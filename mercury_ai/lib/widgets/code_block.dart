import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'brutalist_widgets.dart';

class CodeBlock extends StatefulWidget {
  final String code;
  final String language;
  final String? filename;

  const CodeBlock({
    super.key,
    required this.code,
    required this.language,
    this.filename,
  });

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0EFEA);
    final borderColor = isDark ? AppColors.mutedDark : AppColors.black;
    final shadowColor = isDark ? AppColors.accent.withOpacity(0.2) : AppColors.black;
    final theme = isDark ? atomOneDarkTheme : atomOneLightTheme;

    // Normalize language
    final lang = _normalizeLang(widget.language);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(4, 4), blurRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Bar ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.black,
              border: Border(bottom: BorderSide(color: borderColor, width: 2)),
            ),
            child: Row(
              children: [
                if (widget.filename != null) ...[
                  Icon(Icons.insert_drive_file_outlined,
                      size: 12,
                      color: isDark ? AppColors.accent : AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    widget.filename!,
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.accent : AppColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 12, color: AppColors.mutedDark),
                  const SizedBox(width: 12),
                ],
                BrutalistTag(
                  label: lang,
                  color: isDark ? AppColors.accentAlt : AppColors.accentAlt,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _copy,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy,
                        size: 14,
                        color: _copied ? AppColors.accent : AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'COPIED' : 'COPY',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _copied ? AppColors.accent : AppColors.muted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Code Content ─────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              widget.code,
              language: lang,
              theme: theme,
              padding: const EdgeInsets.all(16),
              textStyle: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeLang(String lang) {
    const aliases = {
      'js': 'javascript', 'ts': 'typescript', 'py': 'python',
      'sh': 'bash', 'yml': 'yaml', 'md': 'markdown',
      'jsx': 'javascript', 'tsx': 'typescript', 'plaintext': 'plaintext',
    };
    return aliases[lang.toLowerCase()] ?? lang.toLowerCase();
  }
}
