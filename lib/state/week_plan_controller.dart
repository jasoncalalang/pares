import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mealpal_ph.dart';

/// Holds the week's plan for the This week screen and drives a [Planner]:
/// starts a plan, polls it until it is ready, and runs meal swaps.
///
/// One instance lives next to the PlanDraft for the whole flow. The screen
/// only reads its state and calls [build], [retry] and [swap].
class WeekPlanController extends ChangeNotifier {
  WeekPlanController(
    this._planner, {
    this.pollEvery = const Duration(seconds: 2),
    this.giveUpAfter = const Duration(minutes: 3),
    Future<void> Function(Duration)? wait,
  }) : _wait = wait ?? ((d) => Future<void>.delayed(d));

  /// Dropped polls in a row that a plan survives.
  static const int tolerableNetworkErrors = 3;

  final Planner _planner;
  final Duration pollEvery;
  final Duration giveUpAfter;
  final Future<void> Function(Duration) _wait;

  PlanBrief? _brief;
  PlanStatus _status = PlanStatus.building;
  List<DayPlan>? _week;
  String? _planId;
  String? _notice;
  String? _failure;
  (Weekday, MealSlot)? _swapping;

  /// Bumped by every new plan and by dispose. A loop that finds its number
  /// stale stops without touching state.
  int _generation = 0;
  bool _disposed = false;

  /// The brief the current plan was asked for, or null before the first
  /// [build].
  PlanBrief? get brief => _brief;

  PlanStatus get status => _status;

  /// Null while a first plan builds or after it failed.
  List<DayPlan>? get week => _week;

  /// A line to show above the meals: why a swap changed nothing or did not
  /// go through. Cleared by the next action.
  String? get notice => _notice;

  /// Copy for the failed card; set only while [status] is failed.
  String? get failure => _failure;

  /// The day and slot of the swap in flight, or null.
  (Weekday, MealSlot)? get swapping => _swapping;

  /// Plans [brief]. Does nothing when this brief is already building or
  /// ready; otherwise drops the old plan and starts a new one.
  void build(PlanBrief brief) {
    if (_disposed) return;
    if (_brief == brief &&
        (_status == PlanStatus.building || _status == PlanStatus.ready)) {
      return;
    }
    _begin(brief);
  }

  /// Starts the last brief again from scratch.
  void retry() {
    final brief = _brief;
    if (_disposed || brief == null) return;
    _begin(brief);
  }

  /// Asks the planner for a different meal in [slot] on [day]. Only when the
  /// plan is ready and no swap is running. The week stays on screen.
  void swap(Weekday day, MealSlot slot) {
    final id = _planId;
    if (_disposed ||
        _status != PlanStatus.ready ||
        _swapping != null ||
        id == null) {
      return;
    }
    _notice = null;
    _swapping = (day, slot);
    notifyListeners();
    unawaited(_runSwap(++_generation, id, day, slot));
  }

  void _begin(PlanBrief brief) {
    _brief = brief;
    _status = PlanStatus.building;
    _week = null;
    _planId = null;
    _notice = null;
    _failure = null;
    _swapping = null;
    notifyListeners();
    unawaited(_runBuild(++_generation, brief));
  }

  Future<void> _runBuild(int gen, PlanBrief brief) async {
    try {
      var snap = await _planner.start(brief);
      if (gen != _generation) return;
      _planId = snap.id;
      snap = await _poll(gen, snap);
      if (gen != _generation) return;
      if (snap.status == PlanStatus.ready && snap.week != null) {
        _status = PlanStatus.ready;
        _week = snap.week;
        _notice = snap.message;
      } else {
        _fail(snap.message ?? _unfinishedCopy);
      }
    } on PlannerException catch (e) {
      if (gen != _generation) return;
      _fail(_kindCopy(e));
    } on _GaveUp {
      if (gen != _generation) return;
      _fail('Your week was not ready after $_giveUpFor. Try again.');
    }
    notifyListeners();
  }

  Future<void> _runSwap(int gen, String id, Weekday day, MealSlot slot) async {
    try {
      var snap = await _planner.swap(id, day, slot);
      if (gen != _generation) return;
      snap = await _poll(gen, snap);
      if (gen != _generation) return;
      if (snap.status == PlanStatus.ready && snap.week != null) {
        _week = snap.week;
      }
      _notice = snap.message;
    } on PlannerException catch (e) {
      if (gen != _generation) return;
      _notice = _swapCopy(e);
    } on _GaveUp {
      if (gen != _generation) return;
      _notice =
          'The swap was not done after $_giveUpFor, so your week is '
          'unchanged. Try the swap again.';
    }
    _swapping = null;
    notifyListeners();
  }

  /// Follows [first] until it is no longer building. Returns the last
  /// snapshot, or throws; returns early (stale) when a newer plan took over.
  Future<PlanSnapshot> _poll(int gen, PlanSnapshot first) async {
    var snap = first;
    var waited = Duration.zero;
    var dropped = 0;
    while (snap.status == PlanStatus.building) {
      if (waited >= giveUpAfter) {
        throw const _GaveUp();
      }
      await _wait(pollEvery);
      waited += pollEvery;
      if (gen != _generation) return snap;
      try {
        snap = await _planner.fetch(snap.id);
        dropped = 0;
      } on PlannerException catch (e) {
        if (gen != _generation) return snap;
        if (e.kind != PlannerErrorKind.network ||
            ++dropped > tolerableNetworkErrors) {
          rethrow;
        }
      }
      if (gen != _generation) return snap;
    }
    return snap;
  }

  void _fail(String copy) {
    _status = PlanStatus.failed;
    _failure = copy;
    _week = null;
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  static const _unfinishedCopy =
      'The planner could not build your week. Try again.';

  String get _giveUpFor {
    final m = giveUpAfter.inMinutes;
    if (m < 1) return '${giveUpAfter.inSeconds} seconds';
    return '$m minute${m == 1 ? '' : 's'}';
  }

  String _swapCopy(PlannerException e) {
    if (e.kind == PlannerErrorKind.busy) {
      return 'The planner is still working on your week. Try the swap again '
          'in a moment.';
    }
    return 'Could not swap that meal, so your week is unchanged. '
        '${_kindCopy(e)}';
  }

  String _kindCopy(PlannerException e) {
    switch (e.kind) {
      case PlannerErrorKind.network:
        return 'Could not reach the planner. Check your connection and try '
            'again.';
      case PlannerErrorKind.rejected:
        final problems = e.problems.isEmpty ? '' : ' ${e.problems.join('; ')}.';
        return 'The planner could not use these choices.$problems '
            'Go back, change them and try again.';
      case PlannerErrorKind.unauthorized:
        return 'The planner did not accept this app. It may be out of date or '
            'set up wrong. Update the app and try again.';
      case PlannerErrorKind.notFound:
        return 'The planner lost track of this plan. Try again to build a '
            'new one.';
      case PlannerErrorKind.busy:
        return 'The planner is busy with this plan. Try again in a moment.';
      case PlannerErrorKind.unavailable:
        return 'The planner is not available right now. Try again in a '
            'minute.';
      case PlannerErrorKind.badResponse:
        return 'The planner sent an answer the app could not read. Try '
            'again.';
    }
  }
}

/// Polling ran past [WeekPlanController.giveUpAfter].
class _GaveUp implements Exception {
  const _GaveUp();
}
