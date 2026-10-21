import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/design_system/design_system.dart';

void main() {
  group('MpColors', () {
    const c = MpColors.light;

    test('pins the brand palette from the design system', () {
      expect(c.cream, const Color(0xFFFCF8EF));
      expect(c.ink, const Color(0xFF241C15));
      expect(c.muted, const Color(0xFF6B5D4C));
      // Faint copy is still read at 12px, so it clears 4.5:1 on cream and white.
      expect(c.faint, const Color(0xFF776855));
      expect(c.annatto, const Color(0xFFB5401C));
      expect(c.annattoDeep, const Color(0xFFA8370F));
      expect(c.annattoTint, const Color(0xFFFBEDE5));
      expect(c.annattoFleck, const Color(0xFFF0A36B));
      expect(c.green, const Color(0xFF2E7D4F));
      expect(c.greenDeep, const Color(0xFF1F6B3F));
      expect(c.greenTint, const Color(0xFFEAF4EC));
      // Amber labels the fat macro and snacks at 11-12px: 4.5:1 on its tint.
      expect(c.amber, const Color(0xFF8C5F10));
      expect(c.amberTint, const Color(0xFFFBF0D8));
      expect(c.surface, const Color(0xFFFFFFFF));
      expect(c.hairline, const Color(0xFFECE3D2));
      // Control boundaries (inputs, toggles, tiles) clear 3:1 on cream and white.
      expect(c.outline, const Color(0xFF998871));
      expect(c.divider, const Color(0xFFF2EADB));
      expect(c.track, const Color(0xFFEEE6D7));
      expect(c.heroSurface, const Color(0xFF241C15));
      expect(c.heroMuted, const Color(0xFFC9BEB0));
    });

    test('is a ThemeExtension that survives lerp', () {
      final mid = c.lerp(c, 0.5);
      expect(mid.annatto, c.annatto);
      expect(mid.outline, c.outline);
      expect(c.copyWith(), isA<MpColors>());
    });
  });

  group('MpTypography', () {
    test('uses Fraunces for display and Plus Jakarta Sans for UI', () {
      expect(MpTypography.h1().fontFamily, 'Fraunces');
      expect(MpTypography.heroNumber().fontFamily, 'Fraunces');
      expect(MpTypography.wordmark().fontFamily, 'Fraunces');
      expect(MpTypography.body().fontFamily, 'PlusJakartaSans');
      expect(MpTypography.eyebrow().fontFamily, 'PlusJakartaSans');
      expect(MpTypography.button().fontFamily, 'PlusJakartaSans');
    });

    test('pins the key sizes and weights', () {
      expect(MpTypography.h1().fontSize, 28);
      expect(MpTypography.h1().fontWeight, FontWeight.w600);
      expect(MpTypography.heroNumber().fontSize, 50);
      expect(MpTypography.bigValue().fontSize, 30);
      expect(MpTypography.bigValue().fontWeight, FontWeight.w700);
      expect(MpTypography.eyebrow().fontSize, 12);
      expect(MpTypography.eyebrow().letterSpacing, closeTo(12 * 0.12, 1e-9));
      expect(MpTypography.body().fontSize, 14);
      expect(MpTypography.button().fontSize, 15);
      expect(MpTypography.button().fontWeight, FontWeight.w700);
    });

    test('drives the variable-font weight axis, not just FontWeight', () {
      final variations = MpTypography.h1().fontVariations!;
      expect(variations, contains(const FontVariation('wght', 600)));
      final ui = MpTypography.button().fontVariations!;
      expect(ui, contains(const FontVariation('wght', 700)));
    });
  });

  group('MpMotion', () {
    test('pins the feedback and reveal timings', () {
      expect(MpMotion.press, const Duration(milliseconds: 120));
      expect(MpMotion.pressScale, 0.97);
      expect(MpMotion.select, const Duration(milliseconds: 250));
      expect(MpMotion.reveal, const Duration(milliseconds: 850));
      expect(MpMotion.expand, const Duration(milliseconds: 350));
    });

    testWidgets('collapses durations when animations are disabled',
        (tester) async {
      late Duration seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              seen = MpMotion.of(context, MpMotion.reveal);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, Duration.zero);
    });
  });

  group('MpTheme', () {
    test('registers MpColors and paints the cream ground', () {
      final theme = MpTheme.light();
      expect(theme.extension<MpColors>(), isNotNull);
      expect(theme.scaffoldBackgroundColor, MpColors.light.cream);
      expect(theme.colorScheme.primary, MpColors.light.annatto);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'PlusJakartaSans');
    });
  });

  group('layout tokens', () {
    test('pins gutters, radii and control heights', () {
      expect(MpSpacing.gutter, 22);
      expect(MpSpacing.top, 24);
      expect(MpRadius.button, 15);
      expect(MpRadius.card, 16);
      expect(MpRadius.input, 13);
      expect(MpRadius.pill, 999);
      expect(MpSize.cta, 54);
      expect(MpSize.control, 52);
      expect(MpSize.bigInput, 64);
      expect(MpSize.tap, 44);
    });

    test('every square control is at least the 44px tap target', () {
      expect(MpSize.swap, greaterThanOrEqualTo(MpSize.tap));
      expect(MpSize.stepper, greaterThanOrEqualTo(MpSize.tap));
    });
  });
}
