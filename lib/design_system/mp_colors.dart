import 'package:flutter/material.dart';

/// Colour tokens for MealPal PH, pinned to the Superdesign/Claude Design
/// mockups. Warm cream ground, ink text, annatto (clay orange) primary,
/// leafy green secondary, amber for snacks/fat. No pink, purple, neon or
/// gradient washes.
@immutable
class MpColors extends ThemeExtension<MpColors> {
  const MpColors({
    required this.cream,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.annatto,
    required this.annattoDeep,
    required this.annattoTint,
    required this.annattoTintBorder,
    required this.annattoFleck,
    required this.green,
    required this.greenDeep,
    required this.greenTint,
    required this.greenTintBorder,
    required this.amber,
    required this.amberTint,
    required this.surface,
    required this.hairline,
    required this.outline,
    required this.divider,
    required this.dividerSoft,
    required this.track,
    required this.heroSurface,
    required this.heroText,
    required this.heroMuted,
    required this.heroTrack,
  });

  /// Page background.
  final Color cream;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Faint labels, helper copy, quantities. Still body-sized text, so it
  /// clears 4.5:1 on cream (5.1) and white (5.4).
  final Color faint;

  /// Primary accent: CTAs, step eyebrow, supermarket chains.
  final Color annatto;
  final Color annattoDeep;
  final Color annattoTint;
  final Color annattoTintBorder;

  /// Warm fleck used for the eyebrow inside the dark hero card.
  final Color annattoFleck;

  /// Secondary accent: local stores, budget progress, protein.
  final Color green;
  final Color greenDeep;
  final Color greenTint;
  final Color greenTintBorder;

  /// Snack slot and fat macro: 4.9:1 on its own tint at 11px.
  final Color amber;
  final Color amberTint;

  /// Card surface.
  final Color surface;

  /// 1px borders on non-interactive cards and dividers (decorative).
  final Color hairline;

  /// 1px boundary on interactive controls (inputs, toggles, tiles,
  /// steppers, checkboxes): 3.2:1 on cream and 3.4:1 on white, so the
  /// control edge itself passes WCAG 1.4.11.
  final Color outline;

  /// Row dividers inside cards.
  final Color divider;
  final Color dividerSoft;

  /// Progress-bar / segment track.
  final Color track;

  /// Dark hero card.
  final Color heroSurface;
  final Color heroText;
  final Color heroMuted;
  final Color heroTrack;

  static const MpColors light = MpColors(
    cream: Color(0xFFFCF8EF),
    ink: Color(0xFF241C15),
    muted: Color(0xFF6B5D4C),
    faint: Color(0xFF776855),
    annatto: Color(0xFFB5401C),
    annattoDeep: Color(0xFFA8370F),
    annattoTint: Color(0xFFFBEDE5),
    annattoTintBorder: Color(0xFFF3DCCE),
    annattoFleck: Color(0xFFF0A36B),
    green: Color(0xFF2E7D4F),
    greenDeep: Color(0xFF1F6B3F),
    greenTint: Color(0xFFEAF4EC),
    greenTintBorder: Color(0xFFD6E8DB),
    amber: Color(0xFF8C5F10),
    amberTint: Color(0xFFFBF0D8),
    surface: Color(0xFFFFFFFF),
    hairline: Color(0xFFECE3D2),
    outline: Color(0xFF998871),
    divider: Color(0xFFF2EADB),
    dividerSoft: Color(0xFFF4EDDF),
    track: Color(0xFFEEE6D7),
    heroSurface: Color(0xFF241C15),
    heroText: Color(0xFFFCF8EF),
    heroMuted: Color(0xFFC9BEB0),
    heroTrack: Color(0x24FCF8EF),
  );

  /// The 3px halo drawn around a selected control (`0 0 0 3px rgba(accent, .08)`).
  Color halo(Color accent) => accent.withValues(alpha: 0.08);

  @override
  MpColors copyWith({
    Color? cream,
    Color? ink,
    Color? muted,
    Color? faint,
    Color? annatto,
    Color? annattoDeep,
    Color? annattoTint,
    Color? annattoTintBorder,
    Color? annattoFleck,
    Color? green,
    Color? greenDeep,
    Color? greenTint,
    Color? greenTintBorder,
    Color? amber,
    Color? amberTint,
    Color? surface,
    Color? hairline,
    Color? outline,
    Color? divider,
    Color? dividerSoft,
    Color? track,
    Color? heroSurface,
    Color? heroText,
    Color? heroMuted,
    Color? heroTrack,
  }) {
    return MpColors(
      cream: cream ?? this.cream,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      annatto: annatto ?? this.annatto,
      annattoDeep: annattoDeep ?? this.annattoDeep,
      annattoTint: annattoTint ?? this.annattoTint,
      annattoTintBorder: annattoTintBorder ?? this.annattoTintBorder,
      annattoFleck: annattoFleck ?? this.annattoFleck,
      green: green ?? this.green,
      greenDeep: greenDeep ?? this.greenDeep,
      greenTint: greenTint ?? this.greenTint,
      greenTintBorder: greenTintBorder ?? this.greenTintBorder,
      amber: amber ?? this.amber,
      amberTint: amberTint ?? this.amberTint,
      surface: surface ?? this.surface,
      hairline: hairline ?? this.hairline,
      outline: outline ?? this.outline,
      divider: divider ?? this.divider,
      dividerSoft: dividerSoft ?? this.dividerSoft,
      track: track ?? this.track,
      heroSurface: heroSurface ?? this.heroSurface,
      heroText: heroText ?? this.heroText,
      heroMuted: heroMuted ?? this.heroMuted,
      heroTrack: heroTrack ?? this.heroTrack,
    );
  }

  @override
  MpColors lerp(ThemeExtension<MpColors>? other, double t) {
    if (other is! MpColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return MpColors(
      cream: l(cream, other.cream),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      annatto: l(annatto, other.annatto),
      annattoDeep: l(annattoDeep, other.annattoDeep),
      annattoTint: l(annattoTint, other.annattoTint),
      annattoTintBorder: l(annattoTintBorder, other.annattoTintBorder),
      annattoFleck: l(annattoFleck, other.annattoFleck),
      green: l(green, other.green),
      greenDeep: l(greenDeep, other.greenDeep),
      greenTint: l(greenTint, other.greenTint),
      greenTintBorder: l(greenTintBorder, other.greenTintBorder),
      amber: l(amber, other.amber),
      amberTint: l(amberTint, other.amberTint),
      surface: l(surface, other.surface),
      hairline: l(hairline, other.hairline),
      outline: l(outline, other.outline),
      divider: l(divider, other.divider),
      dividerSoft: l(dividerSoft, other.dividerSoft),
      track: l(track, other.track),
      heroSurface: l(heroSurface, other.heroSurface),
      heroText: l(heroText, other.heroText),
      heroMuted: l(heroMuted, other.heroMuted),
      heroTrack: l(heroTrack, other.heroTrack),
    );
  }
}

/// `context.mp`: the active [MpColors], falling back to [MpColors.light]
/// so bare widget tests without a theme still paint.
extension MpColorsContext on BuildContext {
  MpColors get mp => Theme.of(this).extension<MpColors>() ?? MpColors.light;
}

/// The three accent families a control can take. Annatto for supermarket
/// chains, CTAs and the breakfast/lunch/dinner slots; green for local stores,
/// budget progress and protein; amber for snacks and fat.
enum MpAccent { annatto, green, amber }

extension MpAccentColors on MpAccent {
  Color main(MpColors c) => switch (this) {
        MpAccent.annatto => c.annatto,
        MpAccent.green => c.green,
        MpAccent.amber => c.amber,
      };

  Color deep(MpColors c) => switch (this) {
        MpAccent.annatto => c.annattoDeep,
        MpAccent.green => c.greenDeep,
        MpAccent.amber => c.amber,
      };

  Color tint(MpColors c) => switch (this) {
        MpAccent.annatto => c.annattoTint,
        MpAccent.green => c.greenTint,
        MpAccent.amber => c.amberTint,
      };

  Color tintBorder(MpColors c) => switch (this) {
        MpAccent.annatto => c.annattoTintBorder,
        MpAccent.green => c.greenTintBorder,
        MpAccent.amber => c.amberTint,
      };
}
