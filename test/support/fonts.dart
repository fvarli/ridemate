// ─────────────────────────────────────────────────────────────
// RideMate — Font loading for golden tests
//
// Without this, the test binary renders every glyph as a filled box (Ahem),
// so goldens would compare boxes rather than the real typography — which is
// half of what the design system IS.
//
// Written by hand rather than pulling in golden_toolkit: it is ~30 lines,
// and the package is no longer actively maintained.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled families, mapped to the weight files declared in pubspec.yaml.
const Map<String, List<String>> _families = <String, List<String>>{
  'Manrope': <String>[
    'assets/fonts/Manrope-Regular.ttf',
    'assets/fonts/Manrope-Medium.ttf',
    'assets/fonts/Manrope-SemiBold.ttf',
    'assets/fonts/Manrope-Bold.ttf',
    'assets/fonts/Manrope-ExtraBold.ttf',
  ],
  'IBM Plex Mono': <String>[
    'assets/fonts/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono-Medium.ttf',
    'assets/fonts/IBMPlexMono-SemiBold.ttf',
  ],
};

bool _loaded = false;

/// Loads the bundled fonts into the test binary.
///
/// Safe to call repeatedly; only the first call does work.
Future<void> loadRideMateFonts() async {
  if (_loaded) return;
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final MapEntry<String, List<String>> family in _families.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String path in family.value) {
      final File file = File(path);
      if (!file.existsSync()) {
        throw StateError(
          'Missing bundled font $path. Goldens would render placeholder '
          'boxes instead of real type.',
        );
      }
      loader.addFont(
        Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await _loadMaterialIcons();
  await _loadEmojiFont();
  _loaded = true;
}

/// Loads a colour emoji font, if the host has one.
///
/// The approved chat copy contains emoji, which are in neither bundled family —
/// on a device they hit the platform emoji font, and without an equivalent here
/// the goldens would bake tofu into the baseline instead.
///
/// Best-effort by design: the golden suite is already declared host-dependent
/// and Linux-generated (see tool/goldens.sh), and no emoji package is added for
/// three glyphs. If no font is found the tests still run.
Future<void> _loadEmojiFont() async {
  const List<String> candidates = <String>[
    '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
    '/usr/share/fonts/noto/NotoColorEmoji.ttf',
    '/System/Library/Fonts/Apple Color Emoji.ttc',
  ];
  for (final String path in candidates) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    final FontLoader loader = FontLoader('Noto Color Emoji')
      ..addFont(
        Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())),
      );
    await loader.load();
    return;
  }
}

/// Loads Flutter's MaterialIcons from the SDK cache.
///
/// RideMate's own icons are SVG, but the debug gallery's chrome uses a couple
/// of stock Material icons. Without this they rasterize as empty boxes and add
/// noise to every baseline.
///
/// Best-effort: if the SDK layout changes, goldens still run — they just show
/// the boxes again.
Future<void> _loadMaterialIcons() async {
  final String? flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? _flutterRootFromExecutable();
  if (flutterRoot == null) return;

  final File font = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!font.existsSync()) return;

  final FontLoader loader = FontLoader('MaterialIcons')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(font.readAsBytesSync())),
    );
  await loader.load();
}

/// Derives the SDK root from `which flutter`, for shells that do not export
/// FLUTTER_ROOT.
String? _flutterRootFromExecutable() {
  for (final String dir in (Platform.environment['PATH'] ?? '').split(':')) {
    final File candidate = File('$dir/flutter');
    if (candidate.existsSync()) {
      // .../flutter/bin/flutter -> .../flutter
      return Directory(dir).parent.path;
    }
  }
  return null;
}
