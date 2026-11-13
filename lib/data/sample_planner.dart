import '../mealpal_ph.dart';
import 'sample_week.dart';

/// A [Planner] that needs no server: it answers from the local sample bank,
/// ready at once. Used when the app is built without a server URL.
///
/// The week is the same whatever the brief asks for, so every snapshot
/// carries [sampleNotice]: This week shows it under the person's own target
/// and budget, which this week was not built to.
class SamplePlanner implements Planner {
  static const _id = 'sample';

  static const sampleNotice =
      'This is a sample week. It is not matched to your target, budget or '
      'stores yet.';

  List<DayPlan>? _week;

  @override
  Future<PlanSnapshot> start(PlanBrief brief) async {
    _week = sampleWeek();
    return _snapshot();
  }

  @override
  Future<PlanSnapshot> fetch(String id) async => _snapshot(id);

  @override
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  }) async {
    final week = _known(id);
    _week = [
      for (final d in week)
        if (d.weekday != day)
          d
        else
          DayPlan(
            weekday: d.weekday,
            meals: [
              for (final m in d.meals) m.slot == slot ? nextAlternative(m) : m,
            ],
          ),
    ];
    return _snapshot();
  }

  List<DayPlan> _known(String id) {
    final week = _week;
    if (id != _id || week == null) {
      throw const PlannerException(PlannerErrorKind.notFound);
    }
    return week;
  }

  PlanSnapshot _snapshot([String id = _id]) =>
      PlanSnapshot(
        id: _id,
        status: PlanStatus.ready,
        week: _known(id),
        message: sampleNotice,
      );
}
