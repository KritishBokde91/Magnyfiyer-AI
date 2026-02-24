
// ─── Artifact types ───────────────────────────────────────────────────────────
enum ArtifactType { code, project, file }

class ArtifactFile {
  final String path;
  final String content;
  final String language;

  ArtifactFile({
    required this.path,
    required this.content,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'content': content,
    'language': language,
  };

  factory ArtifactFile.fromJson(Map<String, dynamic> j) => ArtifactFile(
    path: j['path'],
    content: j['content'],
    language: j['language'],
  );
}

class Artifact {
  final String id;
  final String title;
  final ArtifactType type;
  final List<ArtifactFile> files;
  final DateTime createdAt;

  Artifact({
    required this.id,
    required this.title,
    required this.type,
    required this.files,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ArtifactFile? get primaryFile => files.isNotEmpty ? files.first : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'files': files.map((f) => f.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Artifact.fromJson(Map<String, dynamic> j) => Artifact(
    id: j['id'],
    title: j['title'],
    type: ArtifactType.values.byName(j['type']),
    files: (j['files'] as List).map((f) => ArtifactFile.fromJson(f)).toList(),
    createdAt: DateTime.parse(j['createdAt']),
  );
}

// ─── Web Search Models ────────────────────────────────────────────────────────

class WebSource {
  final String url;
  final String title;
  final String snippet;
  final int chars;

  WebSource({
    required this.url,
    required this.title,
    this.snippet = '',
    this.chars = 0,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'snippet': snippet,
    'chars': chars,
  };

  factory WebSource.fromJson(Map<String, dynamic> j) => WebSource(
    url: j['url'] ?? '',
    title: j['title'] ?? '',
    snippet: j['snippet'] ?? '',
    chars: j['chars'] ?? 0,
  );
}

class WebSearchEvent {
  final String
  type; // searching, found, scraping, scraped, failed, summarizing, done
  final String? query;
  final String? url;
  final String? title;
  final List<String>? urls;
  final int? index;
  final int? total;
  final int? chars;
  final String? error;
  final List<WebSource>? sources;

  WebSearchEvent({
    required this.type,
    this.query,
    this.url,
    this.title,
    this.urls,
    this.index,
    this.total,
    this.chars,
    this.error,
    this.sources,
  });

  factory WebSearchEvent.fromJson(Map<String, dynamic> j) => WebSearchEvent(
    type: j['type'] ?? '',
    query: j['query'],
    url: j['url'],
    title: j['title'],
    urls: j['urls'] != null ? List<String>.from(j['urls']) : null,
    index: j['index'],
    total: j['total'],
    chars: j['chars'],
    error: j['error'],
    sources: j['sources'] != null
        ? (j['sources'] as List).map((s) => WebSource.fromJson(s)).toList()
        : null,
  );
}

// ─── Message ──────────────────────────────────────────────────────────────────
enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  String content;
  final DateTime timestamp;
  bool isStreaming;
  Artifact? artifact;
  String? error;
  List<WebSearchEvent> searchEvents;
  List<WebSource> webSources;
  bool isSearching;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isStreaming = false,
    this.artifact,
    this.error,
    List<WebSearchEvent>? searchEvents,
    List<WebSource>? webSources,
    this.isSearching = false,
  }) : timestamp = timestamp ?? DateTime.now(),
       searchEvents = searchEvents ?? [],
       webSources = webSources ?? [];

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    Artifact? artifact,
    String? error,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      artifact: artifact ?? this.artifact,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'artifact': artifact?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'],
    role: MessageRole.values.byName(j['role']),
    content: j['content'],
    timestamp: DateTime.parse(j['timestamp']),
    artifact: j['artifact'] != null ? Artifact.fromJson(j['artifact']) : null,
  );

  // Convert for Ollama API
  Map<String, String> toOllamaFormat() => {
    'role': role == MessageRole.assistant ? 'assistant' : 'user',
    'content': content,
  };
}

// ─── Conversation ─────────────────────────────────────────────────────────────
class Conversation {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  String model;

  Conversation({
    required this.id,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? model,
  }) : messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       model = model ?? 'deepseek-r1:14b';

  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages';
    final last = messages.last;
    final preview = last.content.replaceAll('\n', ' ').trim();
    return preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'model': model,
  };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'],
    title: j['title'],
    messages: (j['messages'] as List)
        .map((m) => ChatMessage.fromJson(m))
        .toList(),
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
    model: j['model'] ?? 'deepseek-r1:14b',
  );
}

// ─── App Settings ─────────────────────────────────────────────────────────────
class AppSettings {
  final String backendUrl;
  final bool useRag;
  final double temperature;
  final String defaultModel;

  AppSettings({
    this.backendUrl = 'http://localhost:8080',
    this.useRag = true,
    this.temperature = 0.7,
    this.defaultModel = 'deepseek-r1:14b',
  });

  Map<String, dynamic> toJson() => {
    'backendUrl': backendUrl,
    'useRag': useRag,
    'temperature': temperature,
    'defaultModel': defaultModel,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    backendUrl: j['backendUrl'] ?? 'http://localhost:8080',
    useRag: j['useRag'] ?? true,
    temperature: (j['temperature'] ?? 0.7).toDouble(),
    defaultModel: j['defaultModel'] ?? 'deepseek-r1:14b',
  );

  AppSettings copyWith({
    String? backendUrl,
    bool? useRag,
    double? temperature,
    String? defaultModel,
  }) => AppSettings(
    backendUrl: backendUrl ?? this.backendUrl,
    useRag: useRag ?? this.useRag,
    temperature: temperature ?? this.temperature,
    defaultModel: defaultModel ?? this.defaultModel,
  );
}
