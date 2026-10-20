import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Page frame every screen uses: cream ground, safe area, 22px gutters,
/// 24px top padding, scrolling [content], and an optional [footer] (the
/// CTA block) pinned beneath the scroll area.
class MpPage extends StatelessWidget {
  const MpPage({super.key, required this.content, this.footer});

  final List<Widget> content;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.mp;
    return Scaffold(
      backgroundColor: c.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MpSpacing.gutter),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MpSpacing.top,
                    bottom: footer == null ? MpSpacing.bottom : MpSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: MpSpacing.sm,
                    bottom: MpSpacing.bottom,
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column grid built from plain rows so tiles keep their natural height
/// (no aspect-ratio guessing); the two tiles in a row stretch to match each
/// other, so a name that wraps doesn't leave its neighbour shorter.
class MpGrid2 extends StatelessWidget {
  const MpGrid2({super.key, required this.children, this.gap = MpSpacing.tileGap});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            SizedBox(width: gap),
            Expanded(
              child: i + 1 < children.length ? children[i + 1] : const SizedBox(),
            ),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}
