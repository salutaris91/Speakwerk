# Graph Report - Speakwerk  (2026-06-10)

## Corpus Check
- 19 files · ~8,448 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 234 nodes · 322 edges · 17 communities (14 shown, 3 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `699238d7`
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
- [[_COMMUNITY_Community 17|Community 17]]

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 31 edges
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
- `TranscriptionEntry` --implements--> `Equatable`  [EXTRACTED]
  Sources/Speakwerk/HistoryManager.swift →   _Bridges community 7 → community 0_
- `DownloadState` --implements--> `Equatable`  [EXTRACTED]
  Sources/Speakwerk/ModelManager.swift →   _Bridges community 7 → community 15_
- `BackupItem` --references--> `Data`  [EXTRACTED]
  Sources/Speakwerk/ClipboardManager.swift → Sources/Speakwerk/ClipboardManager.swift  _Bridges community 4 → community 0_
- `ModelTier` --implements--> `Identifiable`  [EXTRACTED]
  Sources/Speakwerk/ModelManager.swift →   _Bridges community 15 → community 0_
- `AppDelegate` --inherits--> `NSObject`  [EXTRACTED]
  Sources/Speakwerk/main.swift →   _Bridges community 3 → community 5_

## Import Cycles
- None detected.

## Communities (17 total, 3 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.11
Nodes (14): Codable, Data, Date, Identifiable, Int, String, URL, HistoryManager (+6 more)

### Community 1 - "Community 1"
Cohesion: 0.12
Nodes (15): AGENTS.md — Hausregeln für Coding-Projekte (Speakwerk), Arbeitsweise, Aufgabenwechsel und Übergabe, Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+7 more)

### Community 2 - "Community 2"
Cohesion: 0.12
Nodes (15): Arbeitsweise, Aufgabenwechsel und Übergabe, CLAUDE.md — Hausregeln für Coding-Projekte (Speakwerk), Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+7 more)

### Community 3 - "Community 3"
Cohesion: 0.12
Nodes (15): AppState, Notification, NSApplicationDelegate, NSMenuItem, NSStatusItem, NSWindow, NSWindowDelegate, OnboardingViewMode (+7 more)

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

### Community 10 - "Community 10"
Cohesion: 0.20
Nodes (9): 1. Ed25519-Schlüsselpaar generieren (einmalig), 1. Lokales Bauen (Kompilierung), 2. App-Bundle erstellen und verpacken, 2. Update-Prozess & Verteilung, Auto-Update System (Sparkle 2.x), Installation & Build für Entwickler, Speakwerk, Systemvoraussetzungen (+1 more)

### Community 14 - "Community 14"
Cohesion: 0.50
Nodes (3): Bool, SPUUserUpdateState, SUAppcastItem

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (18): CaseIterable, Double, Sendable, Bool, MainActor, URL, Void, DownloadState (+10 more)

### Community 17 - "Community 17"
Cohesion: 0.09
Nodes (18): AVAuthorizationStatus, Bool, ModelTier, String, Timer, Void, OnboardingState, OnboardingStep (+10 more)

## Knowledge Gaps
- **86 isolated node(s):** `URL`, `allow`, `refresh_graphify.sh script`, `build.sh script`, `idle` (+81 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WhisperKit` connect `Community 8` to `Community 17`, `Community 15`?**
  _High betweenness centrality (0.329) - this node is a cross-community bridge._
- **Why does `OnboardingView` connect `Community 17` to `Community 3`?**
  _High betweenness centrality (0.319) - this node is a cross-community bridge._
- **Why does `TranscriptionEntry` connect `Community 0` to `Community 15`, `Community 7`?**
  _High betweenness centrality (0.227) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `HistoryManager` (e.g. with `.testAddAndLoadHistory()` and `.testAtomicSaving()`) actually correct?**
  _`HistoryManager` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `URL`, `allow`, `refresh_graphify.sh script` to the rest of the system?**
  _86 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.10804597701149425 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._