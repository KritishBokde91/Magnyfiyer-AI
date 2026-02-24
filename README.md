# NEXUS AI — Desktop Code Intelligence Assistant

```
  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
```

**AI-powered desktop coding assistant with RAG memory pipeline, project generation, and artifact management. Built with Flutter for Arch Linux.**

---

## Architecture

```
User Prompt
    ↓
snowflake-arctic-embed2 (embedding)
    ↓
FAISS / ChromaDB Vector Store
    ↓
Top 15 Relevant Memories Retrieved
    ↓
qllama/bge-reranker-v2-m3 (reranking)
    ↓
Top 5 Most Relevant Context
    ↓
deepseek-r1:14b (or selected model)
    ↓
Streaming Response + Artifact Extraction
```

---

## Features

- **Project Generation** — Ask for any app and receive complete, multi-file projects
- **Smart Code Editing** — Edit existing generated code without regenerating everything
- **Error Analysis** — Automatic code review for bugs, security issues, and improvements
- **ZIP Download** — Download generated projects as ZIP files
- **Vector Memory** — Conversations are embedded and stored for contextual recall
- **Multi-Model** — Switch between deepseek-r1, qwen2.5-coder, vicuna, and more
- **Neo Brutalism UI** — Dark/light mode with professional brutalist design
- **Streaming** — Real-time streaming responses

---

## Prerequisites

- **Arch Linux** (or any Linux distro)
- **Ollama** installed and running (`ollama serve`)
- **Flutter** SDK 3.16+
- **Python** 3.10+
- Required Ollama models:
  - `snowflake-arctic-embed2:latest`
  - `qllama/bge-reranker-v2-m3:f16`
  - At least one chat model (e.g. `deepseek-r1:14b`)

---

## Quick Start

### 1. Clone & Setup

```bash
cd ai_chatbot_desktop
chmod +x scripts/*.sh
./scripts/setup.sh
```

### 2. Configure `.env`

Edit `.env` to customize models, ports, and settings:

```env
# Change the default chat model
DEFAULT_CHAT_MODEL=deepseek-r1:14b

# Add/remove available models
AVAILABLE_MODELS=deepseek-r1:14b,qwen2.5-coder:14b,vicuna:13b

# Change backend port if needed
BACKEND_PORT=8000

# Switch vector DB backend
VECTOR_DB_TYPE=faiss  # or: chroma
```

### 3. Start NexusAI

```bash
./scripts/start.sh
```

This starts:
- Python RAG backend on port 8000
- Flutter desktop app

### 4. Build for Production

```bash
cd flutter_app
flutter build linux --release
```

---

## .env Reference

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Ollama server URL |
| `EMBED_MODEL` | `snowflake-arctic-embed2:latest` | Embedding model |
| `RERANK_MODEL` | `qllama/bge-reranker-v2-m3:f16` | Reranking model |
| `DEFAULT_CHAT_MODEL` | `deepseek-r1:14b` | Default LLM |
| `AVAILABLE_MODELS` | (see file) | Comma-separated model list |
| `TOP_K_RETRIEVE` | `15` | Memories retrieved from vector DB |
| `TOP_K_RERANK` | `5` | Memories after reranking |
| `BACKEND_PORT` | `8000` | Backend API port |
| `VECTOR_DB_TYPE` | `faiss` | `faiss` or `chroma` |

---

## Artifact Format

When the AI generates files, it uses this format:

```
### FILE: lib/main.dart
```dart
// code here
```
### END_FILE
```

When editing code, the AI uses:

```
### EDIT: lib/main.dart
### FIND:
```
old code snippet
```
### REPLACE:
```
new code snippet
```
### END_EDIT
```

The app automatically parses these and offers download as ZIP.

---

## Example Prompts

```
Create a full-stack e-commerce Flutter app with:
- Product catalog with categories and search
- Shopping cart and checkout flow
- JWT authentication
- State management with Riverpod
- Beautiful, production-ready UI
```

```
Build a REST API in FastAPI with:
- PostgreSQL database with SQLAlchemy
- JWT auth with refresh tokens
- Docker + docker-compose setup
- Rate limiting and CORS
- Complete CRUD operations
```

```
Make a real-time chat application using:
- Node.js + Socket.io backend
- React frontend with hooks
- MongoDB for message storage
- Rooms and private messages
```

---

## Project Structure

```
ai_chatbot_desktop/
├── .env                        # Configuration (edit this)
├── backend/
│   ├── main.py                 # FastAPI server
│   ├── rag_pipeline.py         # RAG: embed → search → rerank → LLM
│   ├── vector_store.py         # FAISS / ChromaDB implementation
│   ├── requirements.txt
│   └── data/vector_store/      # Persistent vector DB
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme/app_theme.dart        # Neo Brutalism design system
│   │   ├── models/models.dart          # Data models
│   │   ├── services/
│   │   │   ├── api_service.dart        # Backend HTTP + streaming
│   │   │   ├── storage_service.dart    # Local persistence
│   │   │   └── artifact_parser.dart    # File/edit extraction + ZIP
│   │   ├── providers/
│   │   │   ├── chat_provider.dart      # Main state management
│   │   │   └── theme_provider.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart        # Main chat interface
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   │       ├── brutalist_widgets.dart  # UI components
│   │       ├── code_block.dart         # Syntax highlighted code
│   │       ├── artifact_panel.dart     # File viewer + download
│   │       ├── message_bubble.dart     # Chat messages
│   │       └── sidebar.dart           # Conversation sidebar
│   └── pubspec.yaml
└── scripts/
    ├── setup.sh                # One-time setup
    ├── start.sh                # Start everything
    └── start_backend.sh        # Start backend only
```

---

## Troubleshooting

**Backend won't start:**
```bash
cd backend && source .venv/bin/activate && python3 main.py
```

**Flutter app not connecting:**
- Check backend is running: `curl http://localhost:8000/health`
- Verify port in Settings screen matches `.env`

**Models not appearing:**
- Ensure Ollama is running: `ollama serve`
- Check models: `ollama list`

**FAISS errors:**
```bash
pip install faiss-cpu --force-reinstall
```
