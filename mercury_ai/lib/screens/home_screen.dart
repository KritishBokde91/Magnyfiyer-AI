import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/brutalist_widgets.dart';
import '../widgets/sidebar.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  bool _showSidebar = true;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final chat = context.read<ChatProvider>();
    await chat.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final chat = context.watch<ChatProvider>();
    final hasConversation = chat.activeConversation != null;

    // Auto scroll when streaming
    if (chat.isStreaming) _scrollToBottom();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────────────────
          if (_showSidebar) const Sidebar(),

          // ── Main Chat Area ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ── Top Bar ───────────────────────────────────────────────
                _TopBar(
                  isDark: isDark,
                  chat: chat,
                  onToggleSidebar: () =>
                      setState(() => _showSidebar = !_showSidebar),
                  showSidebar: _showSidebar,
                  onOpenSettings: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),

                // ── Messages Area ─────────────────────────────────────────
                Expanded(
                  child: !hasConversation
                      ? _WelcomeScreen(
                          isDark: isDark,
                          onNewChat: chat.newConversation,
                        )
                      : chat.messages.isEmpty
                      ? _EmptyChatPlaceholder(isDark: isDark)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          itemCount: chat.messages.length,
                          itemBuilder: (ctx, i) {
                            final msg = chat.messages[i];
                            return MessageBubble(
                              message: msg,
                              onAnalyzeArtifact: msg.artifact != null
                                  ? () => chat.analyzeArtifact(msg.artifact!)
                                  : null,
                            ).animate().fadeIn(
                              duration: const Duration(milliseconds: 250),
                            );
                          },
                        ),
                ),

                // ── Error Banner ──────────────────────────────────────────
                if (chat.errorMessage != null)
                  _ErrorBanner(
                    message: chat.errorMessage!,
                    onDismiss: chat.clearError,
                  ),

                // ── Input Area ────────────────────────────────────────────
                if (hasConversation)
                  _InputArea(
                    controller: _inputCtrl,
                    focusNode: _inputFocus,
                    isDark: isDark,
                    isStreaming: chat.isStreaming,
                    webSearchEnabled: chat.webSearchEnabled,
                    onSend: _sendMessage,
                    onStop: chat.stopStreaming,
                    onToggleWebSearch: chat.toggleWebSearch,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final bool isDark;
  final ChatProvider chat;
  final VoidCallback onToggleSidebar;
  final bool showSidebar;
  final VoidCallback onOpenSettings;

  const _TopBar({
    required this.isDark,
    required this.chat,
    required this.onToggleSidebar,
    required this.showSidebar,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.accent.withOpacity(0.3)
        : AppColors.black;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Sidebar toggle
          IconButton(
            icon: Icon(
              showSidebar ? Icons.menu_open : Icons.menu,
              color: isDark ? AppColors.accent : AppColors.black,
            ),
            onPressed: onToggleSidebar,
            tooltip: showSidebar ? 'Hide sidebar' : 'Show sidebar',
          ),
          if (chat.activeConversation != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 20,
              color: isDark ? AppColors.mutedDark : AppColors.borderLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                chat.activeConversation!.title,
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),

          // Status & RAG indicator
          if (chat.settings.useRag)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: BrutalistTag(label: 'RAG ON', color: AppColors.accentAlt),
            ),

          // Status indicator
          StatusDot(connected: chat.isConnected),
          const SizedBox(width: 16),

          // Settings
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? AppColors.muted : AppColors.muted,
              size: 20,
            ),
            onPressed: onOpenSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─── Welcome Screen ───────────────────────────────────────────────────────────
class _WelcomeScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNewChat;

  const _WelcomeScreen({required this.isDark, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppColors.accent : AppColors.black,
              border: Border.all(
                color: isDark ? AppColors.accent : AppColors.black,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppColors.accent : AppColors.black,
                  offset: const Offset(6, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.psychology,
              color: isDark ? AppColors.black : AppColors.white,
              size: 36,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 28),
          Text(
            'NEXUS AI',
            style: GoogleFonts.spaceMono(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.accent : AppColors.black,
              letterSpacing: 8,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'POWERFUL, ALL-ROUNDER AI ASSISTANT',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: AppColors.muted,
              letterSpacing: 2.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 40),

          // Feature tags
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _FeatureChip(label: 'CREATIVE WRITING', icon: Icons.draw),
              _FeatureChip(label: 'CODE GENERATION', icon: Icons.code),
              _FeatureChip(label: 'WEB SEARCH', icon: Icons.travel_explore),
              _FeatureChip(label: 'DATA ANALYSIS', icon: Icons.analytics),
              _FeatureChip(label: 'VECTOR MEMORY', icon: Icons.memory),
              _FeatureChip(label: 'LOCAL PRIVACY', icon: Icons.security),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 48),
          BrutalistButton(
            label: 'START NEW CHAT',
            icon: Icons.add,
            onPressed: onNewChat,
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 24),
          Text(
            'SUGGESTED PROMPTS',
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: AppColors.muted,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Plan a 5-day itinerary to Tokyo focusing on local food.',
            'Explain Quantum Computing like I am 5 years old.',
            'Build a REST API in FastAPI with JWT auth and SQLite.',
          ].map(
            (p) => _SuggestedPrompt(
              prompt: p,
              onTap: () {
                onNewChat();
                // Note: we'd need to inject the prompt after creation
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: isDark ? AppColors.mutedDark : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? AppColors.accent : AppColors.black,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.black,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedPrompt extends StatelessWidget {
  final String prompt;
  final VoidCallback onTap;

  const _SuggestedPrompt({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          border: Border.all(
            color: isDark ? AppColors.mutedDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward, size: 12, color: AppColors.muted),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                prompt,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.white.withOpacity(0.7)
                      : AppColors.black.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatPlaceholder extends StatelessWidget {
  final bool isDark;
  const _EmptyChatPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'ASK ANYTHING',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: AppColors.muted,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Area ───────────────────────────────────────────────────────────────
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final bool isStreaming;
  final bool webSearchEnabled;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onToggleWebSearch;

  const _InputArea({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.isStreaming,
    required this.webSearchEnabled,
    required this.onSend,
    required this.onStop,
    required this.onToggleWebSearch,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.mutedDark : AppColors.black;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.white,
        border: Border(top: BorderSide(color: borderColor, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Web Search Active Banner
          if (webSearchEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.accentAlt.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.accent.withOpacity(0.3)
                        : AppColors.accentAlt.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.travel_explore,
                    size: 13,
                    color: isDark ? AppColors.accent : AppColors.accentAlt,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WEB SEARCH ENABLED',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.accent : AppColors.accentAlt,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggleWebSearch,
                    child: Text(
                      'DISABLE',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: webSearchEnabled
                        ? BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.accent.withOpacity(0.4)
                                  : AppColors.accentAlt.withOpacity(0.4),
                              width: 1,
                            ),
                          )
                        : null,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: 6,
                      minLines: 1,
                      enabled: !isStreaming,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.white : AppColors.black,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: webSearchEnabled
                            ? '🌐 Search the web — e.g. "latest AI news 2026"'
                            : 'Ask Mercury AI to build, explain, or fix code...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: webSearchEnabled
                              ? (isDark
                                    ? AppColors.accent.withOpacity(0.5)
                                    : AppColors.accentAlt.withOpacity(0.5))
                              : AppColors.muted,
                        ),
                        contentPadding: webSearchEnabled
                            ? const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              )
                            : null,
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: controller.clear,
                                color: AppColors.muted,
                              )
                            : null,
                      ),
                      onSubmitted: (_) => onSend(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Web search toggle
                Tooltip(
                  message: webSearchEnabled
                      ? 'Web search ON'
                      : 'Web search OFF',
                  child: GestureDetector(
                    onTap: onToggleWebSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: webSearchEnabled
                            ? (isDark ? AppColors.accent : AppColors.accentAlt)
                            : Colors.transparent,
                        border: Border.all(
                          color: webSearchEnabled
                              ? (isDark
                                    ? AppColors.accent
                                    : AppColors.accentAlt)
                              : (isDark
                                    ? AppColors.mutedDark
                                    : AppColors.borderLight),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.travel_explore,
                        size: 18,
                        color: webSearchEnabled
                            ? (isDark ? AppColors.black : AppColors.white)
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isStreaming)
                  BrutalistButton(
                    label: 'STOP',
                    icon: Icons.stop,
                    danger: true,
                    onPressed: onStop,
                  )
                else
                  BrutalistButton(
                    label: webSearchEnabled ? 'SEARCH' : 'SEND',
                    icon: webSearchEnabled ? Icons.search : Icons.send,
                    onPressed: onSend,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.error,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.white, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppColors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.white, size: 16),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
