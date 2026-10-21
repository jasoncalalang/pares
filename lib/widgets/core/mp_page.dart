import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Page frame every screen uses: cream ground, safe area, 22px gutters,
/// 24px top padding, scrolling [content], and an optional [footer] (the
/// CTA block) pinned beneath the scroll area. At the largest text sizes a
/// footer may not fit; past half the screen's height it scrolls on its own
/// rather than overflow.
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
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                // Each area is one traversal group, so Tab walks all of the
                // content before the pinned footer instead of interleaving
                // them by where they sit on screen.
                Expanded(
                  child: FocusTraversalGroup(
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
                ),
                if (footer != null)
                  FocusTraversalGroup(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: box.maxHeight / 2),
                      child: SingleChildScrollView(
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: MpSpacing.sm,
                          bottom: MpSpacing.bottom,
                        ),
                        child: footer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-column grid built from plain rows so tiles keep their natural height
/// (no aspect-ratio guessing); the two tiles in a row stretch to match each
/// other, so a name that wraps doesn't leave its neighbour shorter. With
/// [columns] 1 it stacks the tiles instead, for when two would not fit.
class MpGrid2 extends StatelessWidget {
  const MpGrid2({
    super.key,
    required this.children,
    this.gap = MpSpacing.tileGap,
    this.columns = 2,
  }) : assert(columns == 1 || columns == 2);

  final List<Widget> children;
  final double gap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }
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
