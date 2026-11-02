import 'package:flutter/material.dart';

import 'data/sample_planner.dart';
import 'data/sample_week.dart';
import 'design_system/design_system.dart';
import 'screens/body_stats_screen.dart';
import 'screens/daily_target_screen.dart';
import 'screens/grocery_list_screen.dart';
import 'screens/this_week_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/where_you_shop_screen.dart';
import 'mealpal_ph.dart';
import 'state/plan_draft.dart';
import 'state/week_plan_controller.dart';

/// The planner the app was built for: the MealPal server when
/// `--dart-define=MEALPAL_SERVER_URL=...` was given (with an optional
/// `MEALPAL_APP_KEY`), else the local sample bank, which needs no server.
Planner plannerFor({required String serverUrl, String appKey = ''}) {
  if (serverUrl.isEmpty) return SamplePlanner();
  return HttpPlanner(Uri.parse(serverUrl), appKey: appKey);
}

/// MealPal PH app root. The flow opens on Welcome; one [PlanDraft] lives
/// for the whole flow and is handed to every screen; screens navigate with
/// plain pushes and fade between each other the way the mockups' view
/// transitions do. The week comes from a [Planner] through one
/// [WeekPlanController]: the server when the app is built with a server
/// URL, else the local sample bank. The grocery list stays on sample data.
class MealPalApp extends StatelessWidget {
  const MealPalApp({super.key, this.planner});

  /// Overrides the build-time choice; tests pass a fake.
  final Planner? planner;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealPal PH',
      debugShowCheckedModeBanner: false,
      theme: MpTheme.light(),
      home: _Flow(
        planner:
            planner ??
            plannerFor(
              serverUrl: const String.fromEnvironment('MEALPAL_SERVER_URL'),
              appKey: const String.fromEnvironment('MEALPAL_APP_KEY'),
            ),
      ),
    );
  }
}

class _Flow extends StatefulWidget {
  const _Flow({required this.planner});

  final Planner planner;

  @override
  State<_Flow> createState() => _FlowState();
}

class _FlowState extends State<_Flow> {
  final PlanDraft _draft = PlanDraft();
  late final WeekPlanController _plan = WeekPlanController(widget.planner);

  @override
  void dispose() {
    _plan.dispose();
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

  Widget _bodyStats(BuildContext context) => BodyStatsScreen(
    draft: _draft,
    onBack: () => Navigator.of(context).pop(),
    onNext: () => _push(context, Builder(builder: _dailyTarget)),
  );

  Widget _dailyTarget(BuildContext context) => DailyTargetScreen(
    draft: _draft,
    onBack: () => Navigator.of(context).pop(),
    onNext: () => _push(context, Builder(builder: _whereYouShop)),
  );

  Widget _whereYouShop(BuildContext context) => WhereYouShopScreen(
    draft: _draft,
    onBack: () => Navigator.of(context).pop(),
    onNext: () {
      // An unchanged brief keeps the plan; a changed one rebuilds it.
      _plan.build(_draft.brief);
      _push(context, Builder(builder: _thisWeek));
    },
  );

  Widget _thisWeek(BuildContext context) => ThisWeekScreen(
    draft: _draft,
    controller: _plan,
    onBack: () => Navigator.of(context).pop(),
    onGrocery: () => _push(context, Builder(builder: _groceries)),
  );

  Widget _groceries(BuildContext context) => GroceryListScreen(
    list: sampleGroceryList(budgetPhp: _draft.weeklyBudgetPhp),
    onBack: () => Navigator.of(context).pop(),
  );

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      exampleDay: sampleWeek().first,
      onStart: () => _push(context, Builder(builder: _bodyStats)),
    );
  }
}
