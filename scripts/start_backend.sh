#!/usr/bin/env bash
# Start only the backend server
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"

cd "$BACKEND_DIR"
[ -d ".venv" ] && source .venv/bin/activate
cp "$PROJECT_DIR/.env" .env 2>/dev/null || true
python3 main.py
