import XCTest
import SwiftUI
@testable import Tracery

final class AppIconExportTests: XCTestCase {

    @MainActor
    func testExportAppIcon() throws {
        let iconSize: CGFloat = 1024

        let renderer = ImageRenderer(content:
            AppIconView()
                .frame(width: iconSize, height: iconSize)
        )
        renderer.scale = 1.0

        guard let uiImage = renderer.uiImage,
              let data = uiImage.pngData() else {
            XCTFail("ImageRenderer produced no image")
            return
        }

        // SIMULATOR_HOST_HOME points to the Mac's home dir when running in a simulator
        let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]
            ?? ProcessInfo.processInfo.environment["HOME"]
            ?? NSTemporaryDirectory()
        let outputURL = URL(fileURLWithPath: home)
            .appendingPathComponent("Desktop/AppIcon-1024.png")

        try data.write(to: outputURL)
        print("✅ App icon written to: \(outputURL.path)")

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertEqual(Int(uiImage.size.width), Int(iconSize))
        XCTAssertEqual(Int(uiImage.size.height), Int(iconSize))
    }
}
