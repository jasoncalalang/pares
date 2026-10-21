import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Tap target with the brand's press feedback: a gentle scale to
/// [MpMotion.pressScale] while the finger is down. Declares itself a button
/// to assistive tech (pass [semanticLabel] when the child has no text), is
/// focusable and activates on Enter or Space, and paints a 2px annatto ring
/// round itself while it holds keyboard focus. A null [onTap] disables it.
class MpPress extends StatefulWidget {
  const MpPress({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.scale = MpMotion.pressScale,
    this.focusRadius = MpRadius.button,
    this.focusGap = MpStroke.focusGap,
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final double scale;

  /// Corner radius of the keyboard focus ring, matched to the child's shape.
  final double focusRadius;

  /// Clear space between the child's edge and the focus ring. The ring sits
  /// on the page round the control, so it shows on an annatto fill or an
  /// accent border alike. A parent that clips would cut it off.
  final double focusGap;
  final FocusNode? focusNode;

  /// Take focus when first built (the first control of a sheet).
  final bool autofocus;

  @override
  State<MpPress> createState() => _MpPressState();
}

class _MpPressState extends State<MpPress> {
  bool _down = false;
  bool _focused = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  void didUpdateWidget(MpPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabling mid-press drops the tap recognizer, whose cancel callback
    // then fires during build; clear the press here so it is a no-op.
    if (widget.onTap == null) _down = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        // Space is an ActivateIntent everywhere; Enter is an ActivateIntent on
        // mobile and desktop but a ButtonActivateIntent on the web.
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: MpMotion.of(context, MpMotion.press),
            child: Container(
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.focusRadius),
                border: Border.all(
                  color: _focused ? c.annatto : Colors.transparent,
                  width: MpStroke.focus,
                  // strokeAlign 1 starts the stroke at the edge; each extra
                  // half-width moves it a pixel further out.
                  strokeAlign: BorderSide.strokeAlignOutside +
                      2 * widget.focusGap / MpStroke.focus,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
