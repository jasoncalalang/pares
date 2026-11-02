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

  group('network access', () {
    String manifest(String flavour) =>
        File('android/app/src/$flavour/AndroidManifest.xml').readAsStringSync();

    test('the main manifest asks for INTERNET so a release build can reach '
        'the server', () {
      expect(
        manifest('main'),
        contains('<uses-permission android:name="android.permission.INTERNET"'),
      );
    });

    test('no manifest sets usesCleartextTraffic: it would not gate this '
        "app's dart:io traffic, so it must not look like a guard", () {
      for (final flavour in ['main', 'profile', 'debug']) {
        expect(manifest(flavour), isNot(contains('usesCleartextTraffic')));
      }
    });
  });
}
