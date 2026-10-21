import 'dart:io';

import 'package:test/test.dart';

/// The name under the launcher icon is the product name, not the package id.
void main() {
  test('Android launcher label', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="MealPal PH"'));
  });

  test('iOS display name', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(r'<key>CFBundleDisplayName</key>\s*<string>MealPal PH</string>')
          .hasMatch(plist),
      isTrue,
    );
  });

  test('no em dash ships in the package description', () {
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('—')));
  });
}
