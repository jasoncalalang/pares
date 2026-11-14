import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';

/// Large-number input (age / height / weight): a 13px label, then a 64px
/// white field with the value at 30px bold on the left and the unit muted
/// on the right. Numeric keyboard, digits only. The whole box takes the
/// tap, and while the field has focus it wears the same 2px annatto ring,
/// 2px outside, that [MpPress] draws. Emits the value when it is
/// a positive integer and `null` while the field is empty or zero, so the
/// screen can hold the CTA until every field is filled.
class MpBigValueField extends StatefulWidget {
  const MpBigValueField({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.spokenUnit,
    this.fieldKey,
  });

  final String label;

  /// Null shows the field empty.
  final int? value;
  final String unit;
  final ValueChanged<int?> onChanged;

  /// The unit as a screen reader should say it ("kilograms" for "kg");
  /// defaults to [unit].
  final String? spokenUnit;

  /// Key placed on the inner [TextField] for tests and automation.
  final Key? fieldKey;

  @override
  State<MpBigValueField> createState() => _MpBigValueFieldState();
}

class _MpBigValueFieldState extends State<MpBigValueField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value?.toString() ?? '');

  late final FocusNode _focus = FocusNode()..addListener(_focusChanged);

  void _focusChanged() {
    setState(() {});
    if (_focus.hasFocus) _revealRing();
  }

  /// Scrolls the box and its ring into view, not just the line of digits.
  void _revealRing() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _boxKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      box.showOnScreen(
        rect: (Offset.zero & box.size).inflate(
          MpStroke.focus + MpStroke.focusGap,
        ),
      );
    });
  }

  final _boxKey = GlobalKey();

  @override
  void dispose() {
    _focus
      ..removeListener(_focusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    final n = int.tryParse(text);
    widget.onChanged(n != null && n > 0 ? n : null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The field itself carries the label and unit for screen readers.
        ExcludeSemantics(
          child: Text(widget.label, style: MpTypography.label().copyWith(color: c.ink)),
        ),
        const SizedBox(height: 7),
        // Not an MpPress: the text field is the control and names itself.
        // This only widens its hit area from the line of digits to the 64px
        // box a person sees, unit included. The tap region makes the padding
        // and unit count as inside the field, so a mouse click there on a
        // field that already has focus does not drop and retake it.
        TextFieldTapRegion(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _focus.requestFocus,
            child: Container(
              key: _boxKey,
              height: MpSize.bigInput,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(MpRadius.input),
                border: Border.all(color: c.outline),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MpRadius.input),
                border: Border.all(
                  color: _focus.hasFocus ? c.annatto : Colors.transparent,
                  width: MpStroke.focus,
                  strokeAlign: BorderSide.strokeAlignOutside +
                      2 * MpStroke.focusGap / MpStroke.focus,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      label: '${widget.label}, in ${widget.spokenUnit ?? widget.unit}',
                      child: TextField(
                        key: widget.fieldKey,
                        controller: _controller,
                        focusNode: _focus,
                        onChanged: _changed,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        style: MpTypography.bigValue().copyWith(color: c.ink),
                        cursorColor: c.annatto,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      widget.unit,
                      style: MpTypography.label().copyWith(
                        color: c.faint,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
