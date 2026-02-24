import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Parses AI responses for embedded file artifacts.
/// Handles:
///   ### FILE: path/to/file.ext
///   ```lang
///   content
///   ```
///   ### END_FILE
///
///   ### EDIT: path/to/file.ext
///   ### FIND:
///   ```old code```
///   ### REPLACE:
///   ```new code```
///   ### END_EDIT

class ArtifactParser {
  static const _uuid = Uuid();

  // ── Parse files from AI response ──────────────────────────────────────────
  static List<ArtifactFile> parseFiles(String content) {
    final files = <ArtifactFile>[];
    final filePattern = RegExp(
      r'###\s*FILE:\s*(.+?)\n```(\w*)\n([\s\S]*?)```\s*###\s*END_FILE',
      multiLine: true,
    );
    for (final match in filePattern.allMatches(content)) {
      final path = match.group(1)!.trim();
      final language = match.group(2)?.trim() ?? _detectLanguage(path);
      final fileContent = match.group(3) ?? '';
      files.add(ArtifactFile(
        path: path,
        content: fileContent,
        language: language.isNotEmpty ? language : _detectLanguage(path),
      ));
    }
    return files;
  }

  // ── Parse edits from AI response ──────────────────────────────────────────
  static List<EditInstruction> parseEdits(String content) {
    final edits = <EditInstruction>[];
    final editPattern = RegExp(
      r'###\s*EDIT:\s*(.+?)\n###\s*FIND:\n```[\w]*\n([\s\S]*?)```\n###\s*REPLACE:\n```[\w]*\n([\s\S]*?)```\s*###\s*END_EDIT',
      multiLine: true,
    );
    for (final match in editPattern.allMatches(content)) {
      edits.add(EditInstruction(
        filePath: match.group(1)!.trim(),
        find: match.group(2) ?? '',
        replace: match.group(3) ?? '',
      ));
    }
    return edits;
  }

  // ── Detect language from file extension ───────────────────────────────────
  static String _detectLanguage(String path) {
    final ext = path.split('.').last.toLowerCase();
    const map = {
      'dart': 'dart', 'py': 'python', 'js': 'javascript', 'ts': 'typescript',
      'jsx': 'jsx', 'tsx': 'tsx', 'html': 'html', 'css': 'css',
      'json': 'json', 'yaml': 'yaml', 'yml': 'yaml', 'md': 'markdown',
      'sh': 'bash', 'gradle': 'groovy', 'kt': 'kotlin', 'swift': 'swift',
      'go': 'go', 'rs': 'rust', 'cpp': 'cpp', 'c': 'c', 'h': 'cpp',
      'sql': 'sql', 'xml': 'xml', 'toml': 'toml', 'env': 'bash',
    };
    return map[ext] ?? 'plaintext';
  }

  // ── Build Artifact from parsed files ──────────────────────────────────────
  static Artifact? buildArtifact(String content, String messageId) {
    final files = parseFiles(content);
    if (files.isEmpty) return null;

    final isProject = files.length > 1;
    final title = isProject
        ? _inferProjectTitle(files)
        : files.first.path.split('/').last;

    return Artifact(
      id: messageId,
      title: title,
      type: isProject ? ArtifactType.project : ArtifactType.file,
      files: files,
    );
  }

  static String _inferProjectTitle(List<ArtifactFile> files) {
    for (final f in files) {
      if (f.path.contains('pubspec.yaml')) return 'Flutter Project';
      if (f.path.contains('package.json')) return 'Node.js Project';
      if (f.path.contains('requirements.txt')) return 'Python Project';
      if (f.path.contains('go.mod')) return 'Go Project';
      if (f.path.contains('Cargo.toml')) return 'Rust Project';
    }
    return 'Generated Project';
  }

  // ── Apply edit instructions to existing files ─────────────────────────────
  static Map<String, String> applyEdits(
    Map<String, String> existingFiles,
    List<EditInstruction> edits,
  ) {
    final result = Map<String, String>.from(existingFiles);
    for (final edit in edits) {
      final current = result[edit.filePath] ?? '';
      if (current.contains(edit.find)) {
        result[edit.filePath] = current.replaceFirst(edit.find, edit.replace);
      }
    }
    return result;
  }

  // ── Create downloadable ZIP ───────────────────────────────────────────────
  static Future<String> createZip(Artifact artifact) async {
    final archive = Archive();
    final projectName = artifact.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_');

    for (final file in artifact.files) {
      final bytes = Uint8List.fromList(file.content.codeUnits);
      archive.addFile(ArchiveFile(
        '$projectName/${file.path}',
        bytes.length,
        bytes,
      ));
    }

    final zipBytes = ZipEncoder().encode(archive);
    final dir = await getTemporaryDirectory();
    final zipPath = '${dir.path}/${projectName}_${DateTime.now().millisecondsSinceEpoch}.zip';
    await File(zipPath).writeAsBytes(zipBytes);
    return zipPath;
  }

  // ── Save a single file ────────────────────────────────────────────────────
  static Future<String> saveFile(ArtifactFile file, String directory) async {
    final fullPath = '$directory/${file.path}';
    final f = File(fullPath);
    await f.parent.create(recursive: true);
    await f.writeAsString(file.content);
    return fullPath;
  }
}

class EditInstruction {
  final String filePath;
  final String find;
  final String replace;

  EditInstruction({
    required this.filePath,
    required this.find,
    required this.replace,
  });
}
