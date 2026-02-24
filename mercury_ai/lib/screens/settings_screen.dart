import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brutalist_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _backendUrlCtrl;
  late bool _useRag;
  late double _temperature;

  @override
  void initState() {
    super.initState();
    final s = context.read<ChatProvider>().settings;
    _backendUrlCtrl = TextEditingController(text: s.backendUrl);
    _useRag = s.useRag;
    _temperature = s.temperature;
  }

  @override
  void dispose() {
    _backendUrlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final chat = context.read<ChatProvider>();
    chat.updateSettings(
      AppSettings(
        backendUrl: _backendUrlCtrl.text.trim(),
        useRag: _useRag,
        temperature: _temperature,
        defaultModel: chat.selectedModel,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Settings saved',
          style: GoogleFonts.spaceMono(fontSize: 12),
        ),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final borderColor = isDark
        ? AppColors.accent.withOpacity(0.4)
        : AppColors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: BrutalistButton(
              label: 'SAVE',
              icon: Icons.save,
              small: true,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: 'BACKEND CONNECTION'),
            const SizedBox(height: 12),
            BrutalistCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Backend URL'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _backendUrlCtrl,
                    style: GoogleFonts.spaceMono(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'http://localhost:8080',
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrutalistButton(
                    label: 'TEST CONNECTION',
                    icon: Icons.wifi,
                    small: true,
                    filled: false,
                    onPressed: () async {
                      final chat = context.read<ChatProvider>();
                      final health = chat.settings == chat.settings
                          ? null
                          : null;
                      // Trigger refresh
                      await chat.refreshModels();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              chat.isConnected
                                  ? 'Connected!'
                                  : 'Connection failed',
                              style: GoogleFonts.spaceMono(fontSize: 12),
                            ),
                            backgroundColor: chat.isConnected
                                ? AppColors.accent
                                : AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _SectionHeader(label: 'RAG PIPELINE'),
            const SizedBox(height: 12),
            BrutalistCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Enable RAG Memory'),
                            const SizedBox(height: 4),
                            Text(
                              'Uses snowflake-arctic-embed2 + FAISS + bge-reranker for context retrieval',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useRag,
                        onChanged: (v) => setState(() => _useRag = v),
                        activeThumbColor: isDark
                            ? AppColors.accent
                            : AppColors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BrutalistDivider(),
                  const SizedBox(height: 12),
                  _Label(
                    'Pipeline: snowflake-arctic-embed2 → FAISS (Top 15) → bge-reranker-v2-m3 → Top 5 → LLM',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      BrutalistTag(label: 'EMBED', color: AppColors.accentAlt),
                      const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      BrutalistTag(
                        label: 'FAISS DB',
                        color: AppColors.mutedDark,
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      BrutalistTag(label: 'TOP 15', color: AppColors.mutedDark),
                      const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      BrutalistTag(label: 'RERANK', color: AppColors.warning),
                      const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      BrutalistTag(label: 'TOP 5', color: AppColors.warning),
                      const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      BrutalistTag(label: 'LLM', color: AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _SectionHeader(label: 'MODEL SETTINGS'),
            const SizedBox(height: 12),
            BrutalistCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Temperature: ${_temperature.toStringAsFixed(1)}'),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: isDark
                          ? AppColors.accent
                          : AppColors.black,
                      inactiveTrackColor: AppColors.mutedDark,
                      thumbColor: isDark ? AppColors.accent : AppColors.black,
                      overlayColor: Colors.transparent,
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: _temperature,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (v) => setState(() => _temperature = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PRECISE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        'CREATIVE',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _SectionHeader(label: 'ABOUT'),
            const SizedBox(height: 12),
            BrutalistCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: isDark ? AppColors.accent : AppColors.black,
                        child: Icon(
                          Icons.psychology,
                          color: isDark ? AppColors.black : AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXUS AI',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'v1.0.0 — Desktop AI Assistant',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BrutalistDivider(),
                  const SizedBox(height: 12),
                  ...[
                    ['Architecture', 'RAG + Vector Memory + Reranking'],
                    ['Vector DB', 'FAISS / ChromaDB'],
                    ['Embedding', 'snowflake-arctic-embed2'],
                    ['Reranker', 'qllama/bge-reranker-v2-m3'],
                    ['Interface', 'Flutter Desktop (Linux)'],
                  ].map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              row[0],
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            row[1],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: GoogleFonts.spaceMono(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: isDark ? AppColors.accent : AppColors.black,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.white : AppColors.black,
      ),
    );
  }
}
