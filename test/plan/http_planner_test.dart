import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

Map<String, Object?> meal(String slot) => {
  'slot': slot,
  'id': 'm-$slot',
  'name': 'Meal $slot',
  'kcal': 500,
  'pricePhp': 80,
  'image': null,
  'servings': 1,
};

Map<String, Object?> week() => {
  'days': [
    for (final d in ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'])
      {
        'weekday': d,
        'meals': [
          for (final s in ['breakfast', 'lunch', 'dinner', 'snack']) meal(s),
        ],
        'kcal': 2000,
        'pricePhp': 320,
      },
  ],
  'pricePhp': 2240,
};

Map<String, Object?> record(
  String status, {
  bool withWeek = true,
  String? message,
}) => {
  'id': 'p1',
  'status': status,
  'week': withWeek ? week() : null,
  'message': message,
};

http.Response json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

final brief = PlanBrief(
  targetKcal: 2000,
  budgetPhp: 2500,
  goal: Goal.lose,
  storeIds: ['puregold', 'palengke'],
);

/// Runs [call] against a planner whose server answers with [handler] and
/// returns the requests the server saw.
class Rig {
  Rig(
    Future<http.Response> Function(http.Request) handler, {
    String base = 'http://host:8090',
    String? key,
    Duration? timeout,
  }) {
    planner = HttpPlanner(
      Uri.parse(base),
      appKey: key,
      client: MockClient((r) {
        seen.add(r);
        return handler(r);
      }),
      requestTimeout: timeout ?? const Duration(seconds: 20),
    );
  }
  final seen = <http.Request>[];
  late final HttpPlanner planner;
}

Rig answering(
  http.Response r, {
  String base = 'http://host:8090',
  String? key,
}) => Rig((_) async => r, base: base, key: key);

Matcher plannerError(PlannerErrorKind kind) =>
    throwsA(isA<PlannerException>().having((e) => e.kind, 'kind', kind));

void main() {
  group('start', () {
    test('POSTs the brief as JSON and reads the 202 record', () async {
      final rig = answering(json(202, record('building', withWeek: false)));
      final snap = await rig.planner.start(brief);
      expect(snap.status, PlanStatus.building);
      expect(snap.week, isNull);
      final r = rig.seen.single;
      expect(r.method, 'POST');
      expect(r.url.toString(), 'http://host:8090/plans');
      expect(r.headers['content-type'], contains('application/json'));
      expect(jsonDecode(r.body), brief.toJson());
    });

    test('400 is rejected and carries the problems', () async {
      final rig = answering(
        json(400, {
          'problems': ['targetKcal must be 1200 to 4500.', 'Pick a store.'],
        }),
      );
      await expectLater(
        rig.planner.start(brief),
        throwsA(
          isA<PlannerException>()
              .having((e) => e.kind, 'kind', PlannerErrorKind.rejected)
              .having((e) => e.problems, 'problems', [
                'targetKcal must be 1200 to 4500.',
                'Pick a store.',
              ]),
        ),
      );
    });

    test('503 is unavailable and keeps the server message', () async {
      final rig = answering(json(503, {'message': 'No planner session.'}));
      await expectLater(
        rig.planner.start(brief),
        throwsA(
          isA<PlannerException>()
              .having((e) => e.kind, 'kind', PlannerErrorKind.unavailable)
              .having((e) => e.message, 'message', 'No planner session.'),
        ),
      );
    });

    test('a 200 that is not a plan record is a bad response', () async {
      final rig = answering(http.Response('<html>proxy</html>', 200));
      await expectLater(
        rig.planner.start(brief),
        plannerError(PlannerErrorKind.badResponse),
      );
    });
  });

  group('fetch', () {
    test('GETs the plan and reads a ready week', () async {
      final rig = answering(json(200, record('ready')));
      final snap = await rig.planner.fetch('p1');
      expect(snap.status, PlanStatus.ready);
      expect(snap.week, hasLength(7));
      expect(rig.seen.single.method, 'GET');
      expect(rig.seen.single.url.path, '/plans/p1');
    });

    test('404 is notFound', () async {
      final rig = answering(json(404, {'message': 'No plan p1.'}));
      await expectLater(
        rig.planner.fetch('p1'),
        plannerError(PlannerErrorKind.notFound),
      );
    });

    test('500 is unavailable, an odd status is a bad response', () async {
      await expectLater(
        answering(json(500, {'message': 'boom'})).planner.fetch('p1'),
        plannerError(PlannerErrorKind.unavailable),
      );
      await expectLater(
        answering(http.Response('', 418)).planner.fetch('p1'),
        plannerError(PlannerErrorKind.badResponse),
      );
    });

    test(
      'an error with a body that is not JSON still maps by status',
      () async {
        await expectLater(
          answering(http.Response('<html>gateway</html>', 502)).planner
              .fetch('p1'),
          plannerError(PlannerErrorKind.unavailable),
        );
      },
    );
  });

  group('swap', () {
    test('POSTs weekday, slot and note', () async {
      final rig = answering(json(202, record('building')));
      final snap = await rig.planner.swap(
        'p1',
        Weekday.tue,
        MealSlot.dinner,
        note: 'no pork',
      );
      expect(snap.status, PlanStatus.building);
      expect(snap.week, hasLength(7));
      final r = rig.seen.single;
      expect(r.method, 'POST');
      expect(r.url.path, '/plans/p1/swaps');
      expect(jsonDecode(r.body), {
        'weekday': 'tue',
        'slot': 'dinner',
        'note': 'no pork',
      });
    });

    test('leaves the note out when there is none', () async {
      final rig = answering(json(202, record('building')));
      await rig.planner.swap('p1', Weekday.mon, MealSlot.snack);
      expect(jsonDecode(rig.seen.single.body), {
        'weekday': 'mon',
        'slot': 'snack',
      });
    });

    test('409 is busy with the server message', () async {
      final rig = answering(json(409, {'message': 'Still building.'}));
      await expectLater(
        rig.planner.swap('p1', Weekday.mon, MealSlot.lunch),
        throwsA(
          isA<PlannerException>()
              .having((e) => e.kind, 'kind', PlannerErrorKind.busy)
              .having((e) => e.message, 'message', 'Still building.'),
        ),
      );
    });

    test('400 and 404 map too', () async {
      await expectLater(
        answering(
          json(400, {
            'problems': ['x'],
          }),
        ).planner.swap('p1', Weekday.mon, MealSlot.lunch),
        plannerError(PlannerErrorKind.rejected),
      );
      await expectLater(
        answering(json(404, {'message': 'No plan.'})).planner
            .swap('p1', Weekday.mon, MealSlot.lunch),
        plannerError(PlannerErrorKind.notFound),
      );
    });

    test('a ready record may carry a message', () async {
      final rig = answering(
        json(200, record('ready', message: 'Nothing else fits there.')),
      );
      final snap = await rig.planner.fetch('p1');
      expect(snap.message, 'Nothing else fits there.');
    });
  });

  group('app key', () {
    test('401 is unauthorized', () async {
      final rig = answering(
        json(401, {'message': 'Missing or wrong key.'}),
        key: 'wrong',
      );
      await expectLater(
        rig.planner.fetch('p1'),
        plannerError(PlannerErrorKind.unauthorized),
      );
    });

    test('sends X-MealPal-Key on every call when there is a key', () async {
      final rig = answering(json(200, record('ready')), key: 's3cret');
      await rig.planner.fetch('p1');
      await rig.planner.start(brief);
      await rig.planner.swap('p1', Weekday.mon, MealSlot.lunch);
      expect(rig.seen, hasLength(3));
      for (final r in rig.seen) {
        expect(
          r.headers['X-MealPal-Key'] ?? r.headers['x-mealpal-key'],
          's3cret',
        );
      }
    });

    test('sends no key header when the key is null or empty', () async {
      for (final key in [null, '']) {
        final rig = answering(json(200, record('ready')), key: key);
        await rig.planner.fetch('p1');
        expect(
          rig.seen.single.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('x-mealpal-key')),
        );
      }
    });
  });

  group('paths', () {
    Future<String> pathFor(String base) async {
      final rig = answering(json(200, record('ready')), base: base);
      await rig.planner.fetch('p1');
      return rig.seen.single.url.toString();
    }

    test('joins with or without a trailing slash', () async {
      expect(await pathFor('http://h:1'), 'http://h:1/plans/p1');
      expect(await pathFor('http://h:1/'), 'http://h:1/plans/p1');
    });

    test('keeps a path prefix', () async {
      expect(
        await pathFor('https://h.run.app/api'),
        'https://h.run.app/api/plans/p1',
      );
      expect(
        await pathFor('https://h.run.app/api/'),
        'https://h.run.app/api/plans/p1',
      );
    });

    test('escapes the plan id', () async {
      final rig = answering(json(200, record('ready')));
      await rig.planner.fetch('a/b c');
      expect(rig.seen.single.url.path, '/plans/a%2Fb%20c');
    });
  });

  group('network trouble', () {
    test('a timeout is a network error', () async {
      final never = Completer<http.Response>();
      final rig = Rig((_) => never.future, timeout: Duration.zero);
      await expectLater(
        rig.planner.fetch('p1'),
        plannerError(PlannerErrorKind.network),
      );
    });

    test('a socket error is a network error', () async {
      final rig = Rig((_) async => throw const SocketException('unreachable'));
      await expectLater(
        rig.planner.start(brief),
        plannerError(PlannerErrorKind.network),
      );
    });

    test('a client exception is a network error', () async {
      final rig = Rig(
        (_) async => throw http.ClientException('connection reset'),
      );
      await expectLater(
        rig.planner.swap('p1', Weekday.mon, MealSlot.lunch),
        plannerError(PlannerErrorKind.network),
      );
    });
  });
}
