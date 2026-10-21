import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file: loads the app's real fonts. The default
/// test font draws every glyph a full em wide, so layouts that depend on
/// where Fraunces or Plus Jakarta Sans wrap (the store grid, large text)
/// would be tested against text no phone ever shows.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (family, file) in [
    ('Fraunces', 'assets/fonts/Fraunces-Variable.ttf'),
    ('PlusJakartaSans', 'assets/fonts/PlusJakartaSans-Variable.ttf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load(file))).load();
  }
  await testMain();
}
