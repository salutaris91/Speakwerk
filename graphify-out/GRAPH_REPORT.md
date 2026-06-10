# Graph Report - Speakwerk  (2026-06-10)

## Corpus Check
- 19 files · ~8,040 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 219 nodes · 306 edges · 18 communities (13 shown, 5 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e96b1885`
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

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 27 edges
2. `TranscriptionEntry` - 14 edges
3. `ModelManager` - 13 edges
4. `HistoryManager` - 13 edges
5. `AGENTS.md — Hausregeln für Coding-Projekte (Speakwerk)` - 13 edges
6. `CLAUDE.md — Hausregeln für Coding-Projekte (Speakwerk)` - 13 edges
7. `ModelTier` - 12 edges
8. `OnboardingState` - 12 edges
9. `HotkeyManager` - 11 edges
10. `AudioRecorder` - 10 edges

## Surprising Connections (you probably didn't know these)
- `HistoryManagerTests` --inherits--> `XCTestCase`  [EXTRACTED]
  Tests/HistoryManagerTests.swift →   _Bridges community 16 → community 0_
- `TranscriptionEntry` --implements--> `Equatable`  [EXTRACTED]
  Sources/Speakwerk/HistoryManager.swift →   _Bridges community 7 → community 0_
- `DownloadState` --implements--> `Equatable`  [EXTRACTED]
  Sources/Speakwerk/ModelManager.swift →   _Bridges community 7 → community 15_
- `BackupItem` --references--> `Data`  [EXTRACTED]
  Sources/Speakwerk/ClipboardManager.swift → Sources/Speakwerk/ClipboardManager.swift  _Bridges community 4 → community 0_
- `TranscriptionEntry` --implements--> `Sendable`  [EXTRACTED]
  Sources/Speakwerk/HistoryManager.swift →   _Bridges community 15 → community 0_

## Import Cycles
- None detected.

## Communities (18 total, 5 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.14
Nodes (11): Codable, Data, Date, Int, String, URL, HistoryManager, TranscriptionEntry (+3 more)

### Community 1 - "Community 1"
Cohesion: 0.12
Nodes (15): AGENTS.md — Hausregeln für Coding-Projekte (Speakwerk), Arbeitsweise, Aufgabenwechsel und Übergabe, Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+7 more)

### Community 2 - "Community 2"
Cohesion: 0.12
Nodes (15): Arbeitsweise, Aufgabenwechsel und Übergabe, CLAUDE.md — Hausregeln für Coding-Projekte (Speakwerk), Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+7 more)

### Community 3 - "Community 3"
Cohesion: 0.14
Nodes (13): AppState, Notification, NSApplicationDelegate, NSMenuItem, NSStatusItem, NSWindow, NSWindowDelegate, OnboardingViewMode (+5 more)

### Community 4 - "Community 4"
Cohesion: 0.21
Nodes (7): NSPasteboard, Bool, Int, String, BackupItem, ClipboardManager, PasteboardBackup

### Community 5 - "Community 5"
Cohesion: 0.21
Nodes (7): AVAudioRecorder, AVAudioRecorderDelegate, Error, NSObject, Bool, URL, AudioRecorder

### Community 6 - "Community 6"
Cohesion: 0.15
Nodes (12): EventHandlerRef, EventHotKeyRef, FourCharCode, MainActor, Bool, MainActor, String, Void (+4 more)

### Community 7 - "Community 7"
Cohesion: 0.25
Nodes (7): Equatable, AppState, downloadingModel, error, idle, recording, transcribing

### Community 8 - "Community 8"
Cohesion: 0.33
Nodes (5): ModelTier, String, URL, TranscriptionManager, WhisperKit

### Community 14 - "Community 14"
Cohesion: 0.14
Nodes (9): AVAuthorizationStatus, Bool, Timer, OnboardingState, OnboardingStep, downloading, hotkeyInfo, permissions (+1 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (19): CaseIterable, Double, Identifiable, Sendable, Bool, MainActor, URL, Void (+11 more)

### Community 17 - "Community 17"
Cohesion: 0.18
Nodes (9): ModelTier, String, Void, OnboardingView, OnboardingViewMode, downloadOnly, fullOnboarding, SettingsView (+1 more)

## Knowledge Gaps
- **78 isolated node(s):** `URL`, `allow`, `refresh_graphify.sh script`, `build.sh script`, `idle` (+73 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WhisperKit` connect `Community 8` to `Community 17`, `Community 15`?**
  _High betweenness centrality (0.352) - this node is a cross-community bridge._
- **Why does `OnboardingView` connect `Community 17` to `Community 3`?**
  _High betweenness centrality (0.332) - this node is a cross-community bridge._
- **Why does `TranscriptionEntry` connect `Community 0` to `Community 15`, `Community 7`?**
  _High betweenness centrality (0.247) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `HistoryManager` (e.g. with `.testAddAndLoadHistory()` and `.testAtomicSaving()`) actually correct?**
  _`HistoryManager` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `URL`, `allow`, `refresh_graphify.sh script` to the rest of the system?**
  _78 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._