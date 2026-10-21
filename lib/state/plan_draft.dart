import 'package:flutter/foundation.dart';

import '../mealpal_ph.dart';

/// The number fields on Body stats.
enum BodyStat { age, height, weight }

/// Everything the onboarding flow collects, plus what the domain derives from
/// it. One instance lives for the whole flow and is handed to each screen.
/// In-memory only: there is no persistence layer yet.
class PlanDraft extends ChangeNotifier {
  static const int budgetStepPhp = 100;
  static const int budgetFloorPhp = 500;

  BiologicalSex _sex = BiologicalSex.male;
  int _age = 29;
  int _heightCm = 171;
  int _weightKg = 74;
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal _goal = Goal.lose;
  int _weeklyBudgetPhp = 2500;
  final Set<String> _selectedStoreIds = {'puregold', 'palengke'};
  final Set<BodyStat> _blank = {};

  BiologicalSex get sex => _sex;
  set sex(BiologicalSex v) => _set(() => _sex = v);

  int get age => _age;
  set age(int v) => _set(() => _age = v);

  int get heightCm => _heightCm;
  set heightCm(int v) => _set(() => _heightCm = v);

  int get weightKg => _weightKg;
  set weightKg(int v) => _set(() => _weightKg = v);

  /// Whether the user has emptied [stat]'s field. The draft keeps the last
  /// value it was given, but the field shows empty and the flow waits until
  /// it is filled again. Kept here, not in the screen, because the draft
  /// outlives the screen when the user goes back and returns.
  bool isBlank(BodyStat stat) => _blank.contains(stat);
  bool get bodyStatsComplete => _blank.isEmpty;
  void setBlank(BodyStat stat, {required bool blank}) =>
      _set(() => blank ? _blank.add(stat) : _blank.remove(stat));

  ActivityLevel get activity => _activity;
  set activity(ActivityLevel v) => _set(() => _activity = v);

  Goal get goal => _goal;
  set goal(Goal v) => _set(() => _goal = v);

  int get weeklyBudgetPhp => _weeklyBudgetPhp;
  bool get canBudgetDown => _weeklyBudgetPhp > budgetFloorPhp;

  void budgetUp() => _set(() => _weeklyBudgetPhp += budgetStepPhp);

  void budgetDown() => _set(() {
        final next = _weeklyBudgetPhp - budgetStepPhp;
        _weeklyBudgetPhp = next < budgetFloorPhp ? budgetFloorPhp : next;
      });

  Set<String> get selectedStoreIds => Set.unmodifiable(_selectedStoreIds);
  int get selectedStoreCount => _selectedStoreIds.length;
  bool isStoreSelected(String id) => _selectedStoreIds.contains(id);

  void toggleStore(String id) => _set(() {
        if (!_selectedStoreIds.remove(id)) _selectedStoreIds.add(id);
      });

  CalorieTargetResult get target => calorieTarget(
        weightKg: _weightKg.toDouble(),
        heightCm: _heightCm.toDouble(),
        age: _age,
        sex: _sex,
        activity: _activity,
        goal: _goal,
      );

  MacroSplit get macros => macroSplit(target.targetCalories);

  /// Target as a share of maintenance (TDEE): what the calorie ring draws.
  /// Capped at 1 so a gain goal fills the ring rather than overflowing it.
  double get targetFraction {
    final t = target;
    return (t.targetCalories / t.tdee).clamp(0, 1).toDouble();
  }

  void _set(VoidCallback mutate) {
    mutate();
    notifyListeners();
  }
}
