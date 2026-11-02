import '../nutrition/calorie_target.dart';
import 'plan_models.dart';

/// Where the week's plan is in its life: being built by the recommender,
/// ready to show, or failed.
enum PlanStatus { ready, building, failed }

/// What the person asked for: the inputs a planner builds a week from.
class PlanBrief {
  PlanBrief({
    required this.targetKcal,
    required this.budgetPhp,
    required this.goal,
    required Iterable<String> storeIds,
  }) : storeIds = List.unmodifiable([...storeIds]..sort());

  final int targetKcal;
  final int budgetPhp;
  final Goal goal;

  /// Sorted, so the same stores in any order are the same brief.
  final List<String> storeIds;

  /// The body of the server's `POST /plans`.
  Map<String, Object?> toJson() => {
    'targetKcal': targetKcal,
    'budgetPhp': budgetPhp,
    'goal': goal.name,
    'storeIds': storeIds,
  };

  @override
  bool operator ==(Object other) =>
      other is PlanBrief &&
      other.targetKcal == targetKcal &&
      other.budgetPhp == budgetPhp &&
      other.goal == goal &&
      _sameList(other.storeIds, storeIds);

  @override
  int get hashCode =>
      Object.hash(targetKcal, budgetPhp, goal, Object.hashAll(storeIds));

  @override
  String toString() =>
      'PlanBrief($targetKcal kcal, PHP $budgetPhp, ${goal.name}, $storeIds)';

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One answer from a planner: the plan's id, how far along it is, the week
/// if there is one, and a message fit to show when the planner has
/// something to say.
class PlanSnapshot {
  const PlanSnapshot({
    required this.id,
    required this.status,
    this.week,
    this.message,
  });

  final String id;
  final PlanStatus status;

  /// Null while a first plan builds or after it failed. While a swap
  /// builds, the last accepted week.
  final List<DayPlan>? week;

  /// Why a swap changed nothing, or why a first plan failed.
  final String? message;
}

/// Builds and amends weekly plans. Implemented over HTTP for the server and
/// over the local sample bank for offline use.
abstract interface class Planner {
  Future<PlanSnapshot> start(PlanBrief brief);
  Future<PlanSnapshot> fetch(String id);
  Future<PlanSnapshot> swap(
    String id,
    Weekday day,
    MealSlot slot, {
    String? note,
  });
}

enum PlannerErrorKind {
  /// No connection, or the server did not answer in time.
  network,

  /// 400: the server refused the request; see [PlannerException.problems].
  rejected,

  /// 401: the app key is missing or wrong.
  unauthorized,

  /// 404: the server does not know this plan.
  notFound,

  /// 409: the plan is busy, or has no week to swap yet.
  busy,

  /// 503 and other 5xx.
  unavailable,

  /// The answer could not be read.
  badResponse,
}

class PlannerException implements Exception {
  const PlannerException(this.kind, {this.message, this.problems = const []});

  final PlannerErrorKind kind;

  /// The server's own words, when its body had some.
  final String? message;

  /// The list a 400 carries.
  final List<String> problems;

  @override
  String toString() =>
      'PlannerException(${kind.name}'
      '${message == null ? '' : ': $message'})';
}
