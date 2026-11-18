#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

PORT="${PORT:-8765}"

if ss -tln 2>/dev/null | awk '{print $4}' | grep -qE ":${PORT}$"; then
  echo "Le port ${PORT} est déjà utilisé."
  echo "  → App déjà lancée : http://localhost:${PORT}"
  echo "  → Sinon : ./stop_web.sh puis relancez ./run_web.sh"
  exit 1
fi

echo "Serveur web : http://localhost:${PORT} (0.0.0.0:${PORT})"
exec flutter run -d web-server --web-hostname=0.0.0.0 --web-port="$PORT"
