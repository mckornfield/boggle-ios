import Foundation
import MultipeerConnectivity

enum PeerRole {
    case host
    case peer
}

@Observable
class NetworkingService: NSObject {
    static let serviceType = "tracery-game"

    private let myPeerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private(set) var role: PeerRole = .peer
    private(set) var connectedPeers: [MCPeerID] = []
    private(set) var discoveredHosts: [MCPeerID] = []
    private(set) var isConnected = false

    // Callbacks set by view models
    var onGridReceived: (([[String]]) -> Void)?
    var onTimerStart: ((Date, Int) -> Void)?
    var onWordListReceived: ((UUID, [String]) -> Void)?
    var onRoundResultsReceived: (([PlayerResultMessage]) -> Void)?
    var onPlayerJoined: ((UUID, String) -> Void)?
    var onStartGame: (([PlayerJoinedMessage], Int) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?

    init(playerName: String) {
        self.myPeerID = MCPeerID(displayName: playerName)
        super.init()
    }

    // MARK: - Host

    func startHosting() {
        role = .host
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }

    func sendToAll<T: Encodable>(_ value: T, type messageType: MessageType) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try NetworkMessage.encode(value, type: messageType)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("[Networking] Send error: \(error)")
        }
    }

    // MARK: - Peer/Client

    func startBrowsing() {
        role = .peer
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }

    func connect(to peer: MCPeerID) {
        guard let session, let browser else { return }
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
    }

    func sendToHost<T: Encodable>(_ value: T, type messageType: MessageType) {
        guard let session, let host = session.connectedPeers.first else { return }
        do {
            let data = try NetworkMessage.encode(value, type: messageType)
            try session.send(data, toPeers: [host], with: .reliable)
        } catch {
            print("[Networking] Send error: \(error)")
        }
    }

    // MARK: - Shared

    func disconnect() {
        session?.disconnect()
        session = nil
        connectedPeers = []
        isConnected = false
        discoveredHosts = []
    }

    private func handle(data: Data, from peer: MCPeerID) {
        guard let message = try? NetworkMessage.decode(from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.dispatch(message: message, from: peer)
        }
    }

    private func dispatch(message: NetworkMessage, from peer: MCPeerID) {
        switch message.type {
        case .gridMessage:
            if let msg = try? message.decoded(as: GridMessage.self) {
                onGridReceived?(msg.letters)
            }
        case .timerStart:
            if let msg = try? message.decoded(as: TimerStartMessage.self) {
                onTimerStart?(msg.startDate, msg.durationSeconds)
            }
        case .wordList:
            if let msg = try? message.decoded(as: WordListMessage.self) {
                onWordListReceived?(msg.playerID, msg.words)
            }
        case .roundResults:
            if let msg = try? message.decoded(as: RoundResultsMessage.self) {
                onRoundResultsReceived?(msg.results)
            }
        case .playerJoined:
            if let msg = try? message.decoded(as: PlayerJoinedMessage.self) {
                onPlayerJoined?(msg.playerID, msg.playerName)
            }
        case .startGame:
            if let msg = try? message.decoded(as: StartGameMessage.self) {
                onStartGame?(msg.players, msg.winTarget)
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension NetworkingService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connected:
                if !(self?.connectedPeers.contains(peerID) ?? false) {
                    self?.connectedPeers.append(peerID)
                }
                self?.isConnected = true
            case .notConnected:
                self?.connectedPeers.removeAll { $0 == peerID }
                self?.onPeerDisconnected?(peerID.displayName)
                if self?.connectedPeers.isEmpty ?? true { self?.isConnected = false }
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handle(data: data, from: peerID)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension NetworkingService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension NetworkingService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async { [weak self] in
            if !(self?.discoveredHosts.contains(peerID) ?? false) {
                self?.discoveredHosts.append(peerID)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.discoveredHosts.removeAll { $0 == peerID }
        }
    }
}
