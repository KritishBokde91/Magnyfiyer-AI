import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/artifact_parser.dart';
import '../theme/app_theme.dart';
import 'brutalist_widgets.dart';
import 'code_block.dart';

class ArtifactPanel extends StatefulWidget {
  final Artifact artifact;
  final VoidCallback? onAnalyze;

  const ArtifactPanel({
    super.key,
    required this.artifact,
    this.onAnalyze,
  });

  @override
  State<ArtifactPanel> createState() => _ArtifactPanelState();
}

class _ArtifactPanelState extends State<ArtifactPanel> {
  int _selectedFileIndex = 0;
  bool _isDownloading = false;

  ArtifactFile? get _selectedFile {
    if (widget.artifact.files.isEmpty) return null;
    return widget.artifact.files[_selectedFileIndex.clamp(0, widget.artifact.files.length - 1)];
  }

  Future<void> _downloadZip() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final zipPath = await ArtifactParser.createZip(widget.artifact);

      // Ask user where to save
      String? dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Save Project To',
      );
      if (dir != null) {
        final fileName = zipPath.split('/').last;
        final destPath = '$dir/$fileName';
        await File(zipPath).copy(destPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to $destPath', style: GoogleFonts.spaceMono(fontSize: 12)),
              backgroundColor: AppColors.accent,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.spaceMono(fontSize: 12)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _saveToDirectory() async {
    String? dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Save Project Files To',
    );
    if (dir == null) return;

    int saved = 0;
    for (final file in widget.artifact.files) {
      try {
        await ArtifactParser.saveFile(file, dir);
        saved++;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $saved files to $dir',
              style: GoogleFonts.spaceMono(fontSize: 12)),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.accent.withOpacity(0.4) : AppColors.black;
    final isProject = widget.artifact.type == ArtifactType.project;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.accent.withOpacity(0.15) : AppColors.black,
            offset: const Offset(6, 6),
            blurRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : AppColors.black,
              border: Border(bottom: BorderSide(color: borderColor, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isProject ? Icons.folder_special : Icons.insert_drive_file,
                      color: AppColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.artifact.title,
                        style: GoogleFonts.spaceMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    BrutalistTag(
                      label: isProject ? 'PROJECT' : 'FILE',
                      color: AppColors.accentAlt,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${widget.artifact.files.length} FILE${widget.artifact.files.length > 1 ? 'S' : ''}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: AppColors.muted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onAnalyze != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: BrutalistButton(
                          label: 'ANALYZE',
                          icon: Icons.bug_report,
                          small: true,
                          customBg: AppColors.warning,
                          onPressed: widget.onAnalyze,
                        ),
                      ),
                    if (isProject)
                      BrutalistButton(
                        label: _isDownloading ? 'SAVING...' : 'DOWNLOAD ZIP',
                        icon: Icons.download,
                        small: true,
                        onPressed: _isDownloading ? null : _downloadZip,
                      )
                    else
                      BrutalistButton(
                        label: 'SAVE FILE',
                        icon: Icons.save_alt,
                        small: true,
                        onPressed: _saveToDirectory,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── File Tree (if project) ────────────────────────────────────────
          if (isProject && widget.artifact.files.length > 1) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF8F7F2),
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: ListView.builder(
                itemCount: widget.artifact.files.length,
                itemBuilder: (ctx, i) {
                  final file = widget.artifact.files[i];
                  final isSelected = i == _selectedFileIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFileIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.black.withOpacity(0.06))
                            : null,
                        border: isSelected
                            ? Border(
                                left: BorderSide(
                                  color: isDark ? AppColors.accent : AppColors.black,
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _fileIcon(file.path),
                            size: 12,
                            color: isDark ? AppColors.accent : AppColors.black,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file.path,
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                color: isDark ? AppColors.white : AppColors.black,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Code View ────────────────────────────────────────────────────
          if (_selectedFile != null)
            Expanded(
              child: SingleChildScrollView(
                child: CodeBlock(
                  code: _selectedFile!.content,
                  language: _selectedFile!.language,
                  filename: _selectedFile!.path,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _fileIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    const map = {
      'dart': Icons.flutter_dash,
      'py': Icons.code,
      'js': Icons.javascript,
      'ts': Icons.code,
      'json': Icons.data_object,
      'yaml': Icons.settings,
      'yml': Icons.settings,
      'md': Icons.description,
      'html': Icons.html,
      'css': Icons.style,
      'sh': Icons.terminal,
    };
    return map[ext] ?? Icons.insert_drive_file;
  }
}
