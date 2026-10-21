import 'package:flutter/painting.dart';

import 'mp_colors.dart';

/// Shadows. The page is flat cream paper; only the welcome collage lifts off
/// it, because the plates on the table are that screen's motif. The grocery
/// total card's hairline shadow lives on `MpCard(shadow: true)`.
abstract final class MpElevation {
  /// A plate photo resting on the table.
  static List<BoxShadow> plate(MpColors c) => [
        BoxShadow(
          color: c.ink.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// A kcal / ₱ sticker stuck on a plate.
  static List<BoxShadow> sticker(MpColors c) => [
        BoxShadow(
          color: c.ink.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
