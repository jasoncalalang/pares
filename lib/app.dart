import 'package:flutter/material.dart';

import 'data/sample_week.dart';
import 'design_system/design_system.dart';
import 'screens/body_stats_screen.dart';
import 'screens/daily_target_screen.dart';
import 'screens/grocery_list_screen.dart';
import 'screens/this_week_screen.dart';
import 'screens/where_you_shop_screen.dart';
import 'state/plan_draft.dart';

/// MealPal PH — app root. One [PlanDraft] lives for the whole flow and is
/// handed to every screen; screens navigate with plain pushes and fade
/// between each other the way the mockups' view transitions do.
class MealPalApp extends StatelessWidget {
  const MealPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealPal PH',
      debugShowCheckedModeBanner: false,
      theme: MpTheme.light(),
      home: const _Flow(),
    );
  }
}

class _Flow extends StatefulWidget {
  const _Flow();

  @override
  State<_Flow> createState() => _FlowState();
}

class _FlowState extends State<_Flow> {
  final PlanDraft _draft = PlanDraft();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(_fade(context, screen));
  }

  Route<void> _fade(BuildContext context, Widget screen) {
    return PageRouteBuilder<void>(
      transitionDuration: MpMotion.of(context, MpMotion.select),
      reverseTransitionDuration: MpMotion.of(context, MpMotion.select),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  void _notYet(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BodyStatsScreen(
      draft: _draft,
      onNext: () => _push(
        context,
        Builder(
          builder: (context) => DailyTargetScreen(
            draft: _draft,
            onBack: () => Navigator.of(context).pop(),
            onNext: () => _push(
              context,
              Builder(
                builder: (context) => WhereYouShopScreen(
                  draft: _draft,
                  onBack: () => Navigator.of(context).pop(),
                  onNext: () => _push(
                    context,
                    Builder(
                      builder: (context) => ThisWeekScreen(
                        draft: _draft,
                        week: sampleWeek(),
                        onNew: () => _notYet(context, 'A fresh plan'),
                        onGrocery: () => _push(
                          context,
                          Builder(
                            builder: (context) => GroceryListScreen(
                              list: sampleGroceryList(
                                budgetPhp: _draft.weeklyBudgetPhp,
                              ),
                              onBack: () => Navigator.of(context).pop(),
                              onOrder: () =>
                                  _notYet(context, 'Delivery handoff'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
