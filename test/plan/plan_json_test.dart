import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

Map<String, Object?> meal(String slot, {String? image, Object? kcal = 560}) => {
  'slot': slot,
  'id': 'm-$slot',
  'name': 'Meal $slot',
  'kcal': kcal,
  'pricePhp': 95,
  'image': image,
  'servings': 1.5,
};

Map<String, Object?> day(String weekday) => {
  'weekday': weekday,
  'meals': [
    meal('breakfast', image: 'tapsilog'),
    meal('lunch'),
    meal('dinner'),
    meal('snack'),
  ],
  'kcal': 2240,
  'pricePhp': 380,
};

const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

Map<String, Object?> record({
  String status = 'ready',
  Object? week = 'default',
  String? message,
}) => {
  'id': 'abc123',
  'status': status,
  'week': week == 'default'
      ? {
          'days': [for (final d in weekdays) day(d)],
          'pricePhp': 2660,
        }
      : week,
  'message': message,
};

void main() {
  group('planSnapshotFromJson', () {
    test('reads a ready plan into a week of days and meals', () {
      final snap = planSnapshotFromJson(record());
      expect(snap.id, 'abc123');
      expect(snap.status, PlanStatus.ready);
      expect(snap.message, isNull);
      final week = snap.week!;
      expect(week.map((d) => d.weekday), Weekday.values);
      final first = week.first.meals.first;
      expect(first.slot, MealSlot.breakfast);
      expect(first.id, 'm-breakfast');
      expect(first.name, 'Meal breakfast');
      expect(first.kcal, 560);
      expect(first.pricePhp, 95);
      expect(first.image, 'tapsilog');
      expect(first.servings, 1.5);
      expect(week.first.meals[1].image, isNull);
      expect(week.first.kcal, 2240);
    });

    test('servings may arrive as a whole number', () {
      final r = record();
      final d = ((r['week'] as Map)['days'] as List).first as Map;
      ((d['meals'] as List).first as Map)['servings'] = 2;
      final meal = planSnapshotFromJson(r).week!.first.meals.first;
      expect(meal.servings, 2.0);
    });

    test('a meal with no servings counts as one', () {
      final r = record();
      final d = ((r['week'] as Map)['days'] as List).first as Map;
      ((d['meals'] as List).first as Map).remove('servings');
      expect(planSnapshotFromJson(r).week!.first.meals.first.servings, 1.0);
    });

    test('a first plan in progress has no week', () {
      final snap = planSnapshotFromJson(record(status: 'building', week: null));
      expect(snap.status, PlanStatus.building);
      expect(snap.week, isNull);
    });

    test('a swap in progress keeps the old week', () {
      final snap = planSnapshotFromJson(record(status: 'building'));
      expect(snap.status, PlanStatus.building);
      expect(snap.week, hasLength(7));
    });

    test('keeps the message on a ready or failed plan', () {
      final ready = planSnapshotFromJson(
        record(message: 'That swap did not change anything.'),
      );
      expect(ready.message, 'That swap did not change anything.');
      final failed = planSnapshotFromJson(
        record(status: 'failed', week: null, message: 'No week fit.'),
      );
      expect(failed.status, PlanStatus.failed);
      expect(failed.message, 'No week fit.');
    });

    void expectBad(Object? json) {
      expect(
        () => planSnapshotFromJson(json),
        throwsA(
          isA<PlannerException>().having(
            (e) => e.kind,
            'kind',
            PlannerErrorKind.badResponse,
          ),
        ),
      );
    }

    test('rejects anything that is not a plan record', () {
      expectBad('nope');
      expectBad(<Object?>[]);
      expectBad(null);
    });

    test('rejects an unknown status, weekday or slot', () {
      expectBad(record(status: 'cooking'));
      expectBad(
        record(
          week: {
            'days': [day('funday')],
          },
        ),
      );
      final badSlot = day('mon');
      (badSlot['meals']! as List)[0] = meal('brunch');
      expectBad(
        record(
          week: {
            'days': [badSlot],
          },
        ),
      );
    });

    test('rejects missing or mistyped fields', () {
      expectBad({...record()}..remove('id'));
      expectBad({...record()}..remove('status'));
      expectBad(record(week: {'pricePhp': 1}));
      final noName = day('mon');
      ((noName['meals']! as List)[0] as Map).remove('name');
      expectBad(
        record(
          week: {
            'days': [noName],
          },
        ),
      );
      final badKcal = day('mon');
      (badKcal['meals']! as List)[0] = meal('breakfast', kcal: '560');
      expectBad(
        record(
          week: {
            'days': [badKcal],
          },
        ),
      );
    });
  });

  group('problemsFromJson', () {
    test('reads the message and the problems list of an error body', () {
      expect(errorMessageFromJson({'message': 'Nope.'}), 'Nope.');
      expect(
        errorProblemsFromJson({
          'problems': ['a', 'b'],
        }),
        ['a', 'b'],
      );
    });

    test('is empty or null when the body has neither', () {
      expect(errorMessageFromJson('x'), isNull);
      expect(errorMessageFromJson({'message': 3}), isNull);
      expect(errorProblemsFromJson(null), isEmpty);
      expect(errorProblemsFromJson({'problems': 'a'}), isEmpty);
    });
  });
}
