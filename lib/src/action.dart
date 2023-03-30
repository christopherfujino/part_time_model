import 'package:meta/meta.dart';

import 'account.dart';
import 'dollar.dart';
import 'scheduler.dart';

/// The [I] type is input, the [O] is output.
sealed class Action<I, O> {
  const Action({
    required this.name,
    this.postActions,
  });

  final String name;

  final List<DependentAction<O, dynamic>>? postActions;

  /// Execute action plus any registered hooks.
  @mustCallSuper
  void run(Scheduler scheduler, I input) {
    final O output = _execute(scheduler, input);
    if (postActions != null) {
      for (final action in postActions!) {
        action.run(scheduler, output);
      }
    }
  }

  /// Execute the action.
  O _execute(Scheduler scheduler, I input);
}

sealed class DependentAction<I, O> extends Action<I, O> {
  const DependentAction({
    required super.name,
    super.postActions,
  });

  @override
  O _execute(Scheduler scheduler, I input);
}

final class TransferAction extends DependentAction<Dollar, void> {
  const TransferAction({
    required super.name,
    required this.source,
    required this.target,
    this.rate = 1.0,
    super.postActions,
  });

  final Account source;
  final Account target;

  /// Fraction of total input value passed to [run] to be invested.
  final double rate;

  @override
  void _execute(Scheduler scheduler, Dollar input) {
    final amount = input * rate;
    source.value -= amount;
    if (source.value < 0) {
      throw StateError(
          'Account ${source.name} is overdrawn with balance ${source.value}');
    }
    target.value += amount;
  }
}

final class IncomeAction extends Action<void, Dollar> {
  IncomeAction({
    required super.name,
    required this.account,
    required this.salary,
    this.interval = const SchedulerDuration(SchedulerUnit.month, 1),
    super.postActions,
  });

  Dollar salary;
  final Account account;
  final SchedulerDuration interval;

  @override
  Dollar _execute(Scheduler scheduler, void input) {
    final salaryValue = Dollar(
      splitAnnualValueByInterval(salary.value, interval),
    );
    account.value += salaryValue;
    scheduler.schedule(this, scheduler.currentTime.add(interval));
    return salaryValue;
  }
}

final class InterestAction extends Action<void, Dollar> {
  InterestAction({
    required this.apy,
    required this.interval,
    required this.source,
    Account? target,
    super.postActions,
  })  : target = target ?? source,
        super(name: '$apy% interest');

  final double apy;
  final SchedulerDuration interval;
  final Account source;
  final Account target;

  @override
  Dollar _execute(Scheduler scheduler, void input) {
    final amount = source.value * splitAnnualValueByInterval(apy, interval);
    target.value += amount;
    scheduler.schedule(this, scheduler.currentTime.add(interval));
    return amount;
  }
}

double splitAnnualValueByInterval(double rate, SchedulerDuration interval) {
  return switch (interval.unit) {
    SchedulerUnit.year => rate * interval.count,
    SchedulerUnit.month => rate / 12 * interval.count,
  };
}
