#!/bin/bash

# Stoppe das Skript sofort, falls ein Fehler auftritt
set -e

echo "=================================================="
echo "Speakwerk - Build, Signing & Notarization Skript"
echo "=================================================="

# 1. Laden der Umgebungsvariablen falls vorhanden
if [ -f .env ]; then
    echo "-> Lade .env Datei..."
    export $(grep -v '^#' .env | xargs)
else
    echo "⚠️  Keine .env-Datei gefunden. Trockentest-Modus aktiv."
fi

# 2. Prüfe auf Zertifikat
DRY_RUN=false
if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
    echo "⚠️  DEVELOPER_ID_APPLICATION ist nicht gesetzt."
    echo "-> Skript läuft im Trockentest-Modus (nur Kompilierung und Verpacken)."
    DRY_RUN=true
fi

# 3. Kompiliere das Projekt in Release-Konfiguration
echo "-> Kompiliere Release-Build..."
swift build -c release

# Hole den dynamischen Binärpfad
BIN_PATH=$(swift build -c release --show-bin-path)
echo "-> Binärpfad aufgelöst: $BIN_PATH"

# 4. Erstelle die App-Bundle-Struktur
APP_BUNDLE="build/Speakwerk.app"
echo "-> Bereite App-Bundle-Ordner vor: $APP_BUNDLE"
rm -rf build
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"

# Kopiere die Executable & Info.plist
echo "-> Kopiere App-Ressourcen..."
cp "$BIN_PATH/Speakwerk" "$APP_BUNDLE/Contents/MacOS/Speakwerk"
cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"

# Kopiere Sparkle.framework (unter Behalt von Symlinks)
SPARKLE_SOURCE="$BIN_PATH/Sparkle.framework"
SPARKLE_DEST="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
echo "-> Bette Sparkle.framework ein..."
cp -R "$SPARKLE_SOURCE" "$APP_BUNDLE/Contents/Frameworks/"

# 5. Stoppen falls Trockentest
if [ "$DRY_RUN" = true ]; then
    echo "--------------------------------------------------"
    echo "✅ TROCKENTEST ERFOLGREICH!"
    echo "Das App-Bundle wurde erstellt unter:"
    echo "   $APP_BUNDLE"
    echo "Füge das Developer-ID-Zertifikat in die .env ein,"
    echo "um das Skript vollständig auszuführen."
    echo "=================================================="
    exit 0
fi

# 6. Inside-Out Code-Signing (Hardened Runtime aktiv)
echo "-> Starte Code-Signing (Inside-Out)..."
SPARKLE_PATH="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"

# A. Signiere die eingebetteten Sparkle XPC Services & Hilfs-Apps
echo "   - Signiere Sparkle Downloader.xpc..."
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$SPARKLE_PATH/Versions/B/XPCServices/Downloader.xpc/Contents/MacOS/Downloader"
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$SPARKLE_PATH/Versions/B/XPCServices/Downloader.xpc"

echo "   - Signiere Sparkle Installer.xpc..."
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$SPARKLE_PATH/Versions/B/XPCServices/Installer.xpc/Contents/MacOS/Installer"
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$SPARKLE_PATH/Versions/B/XPCServices/Installer.xpc"

echo "   - Signiere Sparkle Updater.app..."
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$SPARKLE_PATH/Versions/B/Updater.app/Contents/MacOS/Updater"
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$SPARKLE_PATH/Versions/B/Updater.app"

# B. Signiere das Sparkle Framework selbst
echo "   - Signiere Sparkle.framework..."
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$SPARKLE_PATH"

# C. Signiere die Speakwerk-Binary mit den Entitlements
echo "   - Signiere Speakwerk Binary..."
codesign --force --options runtime --timestamp --entitlements Resources/Speakwerk.entitlements --sign "$DEVELOPER_ID_APPLICATION" "$APP_BUNDLE/Contents/MacOS/Speakwerk"

# D. Signiere das gesamte äußere App-Bundle
echo "   - Signiere Speakwerk.app..."
codesign --force --options runtime --timestamp --entitlements Resources/Speakwerk.entitlements --sign "$DEVELOPER_ID_APPLICATION" "$APP_BUNDLE"

# 7. Lokale Signatur-Verifikation
echo "-> Verifiziere Signatur lokal..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

# 8. Notarisierungs-Archiv erstellen
echo "-> Erstelle ZIP-Archiv für Apple Notarisierung..."
ditto -c -k --keepParent "$APP_BUNDLE" build/Speakwerk.zip

# 9. Notarisierung via notarytool
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-speakwerk}"
echo "-> Übermittle zur Notarisierung via notarytool (Profil: $KEYCHAIN_PROFILE)..."
xcrun notarytool submit build/Speakwerk.zip --keychain-profile "$KEYCHAIN_PROFILE" --wait

# 10. Stapling (Notarisierungs-Ticket anheften)
echo "-> Hefte Notarisierungs-Ticket an (Stapling)..."
xcrun stapler staple "$APP_BUNDLE"

# 11. End-Verifikation mit Gatekeeper (nach Stapling erfolgreich)
echo "-> Führe Gatekeeper-Endverifikation aus..."
spctl -a -t exec -vv "$APP_BUNDLE"

# 12. Sparkle Distribution ZIP verpacken
echo "-> Verpacke endgültiges Update-Archiv (gestapelt)..."
ditto -c -k --keepParent "$APP_BUNDLE" build/Speakwerk-Dist.zip

echo "--------------------------------------------------"
echo "🎉 ERFOLG! App wurde gebaut, signiert, notariert und gestapelt."
echo "Finales ZIP für Verteilung/Sparkle: build/Speakwerk-Dist.zip"
echo "=================================================="
