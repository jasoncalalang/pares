import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../design_system/design_system.dart';

/// Third-party marks the provider buttons must show. These two are the only
/// brand marks the product carries (retailers stay monograms), and their
/// colours belong to the marks, not to the MealPal palette.
enum MpBrand { google, apple }

/// The Google "G" or the Apple mark, drawn from the official 24x24 path data
/// and scaled to [size]. The Apple mark takes [color]; the Google "G" keeps
/// its four brand colours.
class MpBrandMark extends StatelessWidget {
  const MpBrandMark(this.brand, {super.key, this.size = MpSize.brandMark, this.color});

  final MpBrand brand;
  final double size;
  final Color? color;

  /// Union of the mark's path bounds in its 24x24 design space.
  static Rect bounds(MpBrand brand) => _paths(brand, const Color(0x00000000))
      .map((p) => p.$2.getBounds())
      .reduce((a, b) => a.expandToInclude(b));

  static const _googleBlue = Color(0xFF4285F4);
  static const _googleGreen = Color(0xFF34A853);
  static const _googleYellow = Color(0xFFFBBC05);
  static const _googleRed = Color(0xFFEA4335);

  static List<(Color, Path)> _paths(MpBrand brand, Color tint) => switch (brand) {
        MpBrand.google => [
            (_googleBlue, parseSvgPathData('M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z')),
            (_googleGreen, parseSvgPathData('M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84A11 11 0 0 0 12 23z')),
            (_googleYellow, parseSvgPathData('M5.84 14.1a6.6 6.6 0 0 1 0-4.2V7.06H2.18a11 11 0 0 0 0 9.88l3.66-2.84z')),
            (_googleRed, parseSvgPathData('M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1A11 11 0 0 0 2.18 7.06l3.66 2.84C6.71 7.31 9.14 5.38 12 5.38z')),
          ],
        MpBrand.apple => [
            (tint, parseSvgPathData('M16.37 12.78c-.02-2.3 1.88-3.4 1.96-3.46-1.07-1.56-2.73-1.78-3.32-1.8-1.41-.14-2.76.83-3.47.83-.72 0-1.82-.81-3-.79-1.54.02-2.96.9-3.75 2.28-1.6 2.78-.41 6.9 1.15 9.16.76 1.1 1.67 2.34 2.86 2.3 1.15-.05 1.58-.74 2.97-.74 1.38 0 1.77.74 2.98.72 1.23-.02 2.01-1.12 2.76-2.23.87-1.28 1.23-2.52 1.25-2.58-.03-.01-2.4-.92-2.42-3.66zM14.1 5.86c.63-.77 1.06-1.83.94-2.9-.91.04-2.02.61-2.67 1.37-.58.68-1.09 1.77-.95 2.81 1.02.08 2.05-.52 2.68-1.28z')),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(_paths(brand, color ?? context.mp.ink)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.paths);

  final List<(Color, Path)> paths;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    for (final (color, path) in paths) {
      canvas.drawPath(path, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.paths != paths;
}
