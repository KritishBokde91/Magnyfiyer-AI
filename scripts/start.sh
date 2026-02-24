#!/usr/bin/env bash
# ─── NexusAI Start Script ─────────────────────────────────────────────────────
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
FLUTTER_DIR="$PROJECT_DIR/flutter_app"

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

cleanup() {
  echo ""
  echo -e "${YELLOW}Stopping NexusAI...${NC}"
  kill "$BACKEND_PID" 2>/dev/null || true
  kill "$FLUTTER_PID" 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM

echo ""
echo -e "${BOLD}${CYAN}"
echo "  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗"
echo "  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝"
echo "  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗"
echo "  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║"
echo "  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║"
echo "  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "  ${BOLD}AI DESKTOP ASSISTANT${NC} — Powered by Ollama"
echo ""

# ── Check Ollama ──────────────────────────────────────────────────────────────
if ! ollama list &>/dev/null; then
  echo -e "${RED}❌ Ollama is not running. Start it with: ollama serve${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Ollama is running${NC}"

# ── Start Backend ─────────────────────────────────────────────────────────────
echo -e "${CYAN}Starting Python backend...${NC}"
cd "$BACKEND_DIR"

if [ -d ".venv" ]; then
  source .venv/bin/activate
fi

# Load port from .env
BACKEND_PORT=$(grep "^BACKEND_PORT=" "$PROJECT_DIR/.env" 2>/dev/null | cut -d'=' -f2 || echo "8000")

python3 main.py &
BACKEND_PID=$!
echo -e "${GREEN}✓ Backend started (PID: $BACKEND_PID, Port: $BACKEND_PORT)${NC}"

# Wait for backend to be ready
echo -n "  Waiting for backend..."
for i in {1..20}; do
  if curl -sf "http://localhost:$BACKEND_PORT/health" &>/dev/null; then
    echo -e " ${GREEN}ready!${NC}"
    break
  fi
  sleep 0.5
  echo -n "."
done
echo ""

# ── Start Flutter App ─────────────────────────────────────────────────────────
echo -e "${CYAN}Starting Flutter desktop app...${NC}"
cd "$FLUTTER_DIR"

# Check if built binary exists
RELEASE_BINARY="$FLUTTER_DIR/build/linux/x64/release/bundle/nexus_ai"
if [ -f "$RELEASE_BINARY" ]; then
  echo -e "${GREEN}✓ Running release build${NC}"
  "$RELEASE_BINARY" &
  FLUTTER_PID=$!
else
  echo -e "${YELLOW}⚠ No release build found. Running in debug mode...${NC}"
  echo -e "  ${BOLD}Tip:${NC} Run ${CYAN}flutter build linux --release${NC} for faster startup"
  flutter run -d linux &
  FLUTTER_PID=$!
fi

echo ""
echo -e "${GREEN}${BOLD}NexusAI is running!${NC}"
echo -e "  Backend: ${CYAN}http://localhost:$BACKEND_PORT${NC}"
echo -e "  Press ${BOLD}Ctrl+C${NC} to stop"
echo ""

# Wait for processes
wait "$FLUTTER_PID" 2>/dev/null || true
cleanup
