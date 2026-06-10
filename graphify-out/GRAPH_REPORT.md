# Graph Report - Speakwerk  (2026-06-10)

## Corpus Check
- 16 files · ~5,757 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 143 nodes · 176 edges · 14 communities (10 shown, 4 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d32aa438`
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

## God Nodes (most connected - your core abstractions)
1. `TranscriptionEntry` - 14 edges
2. `AppDelegate` - 13 edges
3. `HistoryManager` - 13 edges
4. `AGENTS.md — Hausregeln für Coding-Projekte (Speakwerk)` - 13 edges
5. `CLAUDE.md — Hausregeln für Coding-Projekte (Speakwerk)` - 13 edges
6. `AudioRecorder` - 10 edges
7. `HistoryManagerTests` - 8 edges
8. `HotkeyManager` - 8 edges
9. `AppState` - 6 edges
10. `BackupItem` - 5 edges

## Surprising Connections (you probably didn't know these)
- `TranscriptionEntry` --implements--> `Equatable`  [EXTRACTED]
  Sources/Speakwerk/HistoryManager.swift →   _Bridges community 7 → community 0_
- `BackupItem` --references--> `Data`  [EXTRACTED]
  Sources/Speakwerk/ClipboardManager.swift → Sources/Speakwerk/ClipboardManager.swift  _Bridges community 4 → community 0_
- `AppDelegate` --inherits--> `NSObject`  [EXTRACTED]
  Sources/Speakwerk/main.swift →   _Bridges community 3 → community 5_

## Import Cycles
- None detected.

## Communities (14 total, 4 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.10
Nodes (15): Codable, Data, Date, Identifiable, Sendable, Int, String, URL (+7 more)

### Community 1 - "Community 1"
Cohesion: 0.12
Nodes (15): AGENTS.md — Hausregeln für Coding-Projekte (Speakwerk), Arbeitsweise, Aufgabenwechsel und Übergabe, Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+7 more)

### Community 2 - "Community 2"
Cohesion: 0.12
Nodes (15): Arbeitsweise, Aufgabenwechsel und Übergabe, CLAUDE.md — Hausregeln für Coding-Projekte (Speakwerk), Codequalität (Swift & macOS), Deployment-Notizen, Git und Commits, graphify, Kommunikation (+7 more)

### Community 3 - "Community 3"
Cohesion: 0.20
Nodes (9): AppState, Notification, NSApplicationDelegate, NSMenuItem, NSStatusItem, String, AppDelegate, Timer (+1 more)

### Community 4 - "Community 4"
Cohesion: 0.21
Nodes (7): NSPasteboard, Bool, Int, String, BackupItem, ClipboardManager, PasteboardBackup

### Community 5 - "Community 5"
Cohesion: 0.21
Nodes (7): AVAudioRecorder, AVAudioRecorderDelegate, Error, NSObject, Bool, URL, AudioRecorder

### Community 6 - "Community 6"
Cohesion: 0.19
Nodes (9): EventHandlerRef, EventHotKeyRef, FourCharCode, MainActor, Bool, String, HotkeyManager, makeFourCharCode() (+1 more)

### Community 7 - "Community 7"
Cohesion: 0.29
Nodes (6): Equatable, AppState, error, idle, recording, transcribing

### Community 8 - "Community 8"
Cohesion: 0.43
Nodes (4): String, URL, TranscriptionManager, WhisperKit

## Knowledge Gaps
- **54 isolated node(s):** `URL`, `allow`, `refresh_graphify.sh script`, `build.sh script`, `idle` (+49 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TranscriptionEntry` connect `Community 0` to `Community 7`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **Why does `AppDelegate` connect `Community 3` to `Community 5`?**
  _High betweenness centrality (0.053) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `HistoryManager` (e.g. with `.testAddAndLoadHistory()` and `.testAtomicSaving()`) actually correct?**
  _`HistoryManager` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `URL`, `allow`, `refresh_graphify.sh script` to the rest of the system?**
  _54 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.1032258064516129 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._