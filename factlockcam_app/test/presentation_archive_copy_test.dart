import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final presentationRoots = [
    'lib/ui/mobile/archive',
    'lib/core/ui/widgets/heavy_metal_hub_tile.dart',
    'lib/core/ui/widgets/archive_panel_navigation_bar.dart',
  ];

  test('archive presentation sources exclude user-visible Vault label', () {
    for (final root in presentationRoots) {
      if (root.endsWith('.dart')) {
        _scanFile(File(root));
      } else {
        _scanDirectory(Directory(root));
      }
    }
  });
}

void _scanDirectory(Directory dir) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    _scanFile(entity);
  }
}

void _scanFile(File file) {
  final lines = file.readAsStringSync().split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('import ')) continue;
    if (line.contains('vaultService') ||
        line.contains('VaultService') ||
        line.contains('vaultDatabase') ||
        line.contains('localVaultStorage') ||
        line.contains('final vault =')) {
      continue;
    }

    final matches = RegExp(
      r'''['"]([^'"]{0,160})['"]''',
    ).allMatches(line);
    for (final match in matches) {
      final literal = match.group(1)!;
      expect(
        RegExp(r'\bVault\b', caseSensitive: false).hasMatch(literal),
        isFalse,
        reason: 'Deprecated Vault label in ${file.path}:${i + 1}: $literal',
      );
    }
  }
}
