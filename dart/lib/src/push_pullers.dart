/// Library for implementations of [Pusher], [PushReceiver], [Puller], and
/// [PullReceiver].
library;

import 'common.dart';
import 'interface.dart';

final class Invest<T> extends Schedulable<T> implements Pusher<T> {
  Invest(
    super.ctx, {
    required this.interval,
    required this.amount,
    required this.pushHandlers,
  });

  final T amount;

  @override
  final List<PushHandler<T>> pushHandlers;

  @override
  bool tick() {
    return pushHandlers
        .map((handler) => handler(amount))
        .any((isDone) => isDone);
  }

  @override
  final SchedulerDuration interval;
}

final class Accumulator<T> extends PullReceiver<T>
    implements PushReceiver<T>, Pusher<T> {
  Accumulator({
    required this.pushHandlerRegistrars,
    required this.pushHandlers,
    required this.reducer,
    required T initialValue,
    required this.isDone,
    required super.pullHandlerRegistrars,
  }) : pullValue = initialValue {
    // TODO this must happen lazily, or in an explicit "initialize" step
    for (final register in pushHandlerRegistrars) {
      register((T cur) {
        pullValue = reducer(pullValue, cur);
        bool done1 = isDone(pullValue);
        // run pushHandlers whether or not we're done
        bool done2 = pushHandlers
            .map((handler) => handler(pullValue))
            .any((isDone) => isDone);
        return done1 || done2;
      });
    }
  }

  @override
  final List<void Function(PushHandler<T>)> pushHandlerRegistrars;

  @override
  final List<PushHandler<T>> pushHandlers;

  final T Function(T acc, T cur) reducer;

  @override
  T pullValue;

  final bool Function(T) isDone;
}

// TODO does this need to pull, or can it be a PushReceiver?
final class Plotter implements PushReceiver<int> {
  Plotter({
    required this.pushHandlerRegistrars,
    required this.label,
    required this.callback,
  }) {
    for (final register in pushHandlerRegistrars) {
      register(callback);
    }
  }

  final PushHandler<int> callback;

  @override
  final List<void Function(PushHandler<int>)> pushHandlerRegistrars;

  final String label;
}

final class Interest extends Schedulable implements Puller<int>, Pusher<int> {
  Interest(
    super.ctx, {
    required this.rate,
    required this.pushHandlers,
  });

  /// APY.
  final double rate;

  @override
  late final int Function() pull;

  @override
  final List<PushHandler<int>> pushHandlers;

  @override
  final SchedulerDuration interval = SchedulerDuration(months: 1);

  @override
  bool tick() {
    final total = pull();
    final currentRate = rate * interval.months / 12;
    final interest = (total.toDouble() * currentRate).floor();

    return pushHandlers
        .map((handler) => handler(interest))
        .any((isDone) => isDone);
  }
}
