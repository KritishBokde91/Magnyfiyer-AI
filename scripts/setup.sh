#!/usr/bin/env bash
# ─── NexusAI Setup Script for Arch Linux ──────────────────────────────────────
# Run this script once to set up everything
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
FLUTTER_DIR="$PROJECT_DIR/flutter_app"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║     NEXUS AI - SETUP                  ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# ── Check dependencies ────────────────────────────────────────────────────────
echo "[1/5] Checking dependencies..."

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "❌ $1 not found. Please install it first."
    exit 1
  fi
  echo "  ✓ $1"
}

check_cmd ollama
check_cmd flutter
check_cmd python3
check_cmd pip

# ── Check Ollama models ───────────────────────────────────────────────────────
echo ""
echo "[2/5] Checking Ollama models..."
MODELS=$(ollama list 2>/dev/null || echo "")
for model in "snowflake-arctic-embed2" "qllama/bge-reranker-v2-m3"; do
  if echo "$MODELS" | grep -q "$model"; then
    echo "  ✓ $model"
  else
    echo "  ⚠ $model not found. Pulling..."
    ollama pull "$model"
  fi
done

# ── Python backend setup ──────────────────────────────────────────────────────
echo ""
echo "[3/5] Setting up Python backend..."
cd "$BACKEND_DIR"

# Create virtual environment
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  echo "  ✓ Created virtual environment"
fi

source .venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo "  ✓ Python dependencies installed"

# Create data directory
mkdir -p data/vector_store

# Copy .env if not exists
if [ ! -f ".env" ]; then
  cp "$PROJECT_DIR/.env" .env
  echo "  ✓ Copied .env file"
fi

deactivate

# ── Flutter setup ─────────────────────────────────────────────────────────────
echo ""
echo "[4/5] Setting up Flutter app..."
cd "$FLUTTER_DIR"

# Copy .env to assets
cp "$PROJECT_DIR/.env" .env

flutter config --enable-linux-desktop -q
flutter pub get
echo "  ✓ Flutter dependencies installed"

# ── Build (optional) ─────────────────────────────────────────────────────────
echo ""
echo "[5/5] Build Flutter app? (y/N)"
read -r -n 1 BUILD_CHOICE
echo ""
if [[ "$BUILD_CHOICE" =~ ^[Yy]$ ]]; then
  cd "$FLUTTER_DIR"
  flutter build linux --release
  echo "  ✓ Flutter app built at: $FLUTTER_DIR/build/linux/x64/release/bundle/"
fi

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  SETUP COMPLETE!                      ║"
echo "║                                       ║"
echo "║  Run: ./scripts/start.sh              ║"
echo "╚═══════════════════════════════════════╝"
echo ""
