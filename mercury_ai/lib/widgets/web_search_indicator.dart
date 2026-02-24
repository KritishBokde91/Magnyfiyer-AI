import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'brutalist_widgets.dart';

/// Displays real-time web search progress in the chat
class WebSearchIndicator extends StatefulWidget {
  final List<WebSearchEvent> events;
  final bool isSearching;

  const WebSearchIndicator({
    super.key,
    required this.events,
    required this.isSearching,
  });

  @override
  State<WebSearchIndicator> createState() => _WebSearchIndicatorState();
}

class _WebSearchIndicatorState extends State<WebSearchIndicator> {
  bool _expanded = true;

  @override
  void didUpdateWidget(WebSearchIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto collapse if it just finished searching
    if (oldWidget.isSearching && !widget.isSearching) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.events.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg.withOpacity(0.6) : AppColors.offWhite,
        border: Border.all(
          color: isDark
              ? AppColors.accent.withOpacity(0.3)
              : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.black.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: _expanded
                        ? (isDark
                              ? AppColors.accent.withOpacity(0.2)
                              : AppColors.borderLight)
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.travel_explore,
                    size: 14,
                    color: isDark ? AppColors.accent : AppColors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WEB SEARCH',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.accent : AppColors.black,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  if (widget.isSearching)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: isDark ? AppColors.accent : AppColors.black,
                      ),
                    )
                  else
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.muted,
                    ),
                ],
              ),
            ),
          ),

          // Event list
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: widget.events
                    .map((e) => _buildEvent(e, isDark))
                    .toList(),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildEvent(WebSearchEvent event, bool isDark) {
    final textColor = isDark
        ? AppColors.white.withOpacity(0.8)
        : AppColors.black.withOpacity(0.7);
    final mutedColor = isDark ? AppColors.muted : AppColors.muted;

    switch (event.type) {
      case 'searching':
        return _EventRow(
          icon: Icons.search,
          iconColor: isDark ? AppColors.accent : AppColors.accentAlt,
          child: Row(
            children: [
              Text(
                'Searching: ',
                style: GoogleFonts.spaceMono(fontSize: 11, color: mutedColor),
              ),
              Flexible(
                child: Text(
                  event.query ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

      case 'found':
        return _EventRow(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.accent,
          child: Text(
            'Found ${event.total ?? 0} results',
            style: GoogleFonts.spaceMono(fontSize: 11, color: textColor),
          ),
        );

      case 'scraping':
        return _EventRow(
          icon: Icons.downloading,
          iconColor: isDark ? AppColors.warning : AppColors.accentAlt,
          child: Row(
            children: [
              BrutalistTag(
                label: '${event.index}/${event.total}',
                color: isDark ? AppColors.mutedDark : AppColors.borderLight,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _truncateUrl(event.url ?? ''),
                  style: GoogleFonts.spaceMono(fontSize: 10, color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

      case 'scraped':
        return _EventRow(
          icon: Icons.check,
          iconColor: AppColors.accent,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  event.title ?? _truncateUrl(event.url ?? ''),
                  style: GoogleFonts.inter(fontSize: 11, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${event.chars ?? 0} chars',
                style: GoogleFonts.spaceMono(fontSize: 9, color: mutedColor),
              ),
            ],
          ),
        );

      case 'failed':
        return _EventRow(
          icon: Icons.close,
          iconColor: AppColors.error,
          child: Text(
            _truncateUrl(event.url ?? ''),
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: AppColors.error.withOpacity(0.8),
              decoration: TextDecoration.lineThrough,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );

      case 'summarizing':
        return _EventRow(
          icon: Icons.auto_awesome,
          iconColor: isDark ? AppColors.accent : AppColors.accentAlt,
          child: Text(
            'Analyzing & summarizing...',
            style: GoogleFonts.spaceMono(fontSize: 11, color: textColor),
          ),
        );

      case 'done':
        return _EventRow(
          icon: Icons.check_circle,
          iconColor: AppColors.accent,
          child: Text(
            '${event.sources?.length ?? 0} sources ready',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.accent : AppColors.black,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _truncateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.length > 30
          ? '${uri.path.substring(0, 30)}...'
          : uri.path;
      return '${uri.host}$path';
    } catch (_) {
      return url.length > 50 ? '${url.substring(0, 50)}...' : url;
    }
  }
}

class _EventRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _EventRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms).slideX(begin: -0.05);
  }
}

/// Collapsible sources section shown below web search responses
class WebSourcesPanel extends StatefulWidget {
  final List<WebSource> sources;

  const WebSourcesPanel({super.key, required this.sources});

  @override
  State<WebSourcesPanel> createState() => _WebSourcesPanelState();
}

class _WebSourcesPanelState extends State<WebSourcesPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.sources.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header toggle
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: isDark
                  ? AppColors.accent.withOpacity(0.05)
                  : AppColors.offWhite,
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 12,
                    color: isDark ? AppColors.accent : AppColors.accentAlt,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.sources.length} SOURCES',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.accent : AppColors.accentAlt,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),

          // Expanded source list
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: widget.sources.map((s) {
                  return InkWell(
                    onTap: () async {
                      final url = Uri.parse(s.url);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 12,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title.isNotEmpty ? s.title : s.url,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.accent
                                        : AppColors.accentAlt,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  s.url,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9,
                                    color: AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
