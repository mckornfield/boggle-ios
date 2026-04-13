**Word Grid Game**

Product Specification

*Working Title — Name TBD*

Version 1.0 — April 2026

# **1\. Overview**

A word-finding game for iOS and iPadOS. Players compete to find words in a randomly generated 4×4 grid of letter dice. The game faithfully recreates the classic tabletop word game experience with no ads, no power-ups, and no in-app purchases.

# **2\. Platforms & Requirements**

* **iPhone:** iOS 17+ (primary platform)

* **iPad:** iPadOS 17+ (universal app with dedicated Table Mode UI)

* **Networking:** Local Wi-Fi only (no internet connection required for gameplay)

* **App Store:** Distributed via Apple App Store

* **Monetization:** None. No ads, no IAP, no subscriptions.

# **3\. Game Modes**

## **3.1 Solo Mode**

Single player against the clock. The player finds as many valid words as possible within the time limit. After the round, the app validates all entered words against the dictionary and displays the score.

* Player enters words on their own device during the round

* Invalid words (not in dictionary or not traceable on the grid) are flagged and scored as 0

* Running score tracked across rounds with a configurable win target (e.g., first to 50 points)

## **3.2 Local Multiplayer Mode (Network)**

Two or more players on the same Wi-Fi network, each on their own iPhone. One device hosts the game session; others join.

* Host creates a game session with named players and a win condition

* All devices display the same grid simultaneously

* Each player enters words privately on their own device

* After the timer expires, the app automatically eliminates duplicate words found by multiple players

* Only unique words are scored; dictionary validation is applied

* Cumulative scores are tracked across rounds until a player reaches the win target

## **3.3 Table Mode (iPad Only)**

The iPad acts as a shared game board, placed in the center of a table. Players use pen and paper, just like the original board game.

* iPad displays the 4×4 letter grid in a large, readable format

* A visible countdown timer runs for each round

* No digital word entry — players write words on paper

* After the timer expires, players verbally call out their words and manually cross off duplicates

* The iPad displays a “New Round” button to shake/regenerate the grid

* Optional: iPad tracks named players and cumulative scores via simple manual score entry between rounds

# **4\. Game Rules**

## **4.1 Grid Generation**

The game uses a standard set of 16 letter dice with historically accurate face distributions (matching the classic 4×4 game). Each round, all 16 dice are randomly “shaken” and placed into the grid. The “Qu” die face displays as a single tile.

## **4.2 Word Rules**

* Minimum 3 letters

* Words must be formed by connecting adjacent tiles (horizontally, vertically, or diagonally)

* Each tile may only be used once per word

* Proper nouns, abbreviations, and hyphenated words are not valid

* “Qu” counts as two letters

## **4.3 Scoring**

Standard scoring applies:

| Word Length | Points |
| :---- | :---: |
| 3 letters | 1 |
| 4 letters | 1 |
| 5 letters | 2 |
| 6 letters | 3 |
| 7 letters | 5 |
| 8+ letters | 11 |

## **4.4 Duplicate Elimination**

In multiplayer (network mode), any word found by more than one player is eliminated for all players. Only unique finds score points. In Table Mode, players handle this manually by reading words aloud.

## **4.5 Game Sessions**

* A game session consists of multiple rounds played by the same group of named players

* Scores accumulate across rounds

* The session ends when a player reaches the configured win target (e.g., first to 50 points)

* Example: Gregg and Jenny, first to 50 points

# **5\. Timer**

Fixed at 3 minutes per round for the MVP. A visible countdown is displayed on all devices. An audible alert sounds when time expires.

# **6\. Dictionary & Validation**

* The app includes an embedded English word list for offline validation

* Recommended source: TWL (Tournament Word List) or a comparable Scrabble-grade dictionary

* Validation occurs automatically after each round in Solo and Network modes

* Words not found in the dictionary or not traceable on the grid are marked invalid and score 0 points

# **7\. Networking Architecture**

Local Wi-Fi multiplayer only. No cloud services, no user accounts, no internet dependency.

* **Discovery:** Use Apple’s Multipeer Connectivity framework or Bonjour/mDNS to discover nearby players on the same network

* **Host/Join:** One device creates the session (host); others join by selecting the game from a discovered list

* **Sync:** The host generates the grid and distributes it to all players. Timer sync is managed by the host. Word lists are transmitted to the host after the round for duplicate elimination and scoring

* **Latency:** Local network latency is negligible; no special compensation needed

# **8\. Screen Flow**

1. **Home Screen:** Choose Solo, Multiplayer, or Table Mode

2. **Session Setup:** Enter player names, set win condition (e.g., first to 50\)

3. **Lobby (Multiplayer):** Host waits for players to join; shows connected player list

4. **Game Board:** 4×4 grid, countdown timer, word entry area (or grid-only in Table Mode)

5. **Round Results:** Shows each player’s words, duplicates crossed out, invalid words flagged, round scores

6. **Session Scoreboard:** Cumulative scores, indication of progress toward win target

7. **Game Over:** Winner announcement, final scores, option to start a new session

# **9\. Suggested Tech Stack**

This section is a recommendation, not a requirement. The developer should use whatever they are most comfortable with.

* **Language:** Swift / SwiftUI (native iOS development)

* **Networking:** MultipeerConnectivity framework (Apple’s built-in peer-to-peer)

* **Dictionary:** Embedded SQLite database or flat text file bundled with the app

* **Grid Logic:** Custom pathfinding (DFS/BFS) to validate word traceability on the grid

* **State Management:** Observable objects / Combine for reactive UI updates

* **Alternative:** .NET MAUI with C\# is also viable if preferred, but will require platform-specific bindings for MultipeerConnectivity

# **10\. Out of Scope (MVP)**

The following features are explicitly excluded from the initial release:

* Online multiplayer / internet play

* User accounts or cloud sync

* Ads or monetization of any kind

* Power-ups, boosts, or bonus tiles

* Configurable timer (locked at 3 minutes)

* Alternate grid sizes (5×5, etc.)

* Multiple languages / non-English dictionaries

* Leaderboards or Game Center integration

* In-app analytics or tracking

# **11\. Future Considerations**

These are potential enhancements for post-MVP releases, not commitments:

* Configurable timer duration

* 5×5 grid option (Big Boggle variant)

* Online multiplayer via a relay server

* Game Center leaderboards and achievements

* Stats tracking (personal bests, word history)

* Theme/color customization

# **12\. Open Questions**

* **App Name:** Working title is “Word Grid Game.” Needs a real name before App Store submission. Brainstorm needed.

* **Dictionary Source:** TWL vs. SOWPODS vs. another word list? TWL is standard for North American play.

* **Word Entry UX:** Keyboard typing vs. swiping on the grid to form words? Swiping is more intuitive but harder to implement. Typing is simpler for MVP.

* **Table Mode Scoring:** Should the iPad allow manual score entry between rounds, or is it purely a board \+ timer display?