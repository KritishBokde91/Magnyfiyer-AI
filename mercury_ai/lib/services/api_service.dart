import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  String _backendUrl;

  ApiService(this._backendUrl);

  void updateBackendUrl(String url) => _backendUrl = url;

  // ── Health check ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final r = await http
          .get(Uri.parse('$_backendUrl/health'))
          .timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (e) {
      return {
        'status': 'error',
        'ollama': 'disconnected',
        'error': e.toString(),
      };
    }
  }

  // ── Fetch available models ────────────────────────────────────────────────
  Future<List<String>> getModels() async {
    try {
      final r = await http
          .get(Uri.parse('$_backendUrl/models'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      return List<String>.from(data['models'] ?? []);
    } catch (e) {
      return ['deepseek-r1:14b', 'qwen2.5-coder:14b', 'vicuna:13b'];
    }
  }

  // ── Streaming chat ────────────────────────────────────────────────────────
  /// Streams text chunks from the backend RAG pipeline.
  /// Yields individual content strings.
  Stream<String> streamChat({
    required String conversationId,
    required String model,
    required List<ChatMessage> messages,
    required bool useRag,
  }) async* {
    final uri = Uri.parse('$_backendUrl/chat');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode({
      'conversation_id': conversationId,
      'model': model,
      'messages': messages
          .where((m) => !m.isStreaming)
          .map(
            (m) => {
              'role': m.role.name == 'assistant' ? 'assistant' : 'user',
              'content': m.content,
            },
          )
          .toList(),
      'stream': true,
      'use_rag': useRag,
    });

    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(minutes: 10));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final content = json['content'] as String? ?? '';
            if (content.isNotEmpty) yield content;
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  // ── Analyze code for errors ───────────────────────────────────────────────
  Stream<String> analyzeCode({
    required String code,
    required String language,
    required String model,
  }) async* {
    final uri = Uri.parse('$_backendUrl/analyze');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'code': code,
      'language': language,
      'model': model,
    });

    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(minutes: 5));
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final content = json['content'] as String? ?? '';
            if (content.isNotEmpty) yield content;
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  // ── Web search + streaming chat ─────────────────────────────────────────────
  /// Streams web search progress events and LLM content from /web-search.
  /// Yields WebSearchChunk objects containing either a search event or content.
  Stream<WebSearchChunk> streamWebSearch({
    required String query,
    required String conversationId,
    required String model,
    required List<ChatMessage> messages,
    required bool useRag,
    int numResults = 5,
  }) async* {
    final uri = Uri.parse('$_backendUrl/web-search');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode({
      'query': query,
      'conversation_id': conversationId,
      'model': model,
      'messages': messages
          .where((m) => !m.isStreaming && !m.isSearching)
          .map(
            (m) => {
              'role': m.role.name == 'assistant' ? 'assistant' : 'user',
              'content': m.content,
            },
          )
          .toList(),
      'num_results': numResults,
      'use_rag': useRag,
    });

    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(minutes: 10));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            // Check if it's a search event (has "type" field) or LLM content
            if (json['type'] != null) {
              yield WebSearchChunk.event(WebSearchEvent.fromJson(json));
            } else if (json['content'] != null) {
              yield WebSearchChunk.content(json['content'] as String);
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  // ── Delete conversation memory ────────────────────────────────────────────
  Future<void> deleteConversationMemory(String conversationId) async {
    try {
      await http
          .delete(Uri.parse('$_backendUrl/conversation/$conversationId'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}

// ─── Web Search Chunk (union type) ───────────────────────────────────────────
class WebSearchChunk {
  final WebSearchEvent? event;
  final String? content;

  WebSearchChunk._({this.event, this.content});

  factory WebSearchChunk.event(WebSearchEvent e) => WebSearchChunk._(event: e);
  factory WebSearchChunk.content(String c) => WebSearchChunk._(content: c);

  bool get isEvent => event != null;
  bool get isContent => content != null;
}
