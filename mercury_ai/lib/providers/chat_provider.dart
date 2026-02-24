import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/artifact_parser.dart';

const _uuid = Uuid();

enum ChatStatus { idle, loading, streaming, searching, analyzing, error }

class ChatProvider extends ChangeNotifier {
  final StorageService _storage;
  late ApiService _api;

  ChatProvider({required StorageService storage}) : _storage = storage {
    final settings = _storage.loadSettings();
    _settings = settings;
    _api = ApiService(settings.backendUrl);
    _conversations = _storage.loadConversations();
    _selectedModel = settings.defaultModel;
    _checkBackendHealth();
  }

  // ── State ─────────────────────────────────────────────────────────────────
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  ChatStatus _status = ChatStatus.idle;
  String? _errorMessage;
  List<String> _availableModels = ['deepseek-r1:14b'];
  String _selectedModel = 'deepseek-r1:14b';
  bool _isConnected = false;
  AppSettings _settings = AppSettings();
  StreamSubscription? _streamSub;
  bool _webSearchEnabled = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Conversation> get conversations => _conversations;
  Conversation? get activeConversation => _activeConversation;
  ChatStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<String> get availableModels => _availableModels;
  String get selectedModel => _selectedModel;
  bool get isConnected => _isConnected;
  AppSettings get settings => _settings;
  bool get isStreaming =>
      _status == ChatStatus.streaming || _status == ChatStatus.searching;
  bool get webSearchEnabled => _webSearchEnabled;

  List<ChatMessage> get messages => _activeConversation?.messages ?? [];

  // ── Web Search Toggle ─────────────────────────────────────────────────────
  void toggleWebSearch() {
    _webSearchEnabled = !_webSearchEnabled;
    notifyListeners();
  }

  // ── Backend Health ────────────────────────────────────────────────────────
  Future<void> _checkBackendHealth() async {
    final health = await _api.checkHealth();
    _isConnected = health['status'] == 'ok';
    if (_isConnected) {
      _availableModels = List<String>.from(health['available_models'] ?? []);
      if (!_availableModels.contains(_selectedModel) &&
          _availableModels.isNotEmpty) {
        _selectedModel = _availableModels.first;
      }
    }
    notifyListeners();
  }

  Future<void> refreshModels() async {
    _availableModels = await _api.getModels();
    notifyListeners();
  }

  // ── Conversation Management ───────────────────────────────────────────────
  void newConversation() {
    final conv = Conversation(
      id: _uuid.v4(),
      title: 'New Chat',
      model: _selectedModel,
    );
    _conversations.insert(0, conv);
    _activeConversation = conv;
    _status = ChatStatus.idle;
    _errorMessage = null;
    _storage.saveConversations(_conversations);
    notifyListeners();
  }

  void selectConversation(Conversation conv) {
    _activeConversation = _conversations.firstWhere((c) => c.id == conv.id);
    _status = ChatStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteConversation(Conversation conv) async {
    if (_activeConversation?.id == conv.id) {
      _activeConversation = null;
    }
    _conversations.removeWhere((c) => c.id == conv.id);
    await _storage.saveConversations(_conversations);
    await _api.deleteConversationMemory(conv.id);
    notifyListeners();
  }

  void renameConversation(String id, String newTitle) {
    final idx = _conversations.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _conversations[idx].title = newTitle;
      _storage.saveConversations(_conversations);
      notifyListeners();
    }
  }

  // ── Model Selection ───────────────────────────────────────────────────────
  void setModel(String model) {
    _selectedModel = model;
    if (_activeConversation != null) {
      _activeConversation!.model = model;
    }
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    _api.updateBackendUrl(settings.backendUrl);
    await _storage.saveSettings(settings);
    await _checkBackendHealth();
    notifyListeners();
  }

  // ── Send Message ──────────────────────────────────────────────────────────
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Check for @web prefix or web search toggle
    final isWebSearch =
        _webSearchEnabled || content.trimLeft().startsWith('@web ');
    final query = isWebSearch
        ? content.trimLeft().replaceFirst(RegExp(r'^@web\s+'), '')
        : content;

    if (isWebSearch) {
      return _sendWebSearchMessage(query);
    }

    if (_activeConversation == null) newConversation();

    final conv = _activeConversation!;

    // Auto-title from first message
    if (conv.messages.isEmpty) {
      conv.title = content.length > 40
          ? '${content.substring(0, 40)}...'
          : content;
    }

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: content,
    );
    conv.messages.add(userMsg);

    // Add assistant placeholder
    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    conv.messages.add(assistantMsg);
    conv.updatedAt = DateTime.now();

    _status = ChatStatus.streaming;
    _errorMessage = null;
    notifyListeners();

    final buffer = StringBuffer();
    try {
      _streamSub = _api
          .streamChat(
            conversationId: conv.id,
            model: _selectedModel,
            messages: conv.messages.where((m) => !m.isStreaming).toList(),
            useRag: _settings.useRag,
          )
          .listen(
            (chunk) {
              buffer.write(chunk);
              assistantMsg.content = buffer.toString();
              notifyListeners();
            },
            onError: (e) {
              _setError('Stream error: $e');
              assistantMsg.isStreaming = false;
              assistantMsg.error = e.toString();
              notifyListeners();
            },
            onDone: () {
              assistantMsg.isStreaming = false;
              final fullContent = buffer.toString();
              assistantMsg.content = fullContent;

              // Parse artifacts
              final artifact = ArtifactParser.buildArtifact(
                fullContent,
                assistantMsg.id,
              );
              if (artifact != null) {
                assistantMsg.artifact = artifact;
              }

              _status = ChatStatus.idle;
              conv.updatedAt = DateTime.now();
              _saveConversations();
              notifyListeners();
            },
          );
    } catch (e) {
      _setError('Failed to connect: $e');
      assistantMsg.isStreaming = false;
    }
  }

  // ── Send Web Search Message ───────────────────────────────────────────────
  Future<void> _sendWebSearchMessage(String query) async {
    if (_activeConversation == null) newConversation();
    final conv = _activeConversation!;

    // Auto-title
    if (conv.messages.isEmpty) {
      conv.title =
          '🌐 ${query.length > 35 ? '${query.substring(0, 35)}...' : query}';
    }

    // Add user message
    conv.messages.add(
      ChatMessage(id: _uuid.v4(), role: MessageRole.user, content: '🌐 $query'),
    );

    // Add assistant placeholder with search state
    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
      isSearching: true,
    );
    conv.messages.add(assistantMsg);
    conv.updatedAt = DateTime.now();

    _status = ChatStatus.searching;
    _errorMessage = null;
    notifyListeners();

    final buffer = StringBuffer();
    try {
      _streamSub = _api
          .streamWebSearch(
            query: query,
            conversationId: conv.id,
            model: _selectedModel,
            messages: conv.messages
                .where((m) => !m.isStreaming && !m.isSearching)
                .toList(),
            useRag: _settings.useRag,
          )
          .listen(
            (chunk) {
              if (chunk.isEvent) {
                final event = chunk.event!;
                assistantMsg.searchEvents.add(event);

                // When done, transition from searching to streaming
                if (event.type == 'done') {
                  assistantMsg.isSearching = false;
                  assistantMsg.webSources = event.sources ?? [];
                  _status = ChatStatus.streaming;
                }
                notifyListeners();
              } else if (chunk.isContent) {
                buffer.write(chunk.content);
                assistantMsg.content = buffer.toString();
                notifyListeners();
              }
            },
            onError: (e) {
              _setError('Web search error: $e');
              assistantMsg.isStreaming = false;
              assistantMsg.isSearching = false;
              assistantMsg.error = e.toString();
              notifyListeners();
            },
            onDone: () {
              assistantMsg.isStreaming = false;
              assistantMsg.isSearching = false;
              final fullContent = buffer.toString();
              assistantMsg.content = fullContent;

              // Parse artifacts from web search responses too
              final artifact = ArtifactParser.buildArtifact(
                fullContent,
                assistantMsg.id,
              );
              if (artifact != null) {
                assistantMsg.artifact = artifact;
              }

              _status = ChatStatus.idle;
              conv.updatedAt = DateTime.now();
              _saveConversations();
              notifyListeners();
            },
          );
    } catch (e) {
      _setError('Failed to connect: $e');
      assistantMsg.isStreaming = false;
      assistantMsg.isSearching = false;
    }
  }

  // ── Stop Streaming ────────────────────────────────────────────────────────
  void stopStreaming() {
    _streamSub?.cancel();
    _streamSub = null;
    if (_activeConversation != null) {
      for (final msg in _activeConversation!.messages) {
        if (msg.isStreaming) msg.isStreaming = false;
        if (msg.isSearching) msg.isSearching = false;
      }
    }
    _status = ChatStatus.idle;
    notifyListeners();
  }

  // ── Analyze code ──────────────────────────────────────────────────────────
  Future<void> analyzeArtifact(Artifact artifact) async {
    if (_activeConversation == null) return;
    final conv = _activeConversation!;
    final code = artifact.files.isNotEmpty ? artifact.files.first.content : '';
    final language = artifact.files.isNotEmpty
        ? artifact.files.first.language
        : 'plaintext';

    final analysisMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    conv.messages.add(
      ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.user,
        content: '🔍 Analyzing code for errors...',
      ),
    );
    conv.messages.add(analysisMsg);
    _status = ChatStatus.analyzing;
    notifyListeners();

    final buffer = StringBuffer();
    _api
        .analyzeCode(code: code, language: language, model: _selectedModel)
        .listen(
          (chunk) {
            buffer.write(chunk);
            analysisMsg.content = buffer.toString();
            notifyListeners();
          },
          onDone: () {
            analysisMsg.isStreaming = false;
            _status = ChatStatus.idle;
            _saveConversations();
            notifyListeners();
          },
          onError: (e) {
            _setError('Analysis error: $e');
            analysisMsg.isStreaming = false;
            notifyListeners();
          },
        );
  }

  // ── Edit existing files ───────────────────────────────────────────────────
  void applyEditsToConversation(List<EditInstruction> edits) {
    if (_activeConversation == null || edits.isEmpty) return;
    // Find the last artifact in conversation
    for (final msg in _activeConversation!.messages.reversed) {
      if (msg.artifact != null) {
        final existingFiles = {
          for (final f in msg.artifact!.files) f.path: f.content,
        };
        final updated = ArtifactParser.applyEdits(existingFiles, edits);
        // Create updated artifact
        final updatedArtifact = Artifact(
          id: msg.artifact!.id,
          title: msg.artifact!.title,
          type: msg.artifact!.type,
          files: updated.entries
              .map(
                (e) => ArtifactFile(
                  path: e.key,
                  content: e.value,
                  language: ArtifactParser.parseFiles('').isEmpty
                      ? 'plaintext'
                      : msg.artifact!.files
                            .firstWhere(
                              (f) => f.path == e.key,
                              orElse: () => msg.artifact!.files.first,
                            )
                            .language,
                ),
              )
              .toList(),
        );
        msg.artifact = updatedArtifact;
        _saveConversations();
        notifyListeners();
        return;
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setError(String message) {
    _status = ChatStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ChatStatus.error) _status = ChatStatus.idle;
    notifyListeners();
  }

  Future<void> _saveConversations() async {
    await _storage.saveConversations(_conversations);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
