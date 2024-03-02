/// Library for implementations of [Pusher], [PushReceiver], [Puller], and
/// [PullReceiver].
library;

import 'common.dart';
import 'pull.dart';
import 'push.dart';

final class Invest<T> extends Schedulable<T> implements Pusher<T> {
  Invest(
    super.ctx, {
    required this.interval,
    required this.amount,
    required this.pushers,
  });

  final T amount;

  @override
  final List<void Function(T t)> pushers;

  @override
  bool tick() {
    for (final pusher in pushers) {
      pusher(amount);
    }
    return false;
  }

  @override
  final SchedulerDuration interval;
}

final class Accumulator<T> extends PullReceiver<T> implements PushReceiver<T> {
  Accumulator({
    required this.registerPushHandlers,
    required super.registerPullHandlers,
    required this.reducer,
    required T initialValue,
  }) : pullValue = initialValue {
    for (final handler in registerPushHandlers) {
      handler((T cur) {
        pullValue = reducer(pullValue, cur);
      });
    }
  }

  final T Function(T acc, T cur) reducer;

  @override
  final List<void Function(void Function(T))> registerPushHandlers;

  @override
  T pullValue;
}

typedef PlotterCallback = void Function(
  int months,
  int years,
  int cents,
);

final class Plotter extends Schedulable implements Puller<int> {
  Plotter(
    super.ctx, {
    required this.pull,
    required this.isDone,
    required this.label,
    required this.interval,
    required this.callback,
  });

  final PlotterCallback callback;

  @override
  final int Function() pull;

  @override
  bool tick() {
    final int t = pull();
    final years = ctx.scheduler.months ~/ 12;
    final months = ctx.scheduler.months % 12;
    callback(months, years, t);
    return isDone(t);
  }

  @override
  final SchedulerDuration interval;

  // TODO make this a conditional DSL
  // We can't interpret user-provided Dart at runtime
  final bool Function(int) isDone;

  final String label;
}

final class Interest extends Schedulable implements Puller<int>, Pusher<int> {
  Interest(
    super.ctx, {
    required this.rate,
    required this.pull,
    required this.pushers,
  });

  /// APY.
  final double rate;

  @override
  final int Function() pull;

  @override
  final List<void Function(int t)> pushers;

  @override
  final SchedulerDuration interval = SchedulerDuration(months: 1);

  @override
  bool tick() {
    final total = pull();
    final currentRate = rate * interval.months / 12;
    final interest = (total.toDouble() * currentRate).floor();
    for (final pusher in pushers) {
      pusher(interest);
    }
    return false;
  }
}
