# Release-Anleitung (Maintainer)

Diese Anleitung beschreibt den vollständigen Veröffentlichungsprozess einer neuen Speakwerk-Version. Sie richtet sich ausschließlich an Maintainer — zum bloßen Bauen der App genügt die README.

Der dokumentierte Weg ist der **Prozess ohne Apple Developer Account** mit einem selbst-signierten Zertifikat (bis v1.0.3 wurde ad-hoc signiert). Der notarisierte Weg ist am Ende als Ausblick beschrieben.

---

## Voraussetzungen (einmalig)

### Selbst-signiertes Code-Signing-Zertifikat

macOS knüpft TCC-Berechtigungen (z. B. Mikrofonzugriff) an die Code-Identität der App. Bei Ad-hoc-Signaturen (`codesign --sign -`) ändert sich diese Identität mit **jedem Build** — nach jedem Update verliert die App ihre Mikrofonberechtigung. Ein selbst-signiertes Zertifikat hält die Identität über Releases hinweg stabil.

Einmalig erstellen (GUI, benötigt Admin-Rechte):

1. **Schlüsselbundverwaltung** öffnen → Menü *Schlüsselbundverwaltung* → *Zertifikatsassistent* → *Ein Zertifikat erstellen…*
2. Name: `Speakwerk Signing` · Identitätstyp: *Selbst signiertes Root-Zertifikat* · Zertifikatstyp: **Code-Signierung**
3. *Erstellen* klicken. Das Zertifikat landet im Login-Schlüsselbund.
4. Beim ersten `codesign`-Aufruf fragt macOS nach Schlüsselbund-Zugriff → *Immer erlauben*.

Prüfen, dass das Zertifikat gefunden wird:

```bash
security find-identity -p codesigning -v | grep "Speakwerk Signing"
```

**Hinweis:** Beim Wechsel von Ad-hoc auf dieses Zertifikat (bzw. falls das Zertifikat jemals neu erstellt wird) verlieren bestehende Installationen **einmalig** ihre Mikrofonberechtigung nach dem ersten Update mit der neuen Signatur. Danach bleibt sie über alle weiteren Updates erhalten.

### Sparkle Ed25519-Schlüsselpaar

Updates müssen kryptografisch signiert werden, um von Sparkle akzeptiert zu werden. Das Schlüsselpaar wird einmalig erzeugt:

```bash
./.build/artifacts/sparkle/Sparkle/bin/generate_keys
```

*   Der **öffentliche Schlüssel** steht in `Resources/Info.plist` unter dem Key `SUPublicEDKey`.
*   Der **private Schlüssel** liegt automatisch im lokalen macOS-Schlüsselbund (Keychain). **Wichtig:** Diesen Schlüssel zusätzlich an einem sicheren Ort sichern (`generate_keys -x <datei>` exportiert ihn). Geht er verloren, können bestehende Installationen keine automatischen Updates mehr verifizieren!

Ein erneuter Aufruf von `generate_keys` zeigt den vorhandenen öffentlichen Schlüssel an — so lässt sich vor jedem Release prüfen, dass er mit der `Info.plist` übereinstimmt.

---

## Release-Prozess (selbst-signiert, ohne Notarisierung)

Im Beispiel steht `<tag>` für den GitHub-Release-Tag, z. B. `v1.1.0`.

### 1. Versionen erhöhen

In `Resources/Info.plist` die Marketing-Version (`CFBundleShortVersionString`, z. B. `1.1.0`) und die Build-Nummer (`CFBundleVersion`, ganzzahlig hochzählen) anpassen.

### 2. App-Bundle bauen

```bash
./scripts/build.sh
```

Ohne `.env` (bzw. ohne gesetztes `DEVELOPER_ID_APPLICATION`) läuft das Skript im **Trockentest-Modus**: Es kompiliert den Release-Build, erstellt `build/Speakwerk.app`, bettet Sparkle.framework ein und führt den Launch-Smoke-Test aus. **Achtung:** Im Trockentest-Modus erzeugt das Skript *kein* `Speakwerk-Dist.zip` — Signieren und Verpacken folgen manuell in den nächsten beiden Schritten.

### 3. Signieren (inside-out, selbst-signiertes Zertifikat)

```bash
APP="build/Speakwerk.app"
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
IDENTITY="Speakwerk Signing"
codesign --force --sign "$IDENTITY" "$SPARKLE/Versions/B/Updater.app/Contents/MacOS/Updater"
codesign --force --sign "$IDENTITY" "$SPARKLE/Versions/B/Updater.app"
codesign --force --sign "$IDENTITY" "$SPARKLE"
codesign --force --sign "$IDENTITY" --entitlements Resources/Speakwerk.entitlements "$APP/Contents/MacOS/Speakwerk"
codesign --force --sign "$IDENTITY" --entitlements Resources/Speakwerk.entitlements "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
```

Nicht mehr ad-hoc (`--sign -`) signieren — siehe Voraussetzungen, sonst geht die Mikrofonberechtigung bei jedem Update verloren.

### 4. Distributions-Archiv erstellen

```bash
ditto -c -k --keepParent build/Speakwerk.app build/Speakwerk-Dist.zip
```

`ditto` (statt `zip`) ist Pflicht: Es erhält die Symlinks und Metadaten im Sparkle.framework, ohne die die Code-Signatur ungültig wird.

### 5. Appcast generieren

```bash
mkdir -p build/release-assets
cp build/Speakwerk-Dist.zip build/release-assets/
./.build/artifacts/sparkle/Sparkle/bin/generate_appcast \
  --download-url-prefix "https://github.com/salutaris91/Speakwerk/releases/download/<tag>/" \
  build/release-assets/
```

`generate_appcast` signiert das ZIP automatisch mit dem privaten Schlüssel aus dem Schlüsselbund (EdDSA-Signatur im `sparkle:edSignature`-Attribut).

### 6. Appcast committen und nach `main` bringen

```bash
cp build/release-assets/appcast.xml appcast.xml
git add appcast.xml
git commit -m "add Sparkle appcast for <tag> release"
```

Anschließend den Release-Branch pushen, einen PR nach `main` erstellen und mergen. Sparkle ruft den Feed von `main` ab (`SUFeedURL` in der `Info.plist` zeigt auf `https://raw.githubusercontent.com/salutaris91/Speakwerk/main/appcast.xml`) — das Update wird also erst nach dem Merge sichtbar.

### 7. GitHub-Release erstellen

Neues Release mit dem Tag `<tag>` auf `main` anlegen und `build/Speakwerk-Dist.zip` als Asset hochladen, z. B.:

```bash
gh release create <tag> build/Speakwerk-Dist.zip --target main --title "Speakwerk <version>" --notes "..."
```

**Wichtig:** Der Asset-Dateiname muss exakt `Speakwerk-Dist.zip` lauten, da er so in der Enclosure-URL des Appcasts referenziert wird.

### 8. Verifizieren

```bash
curl -sf "https://raw.githubusercontent.com/salutaris91/Speakwerk/main/appcast.xml" | grep -o 'url="[^"]*"'
curl -sIL -o /dev/null -w "%{http_code}\n" "https://github.com/salutaris91/Speakwerk/releases/download/<tag>/Speakwerk-Dist.zip"
```

Die Enclosure-URL muss auf das hochgeladene Asset zeigen, der Download mit HTTP 200 antworten. Idealerweise zusätzlich auf einer bestehenden Installation „Nach Updates suchen" auslösen.

### 9. Produktseite aktualisieren

Auf https://anderzlabs.de/speakwerk/ die Versionsnummer und ggf. den Download-Link auf die neue Version aktualisieren.

---

## Ausblick: Notarisiertes Release (mit Apple Developer Account)

Sobald ein "Developer ID Application"-Zertifikat vorhanden ist, übernimmt `scripts/build.sh` die Schritte 3 und 4 vollständig (Hardened-Runtime-Signierung, Notarisierung via `notarytool`, Stapling, Gatekeeper-Verifikation und Erzeugung von `build/Speakwerk-Dist.zip`). Dazu die Zugangsdaten gemäß `.env.example` in einer `.env` hinterlegen. Der restliche Prozess (Schritte 1, 2, 5–8) bleibt identisch; der Gatekeeper-Hinweis in der README kann dann entfallen.
