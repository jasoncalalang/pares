import 'plan_models.dart';
import 'planner.dart';

PlannerException _bad(String what) => PlannerException(
  PlannerErrorKind.badResponse,
  message: 'Unreadable plan: $what.',
);

/// Reads the server's PlanRecord. Anything unexpected is a
/// [PlannerErrorKind.badResponse], never a half-built plan.
PlanSnapshot planSnapshotFromJson(Object? json) {
  final record = _map(json, 'plan');
  final status = _byName(PlanStatus.values, record['status'], 'status');
  final weekJson = record['week'];
  return PlanSnapshot(
    id: _string(record['id'], 'id'),
    status: status,
    week: weekJson == null ? null : _week(weekJson),
    message: _optionalString(record['message'], 'message'),
  );
}

/// The `message` of an error body, or null when there is none.
String? errorMessageFromJson(Object? json) {
  if (json is Map && json['message'] is String) {
    return json['message'] as String;
  }
  return null;
}

/// The `problems` of a 400 body, or an empty list.
List<String> errorProblemsFromJson(Object? json) {
  if (json is Map && json['problems'] is List) {
    return [
      for (final p in json['problems'] as List)
        if (p is String) p,
    ];
  }
  return const [];
}

List<DayPlan> _week(Object json) {
  final days = _map(json, 'week')['days'];
  if (days is! List) throw _bad('week has no days');
  return [for (final d in days) _day(d)];
}

DayPlan _day(Object? json) {
  final day = _map(json, 'day');
  final meals = day['meals'];
  if (meals is! List) throw _bad('day has no meals');
  return DayPlan(
    weekday: _byName(Weekday.values, day['weekday'], 'weekday'),
    meals: [for (final m in meals) _meal(m)],
  );
}

PlannedMeal _meal(Object? json) {
  final meal = _map(json, 'meal');
  return PlannedMeal(
    slot: _byName(MealSlot.values, meal['slot'], 'slot'),
    id: _string(meal['id'], 'meal id'),
    name: _string(meal['name'], 'meal name'),
    kcal: _int(meal['kcal'], 'kcal'),
    pricePhp: _int(meal['pricePhp'], 'pricePhp'),
    image: _optionalString(meal['image'], 'image'),
  );
}

Map<String, Object?> _map(Object? json, String what) {
  if (json is Map<String, Object?>) return json;
  if (json is Map) return json.cast<String, Object?>();
  throw _bad('$what is not an object');
}

String _string(Object? v, String what) {
  if (v is String) return v;
  throw _bad('$what is missing');
}

String? _optionalString(Object? v, String what) {
  if (v == null) return null;
  if (v is String) return v;
  throw _bad('$what is not text');
}

int _int(Object? v, String what) {
  if (v is int) return v;
  throw _bad('$what is not a whole number');
}

T _byName<T extends Enum>(List<T> values, Object? v, String what) {
  for (final e in values) {
    if (e.name == v) return e;
  }
  throw _bad('unknown $what');
}
