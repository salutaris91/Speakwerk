#!/bin/bash
# Aktualisiert den Graphify-Wissensgraphen für Speakwerk
set -e

# Lade Umgebungsvariablen aus .env falls vorhanden (für API-Keys)
if [ -f .env ]; then
    echo "-> Lade .env Datei für API-Keys..."
    set -a
    source .env
    set +a
fi

echo "-> Aktualisiere Graphify-Wissensgraph (inkrementell)..."
graphify update .

echo "-> Graphify-Wissensgraph erfolgreich aktualisiert!"
