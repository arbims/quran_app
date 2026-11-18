#!/usr/bin/env bash
# Arrête le serveur Flutter web sur le port 8765 (WSL).
set -euo pipefail
for port in 8765; do
  if fuser "${port}/tcp" 2>/dev/null; then
    echo "Libération du port ${port}…"
    fuser -k "${port}/tcp" 2>/dev/null || true
  fi
done
echo "Terminé."
