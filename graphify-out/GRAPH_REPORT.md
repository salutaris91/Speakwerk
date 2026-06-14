# Graph Report - Speakwerk  (2026-06-14)

## Corpus Check
- 26 files · ~49,862 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 320 nodes · 448 edges · 21 communities (18 shown, 3 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 10 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `14529c91`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 34 edges
2. `ModelManager` - 18 edges
3. `TranscriptionEntry` - 15 edges
4. `ModelTier` - 14 edges
5. `TranscriptionLanguage` - 13 edges
6. `HistoryManager` - 13 edges
7. `AGENTS.md — Hausregeln für Coding-Projekte (Speakwerk)` - 13 edges
8. `CLAUDE.md — Hausregeln für Coding-Projekte (Speakwerk)` - 13 edges
9. `OnboardingState` - 12 edges
10. `HotkeyManager` - 11 edges

## Surprising Connections (you probably didn't know these)
- `HistoryManagerTests` --inherits--> `XCTestCase`  [EXTRACTED]
  Tests/HistoryManagerTests.swift →   _Bridges community 17 → community 0_
- `TranscriptionEntry` --implements--> `Equatable`  [EXTRACTED]
  Sources/Speakwerk/HistoryManager.swift →   _Bridges community 19 → community 0_
- `DownloadState` --implements--> `Equatable`  [EXTRACTED]
  Sources/Speakwerk/ModelManager.swift →   _Bridges community 19 → community 15_
- `DictationRule` --implements--> `Identifiable`  [EXTRACTED]
  Sources/Speakwerk/DictationManager.swift →   _Bridges community 15 → community 7_
- `TranscriptionEntry` --implements--> `Identifiable`  [EXTRACTED]
  Sources/Speakwerk/HistoryManager.swift →   _Bridges community 15 → community 0_

## Import Cycles
- None detected.

## Communities (21 total, 3 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.15
Nodes (10): Date, Int, String, URL, UUID, HistoryManager, TranscriptionEntry, HistoryManagerTests (+2 more)

### Community 1 - "Community 1"
Cohesion: 0.12
Nodes (16): AGENTS.md — Hausregeln für Coding-Projekte (Speakwerk), Arbeitsweise, Aufgabenwechsel und Übergabe, Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+8 more)

### Community 2 - "Community 2"
Cohesion: 0.12
Nodes (16): Arbeitsweise, Aufgabenwechsel und Übergabe, CLAUDE.md — Hausregeln für Coding-Projekte (Speakwerk), Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+8 more)

### Community 3 - "Community 3"
Cohesion: 0.10
Nodes (18): AppState, Notification, NSApplicationDelegate, NSMenuItem, NSStatusItem, NSWindow, NSWindowDelegate, OnboardingViewMode (+10 more)

### Community 4 - "Community 4"
Cohesion: 0.19
Nodes (8): Data, NSPasteboard, Bool, Int, String, BackupItem, ClipboardManager, PasteboardBackup

### Community 5 - "Community 5"
Cohesion: 0.21
Nodes (7): AVAudioRecorder, AVAudioRecorderDelegate, Error, NSObject, Bool, URL, AudioRecorder

### Community 6 - "Community 6"
Cohesion: 0.15
Nodes (12): EventHandlerRef, EventHotKeyRef, FourCharCode, MainActor, Bool, MainActor, String, Void (+4 more)

### Community 7 - "Community 7"
Cohesion: 0.25
Nodes (7): Codable, Hashable, Bool, String, UUID, DictationManager, DictationRule

### Community 8 - "Community 8"
Cohesion: 0.33
Nodes (5): ModelTier, String, URL, TranscriptionManager, WhisperKit

### Community 10 - "Community 10"
Cohesion: 0.12
Nodes (16): 1. Ed25519-Schlüsselpaar generieren (einmalig), 1. Lokales Bauen (Kompilierung), 2. App-Bundle erstellen, 2. App-Bundle erstellen und verpacken, 2. Update-Prozess & Verteilung, Alternativ: Download per Browser, Auto-Update System (Sparkle 2.x), Bauen aus dem Quellcode (für Entwickler) (+8 more)

### Community 14 - "Community 14"
Cohesion: 0.07
Nodes (22): AVAuthorizationStatus, String, Bool, ModelTier, String, Timer, Void, String (+14 more)

### Community 15 - "Community 15"
Cohesion: 0.08
Nodes (29): CaseIterable, Double, Identifiable, Sendable, Bool, MainActor, URL, Void (+21 more)

### Community 16 - "Community 16"
Cohesion: 0.16
Nodes (17): 1. Versionen erhöhen, 2. App-Bundle bauen, 3. Ad-hoc signieren (inside-out), 3. Signieren (inside-out, selbst-signiertes Zertifikat), 4. Distributions-Archiv erstellen, 5. Appcast generieren, 6. Appcast committen und nach `main` bringen, 7. GitHub-Release erstellen (+9 more)

### Community 17 - "Community 17"
Cohesion: 0.17
Nodes (3): SpeakwerkTests, TextProcessorTests, XCTestCase

### Community 18 - "Community 18"
Cohesion: 0.33
Nodes (5): In Evaluation (kein Versionsziel), Roadmap, v1.1 — Bedienkomfort, v1.2 — Eigenes Vokabular, v2.0 — Intelligente Nachbearbeitung

### Community 19 - "Community 19"
Cohesion: 0.25
Nodes (7): Equatable, AppState, downloadingModel, error, idle, recording, transcribing

### Community 20 - "Community 20"
Cohesion: 0.47
Nodes (3): DictationRule, String, TextProcessor

## Knowledge Gaps
- **112 isolated node(s):** `URL`, `allow`, `refresh_graphify.sh script`, `build.sh script`, `String` (+107 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WhisperKit` connect `Community 8` to `Community 14`, `Community 15`?**
  _High betweenness centrality (0.278) - this node is a cross-community bridge._
- **Why does `OnboardingView` connect `Community 14` to `Community 3`?**
  _High betweenness centrality (0.254) - this node is a cross-community bridge._
- **Why does `TranscriptionEntry` connect `Community 0` to `Community 19`, `Community 15`, `Community 7`?**
  _High betweenness centrality (0.188) - this node is a cross-community bridge._
- **What connects `URL`, `allow`, `refresh_graphify.sh script` to the rest of the system?**
  _112 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Should `Community 3` be split into smaller, more focused modules?**
  _Cohesion score 0.09878048780487805 - nodes in this community are weakly interconnected._