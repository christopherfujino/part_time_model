import 'dart:collection';

import 'action.dart';

class Scheduler {
  Scheduler({
    SchedulerDate? startTime,
    required this.duration,
    required Iterable<Action> actions,
  }) : startTime = startTime ?? SchedulerDate.now() {
    currentTime = this.startTime;
    for (final action in actions) {
      schedule(action, currentTime);
    }
  }

  final SchedulerDate startTime;
  late final SchedulerDate endTime = startTime.add(duration);
  final SchedulerDuration duration;
  late SchedulerDate currentTime;

  final SplayTreeMap<SchedulerDate, Queue<Action>> workQueue =
      SplayTreeMap<SchedulerDate, Queue<Action>>();

  void schedule(Action action, [SchedulerDate? nextRun]) {
    nextRun ??= currentTime;

    final actions = workQueue[nextRun] ?? Queue<Action>();
    actions.addLast(action);

    //print('scheduling a new run of ${action.name} at $nextRun');
    workQueue[nextRun] = actions;
  }

  /// Will return [false] when queue is exhausted.
  bool runNext() {
    final SchedulerDate? firstKey = workQueue.firstKey();
    if (firstKey == null) {
      // work queue is empty
      return false;
    }
    // TODO what if is equal to?
    if (firstKey > endTime) {
      // We reached the end of the simulation
      return false;
    }
    currentTime = firstKey;
    final actions = workQueue[firstKey]!;
    final action = actions.removeFirst();
    action.run(this, null);
    if (actions.isEmpty) {
      workQueue.remove(firstKey);
      final SchedulerDate? nextKey = workQueue.firstKey();
      if (nextKey == null || nextKey > endTime) {
        return false;
      }
    }
    return true;
  }
}

class SchedulerDate implements Comparable<SchedulerDate> {
  SchedulerDate(this.month, this.year);

  SchedulerDate.fromDateTime(DateTime input)
      : month = input.month - 1,
        year = input.year;

  factory SchedulerDate.now() => SchedulerDate.fromDateTime(DateTime.now());

  final int year;

  /// [0..11].
  final int month;

  SchedulerDate add(SchedulerDuration duration) {
    switch (duration.unit) {
      case SchedulerUnit.month:
        int newMonth = month + duration.count;
        int newYear = year;
        while (newMonth > 11) {
          newMonth = newMonth - 12;
          newYear += 1;
        }
        return SchedulerDate(newMonth, newYear);
      case SchedulerUnit.year:
        return SchedulerDate(month, year + duration.count);
    }
  }

  @override
  int compareTo(SchedulerDate other) {
    if (other.year > year) {
      return -1;
    }
    if (other.year < year) {
      return 1;
    }
    if (other.month > month) {
      return -1;
    }
    if (other.month < month) {
      return 1;
    }
    return 0;
  }

  operator >(SchedulerDate other) {
    if (year > other.year) {
      return true;
    }
    if (year < other.year) {
      return false;
    }
    return month > other.month;
  }
}

class SchedulerDuration {
  const SchedulerDuration(this.unit, this.count);

  final SchedulerUnit unit;
  final int count;
}

enum SchedulerUnit {
  month,
  year,
}


