# Roadmap

Stand: Juni 2026, nach Release v1.0.1. Die Roadmap ist eine Absichtserklärung, keine Zusage — Reihenfolge und Zuschnitt können sich ändern. Leitplanken bleiben unverändert: **100 % lokal, kostenlos, Open Source, keine Telemetrie.**

## v1.1 — Bedienkomfort

- **Diktierbefehle für Sonderzeichen**: Gesprochene Befehle wie „Klammer auf", „Anführungszeichen" oder „neue Zeile" werden nach der Transkription in die entsprechenden Zeichen umgewandelt (deterministische Ersetzungstabelle, abschaltbar, perspektivisch editierbar). Legt zugleich die Post-Processing-Pipeline für spätere Erweiterungen.
- **Modellwechsel per Hotkey**: Schneller Wechsel zwischen den installierten Whisper-Modellstufen ohne Umweg über das Menü.
- **Push-to-Talk** *(optional, falls ohne großen Mehraufwand umsetzbar)*: Aufnahme nur solange die Taste gehalten wird, als Alternative zum Toggle-Modus.

## v1.2 — Eigenes Vokabular

- **Wörterbuch**: Nutzerdefinierte Begriffe (Namen, Fachwörter, Abkürzungen) und eigene Text-Ersetzungen — baut direkt auf der Ersetzungs-Pipeline aus v1.1 auf.

## v2.0 — Intelligente Nachbearbeitung

- **KI-Nachbearbeitung / Enhancement**: Optionale Umformung des Transkripts (Stil, Formatierung, kontextuelle Befehle) durch ein Sprachmodell. Lokal bevorzugt; eine Cloud-Anbindung käme nur strikt opt-in mit eigenem API-Key (Schlüssel im macOS-Keychain).
- **Live-Streaming-Transkription**: Text erscheint bereits während des Sprechens statt erst nach Aufnahmeende.

## In Evaluation (kein Versionsziel)

- **Intel-Support**: Abhängig von Nachfrage und WhisperKit-Performance auf Intel-Macs.
- **Screen-Kontext-Erfassung**: Transkription mit Kontextwissen über die aktive App — nur, wenn es ohne Aufweichung der Datenschutz-Prinzipien möglich ist.
- **Apple-Notarisierung**: Entfall der Gatekeeper-Hürde, sobald ein Apple Developer Account vorhanden ist (`docs/RELEASING.md` beschreibt den Umstieg).
- **Satz-Spacing bei Folgeaufnahmen**: Untersuchung, wie fehlende Leerzeichen zwischen mehreren aufeinanderfolgenden Aufnahmen (z.B. nach einem Punkt) am elegantesten vermieden werden können.
- **Intelligente Grammatik-Typografie (Deutsch)**: Automatische Bereinigung von grammatikalisch störenden Kommata vor öffnenden Klammern (z.B. Umformung von *„Ich hoffe, (und nicht nur ich), dass…"* zu *„Ich hoffe (und nicht nur ich), dass…"*).
