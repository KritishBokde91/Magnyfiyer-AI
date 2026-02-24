import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'brutalist_widgets.dart';
import 'code_block.dart';
import 'artifact_panel.dart';
import 'web_search_indicator.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onAnalyzeArtifact;

  const MessageBubble({
    super.key,
    required this.message,
    this.onAnalyzeArtifact,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _thinkingExpanded = false;

  // Parse <think>...</think> tags dynamically from content
  ({String thinking, String response, bool isThinkingComplete})
  
  _parseThinkingContent(String text) {
    // Some models output text BEFORE <think>. Let's preserve that.
    final thinkStartIdx = text.indexOf('<think>');
    if (thinkStartIdx == -1) {
      return (thinking: '', response: text, isThinkingComplete: true);
    }

    final String prefix = text.substring(0, thinkStartIdx).trim();

    final thinkEndIdx = text.indexOf('</think>');
    if (thinkEndIdx == -1) {
      // Still thinking — no closing tag yet (streaming)
      final thinking = text.substring(thinkStartIdx + 7);
      return (
        thinking: thinking.trim(),
        response: prefix, // preserve any prefix received before thinking
        isThinkingComplete: false,
      );
    }

    // Complete thinking block
    final thinking = text.substring(thinkStartIdx + 7, thinkEndIdx);
    final String suffix = text.substring(thinkEndIdx + 8).trim();

    // Combine text before and after the thinking block
    final response = [prefix, suffix].where((s) => s.isNotEmpty).join('\n\n');

    return (
      thinking: thinking.trim(),
      response: response,
      isThinkingComplete: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = widget.message.role == MessageRole.user;
    final message = widget.message;

    // Parse thinking content for assistant messages
    final parsed = !isUser && message.content.contains('<think')
        ? _parseThinkingContent(message.content)
        : (thinking: '', response: message.content, isThinkingComplete: true);
    final displayContent = parsed.response;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // ── Role Label ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
            child: Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accent : AppColors.black,
                      border: Border.all(
                        color: isDark ? AppColors.accent : AppColors.black,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      size: 12,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  isUser ? 'YOU' : 'NEXUS AI',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isUser
                        ? (isDark ? AppColors.accentAlt : AppColors.accentAlt)
                        : (isDark ? AppColors.accent : AppColors.black),
                    letterSpacing: 1.5,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.accentAlt,
                      border: Border.all(color: AppColors.accentAlt, width: 1),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 12,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Web Search Progress ───────────────────────────────────────
          if (!isUser && message.searchEvents.isNotEmpty)
            WebSearchIndicator(
              events: message.searchEvents,
              isSearching: message.isSearching,
            ),

          // ── Thinking Block ─────────────────────────────────────────────
          if (!isUser && parsed.thinking.isNotEmpty)
            _ThinkingBlock(
              content: parsed.thinking,
              isComplete: parsed.isThinkingComplete,
              isExpanded: _thinkingExpanded || !parsed.isThinkingComplete,
              onToggle: () =>
                  setState(() => _thinkingExpanded = !_thinkingExpanded),
              isDark: isDark,
            ),

          // ── Message Content ────────────────────────────────────────────
          if (displayContent.isNotEmpty || message.isStreaming)
            Container(
              constraints: const BoxConstraints(maxWidth: 820),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark
                          ? AppColors.accentAlt.withOpacity(0.15)
                          : AppColors.accentAlt.withOpacity(0.08))
                    : (isDark ? AppColors.darkCard : AppColors.white),
                border: Border.all(
                  color: isUser
                      ? AppColors.accentAlt
                      : (isDark ? AppColors.mutedDark : AppColors.black),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.accentAlt.withOpacity(0.3)
                        : (isDark
                              ? AppColors.accent.withOpacity(0.1)
                              : AppColors.black),
                    offset: const Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayContent.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: isUser
                          ? Text(
                              displayContent,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.6,
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.black,
                              ),
                            )
                          : _buildMarkdownContent(
                              context,
                              isDark,
                              displayContent,
                            ),
                    ),
                  if (message.isStreaming &&
                      (parsed.isThinkingComplete || displayContent.isEmpty))
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        displayContent.isEmpty ? 16 : 0,
                        16,
                        16,
                      ),
                      child: LoadingDots(),
                    ),
                ],
              ),
            ),

          // ── Artifact Panel ─────────────────────────────────────────────
          if (message.artifact != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 480,
              child: ArtifactPanel(
                artifact: message.artifact!,
                onAnalyze: widget.onAnalyzeArtifact,
              ),
            ),
          ],

          // ── Web Sources ─────────────────────────────────────────────
          if (!isUser && message.webSources.isNotEmpty)
            WebSourcesPanel(sources: message.webSources),

          // ── Error ──────────────────────────────────────────────────────
          if (message.error != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.error,
                border: Border(bottom: BorderSide(color: AppColors.error)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.error!,
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),

          // ── Timestamp ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
            child: Text(
              _formatTime(message.timestamp),
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, bool isDark, String text) {
    // Check if message has code blocks
    if (!text.contains('```')) {
      return MarkdownBody(data: text, styleSheet: _mdStyle(isDark));
    }

    // Split on code blocks and render them separately
    final parts = text.split(RegExp(r'(```[\s\S]*?```)'));
    final codeBlocks = RegExp(r'```(\w*)\n?([\s\S]*?)```').allMatches(text);

    final widgets = <Widget>[];
    int blockIndex = 0;

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.trim().isNotEmpty && !part.startsWith('```')) {
        widgets.add(MarkdownBody(data: part, styleSheet: _mdStyle(isDark)));
      } else if (part.startsWith('```') && blockIndex < codeBlocks.length) {
        final match = codeBlocks.elementAt(blockIndex);
        final lang = match.group(1) ?? '';
        final code = match.group(2) ?? '';
        blockIndex++;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: CodeBlock(code: code.trimRight(), language: lang),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  MarkdownStyleSheet _mdStyle(bool isDark) {
    final textColor = isDark ? AppColors.white : AppColors.black;
    final codeColor = isDark ? AppColors.accent : AppColors.accentAlt;
    return MarkdownStyleSheet(
      p: GoogleFonts.inter(fontSize: 14, height: 1.6, color: textColor),
      h1: GoogleFonts.spaceMono(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      h2: GoogleFonts.spaceMono(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      h3: GoogleFonts.spaceMono(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      code: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
        color: codeColor,
      ),
      codeblockDecoration: const BoxDecoration(color: Colors.transparent),
      strong: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      em: GoogleFonts.inter(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: textColor,
      ),
      listBullet: GoogleFonts.inter(fontSize: 14, color: textColor),
      blockquote: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.muted,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Thinking Block ──────────────────────────────────────────────────────────
/// Displays model's reasoning/thinking process in a collapsible block.
/// Shown expanded while streaming, collapsible once complete.
class _ThinkingBlock extends StatelessWidget {
  final String content;
  final bool isComplete;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isDark;

  const _ThinkingBlock({
    required this.content,
    required this.isComplete,
    required this.isExpanded,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 820),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBg.withOpacity(0.5)
            : Colors.amber.withOpacity(0.05),
        border: Border.all(
          color: isDark
              ? Colors.amber.withOpacity(0.3)
              : Colors.amber.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          GestureDetector(
            onTap: isComplete ? onToggle : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber.withOpacity(0.08)
                    : Colors.amber.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.amber.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isComplete ? Icons.psychology : Icons.psychology_alt,
                    size: 14,
                    color: isDark ? Colors.amber : Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isComplete ? 'THINKING' : 'THINKING...',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.amber : Colors.amber.shade800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  if (!isComplete)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: isDark ? Colors.amber : Colors.amber.shade800,
                      ),
                    )
                  else
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: isDark
                          ? Colors.amber.withOpacity(0.7)
                          : Colors.amber.shade600,
                    ),
                ],
              ),
            ),
          ),

          // Content
          if (isExpanded && content.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark
                        ? AppColors.white.withOpacity(0.6)
                        : AppColors.black.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
