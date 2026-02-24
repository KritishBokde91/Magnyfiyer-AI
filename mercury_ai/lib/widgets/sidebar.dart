import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'brutalist_widgets.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final chat = context.watch<ChatProvider>();
    final borderColor = isDark
        ? AppColors.accent.withOpacity(0.3)
        : AppColors.black;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.white;

    final filtered = chat.conversations.where((c) {
      if (_search.isEmpty) return true;
      return c.title.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo / Brand ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : AppColors.black,
              border: Border(bottom: BorderSide(color: borderColor, width: 2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: AppColors.black,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXUS AI',
                      style: GoogleFonts.spaceMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      'ASSISTANT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 7,
                        color: AppColors.muted,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Theme toggle
                GestureDetector(
                  onTap: () => context.read<ThemeProvider>().toggle(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.mutedDark : AppColors.muted,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      size: 14,
                      color: isDark ? AppColors.muted : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Status ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF141414) : const Color(0xFFF8F7F2),
            child: Row(
              children: [
                StatusDot(connected: chat.isConnected),
                const Spacer(),
                Text(
                  'OLLAMA',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: AppColors.muted,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── New Chat Button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onTap: chat.newConversation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accent : AppColors.black,
                  border: Border.all(
                    color: isDark ? AppColors.accent : AppColors.black,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.accent.withOpacity(0.3)
                          : AppColors.black,
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 14,
                      color: isDark ? AppColors.black : AppColors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NEW CHAT',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.black : AppColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search, size: 16),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(height: 12),
          BrutalistDivider(label: 'CHATS'),
          const SizedBox(height: 4),

          // ── Conversation List ─────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'NO CHATS YET',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: AppColors.muted,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _ConversationTile(
                      conversation: filtered[i],
                      isActive: chat.activeConversation?.id == filtered[i].id,
                      onTap: () => chat.selectConversation(filtered[i]),
                      onDelete: () => _confirmDelete(ctx, chat, filtered[i]),
                      onRename: () => _showRenameDialog(ctx, chat, filtered[i]),
                      isDark: isDark,
                    ),
                  ),
          ),

          // ── Model Selector ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : AppColors.offWhite,
              border: Border(top: BorderSide(color: borderColor, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODEL',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.white,
                    border: Border.all(
                      color: isDark ? AppColors.mutedDark : AppColors.black,
                      width: 2,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: chat.availableModels.contains(chat.selectedModel)
                          ? chat.selectedModel
                          : (chat.availableModels.isNotEmpty
                                ? chat.availableModels.first
                                : null),
                      isExpanded: true,
                      dropdownColor: isDark
                          ? AppColors.darkCard
                          : AppColors.white,
                      icon: Icon(
                        Icons.unfold_more,
                        size: 14,
                        color: isDark ? AppColors.accent : AppColors.black,
                      ),
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: isDark ? AppColors.white : AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      items: chat.availableModels
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) chat.setModel(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, ChatProvider chat, Conversation conv) {
    showDialog(
      context: ctx,
      builder: (dCtx) => _BrutalistDialog(
        title: 'DELETE CHAT?',
        message: 'This will permanently delete "${conv.title}" and its memory.',
        confirmLabel: 'DELETE',
        isDanger: true,
        onConfirm: () {
          chat.deleteConversation(conv);
          Navigator.pop(dCtx);
        },
        onCancel: () => Navigator.pop(dCtx),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext ctx,
    ChatProvider chat,
    Conversation conv,
  ) {
    final ctrl = TextEditingController(text: conv.title);
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: context.watch<ThemeProvider>().isDark
            ? AppColors.darkCard
            : AppColors.white,
        shape: const RoundedRectangleBorder(),
        title: Text(
          'RENAME CHAT',
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: const InputDecoration(hintText: 'Chat name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                chat.renameConversation(conv.id, ctrl.text.trim());
              }
              Navigator.pop(dCtx);
            },
            child: Text(
              'SAVE',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final bool isDark;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.isDark,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isActive = widget.isActive;
    final accentColor = isDark ? AppColors.accent : AppColors.black;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.black.withOpacity(0.06))
                : (_hovered
                      ? (isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.03))
                      : null),
            border: isActive
                ? Border(left: BorderSide(color: accentColor, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 12,
                color: isActive ? accentColor : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.conversation.lastMessagePreview,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_hovered || isActive) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 14, color: AppColors.muted),
                  color: isDark ? AppColors.darkCard : AppColors.white,
                  shape: const RoundedRectangleBorder(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 12),
                          const SizedBox(width: 8),
                          Text(
                            'Rename',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete,
                            size: 12,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') widget.onDelete();
                    if (v == 'rename') widget.onRename();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BrutalistDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDanger;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _BrutalistDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDanger = false,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: const RoundedRectangleBorder(),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDanger
                ? AppColors.error
                : (isDark ? AppColors.accent : AppColors.black),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDanger
                  ? AppColors.error
                  : (isDark ? AppColors.accent : AppColors.black),
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceMono(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                BrutalistButton(
                  label: confirmLabel,
                  danger: isDanger,
                  onPressed: onConfirm,
                  small: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
