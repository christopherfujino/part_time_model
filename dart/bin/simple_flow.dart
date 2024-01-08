void main(List<String> arguments) {
  final ctx = Context();
  final scheduler = Scheduler(ctx);
  final pipe1 = PushPipe<int>();
  Invest(
    ctx,
    interval: const SchedulerDuration._(1),
    push: pipe1.push,
    amount: 24,
  );
  final pipe2 = PullPipe<int>();
  Accumulator(
    registerPushHandler: pipe1.registerPushHandler,
    registerPullHandler: pipe2.registerPullHandler,
  );
  Plotter(
    ctx,
    pull: pipe2.pull,
    isDone: (int x) => x >= 100,
    label: 'foo',
  );
  while (true) {
    if (scheduler.tick()) {
      break;
    }
  }
  print('yay!');
}

/// Global state.
final class Context {
  Context();

  late final Scheduler scheduler = Scheduler(this);
  final tickables = <Tickable>[];
}

abstract base class Component {
  Component(this.ctx);

  final Context ctx;
}

final class Scheduler extends Component {
  Scheduler(super.ctx);

  int months = 0;

  bool tick() {
    months += 1;
    bool isDone = false;
    for (final tickable in ctx.tickables) {
      if (months % tickable.interval.months == 0) {
        if (tickable.tick()) {
          // run all on this tick
          isDone = true;
        }
      }
    }
    return isDone;
  }
}

/// A [_Pusher] may cause side effects on the side of the [_PushReceiver].
abstract class _Pusher<T> {
  _Pusher({required this.push});

  final void Function(T t) push;
}

abstract class _PushReceiver<T> {
  _PushReceiver({required this.registerPushHandler});

  final void Function(void Function(T)) registerPushHandler;
}

/// Pulling should not cause side effects. Implement a [_Pusher] to cause side effects.
abstract class _Puller<T> {
  _Puller({required this.pull});

  final T Function() pull;
}


abstract class _PullReceiver<T> {
  _PullReceiver({required this.registerPullHandler});

  final void Function(T Function()) registerPullHandler;
}

/// Sends a value to [out] once per [interval].
///
/// Registered to the context, from where the [Scheduler] will call [tick].
abstract base class Tickable<T> extends Component {
  Tickable(super.ctx) {
    ctx.tickables.add(this);
  }

  /// Returns whether or not the simulation should end.
  bool tick();

  // TODO should this instead be a bool callback?
  SchedulerDuration get interval;
}

final class Invest<T> extends Tickable<T> implements _Pusher<T> {
  Invest(
    super.ctx, {
    required this.interval,
    required this.amount,
    required this.push,
  });

  final T amount;

  @override
  final void Function(T t) push;

  @override
  bool tick() {
    push(amount);
    return false;
  }

  @override
  final SchedulerDuration interval;
}

final class Accumulator implements _PushReceiver<int>, _PullReceiver<int> {
  Accumulator({
    required this.registerPushHandler,
    required this.registerPullHandler,
  }) {
    registerPushHandler((int t) {
      _x += t;
    });
    registerPullHandler(() => _x);
  }

  @override
  final void Function(int Function()) registerPullHandler;

  @override
  final void Function(void Function(int)) registerPushHandler;

  int _x = 0;
}

final class Plotter extends Tickable implements _Puller<int> {
  Plotter(
    super.ctx, {
    required this.pull,
    required this.isDone,
    required this.label,
  });

  @override
  final int Function() pull;

  @override
  bool tick() {
    final int t = pull();
    print('$label : (${ctx.scheduler.months}, $t)');
    return isDone(t);
  }

  @override
  final SchedulerDuration interval = const SchedulerDuration._(1);

  // TODO make this a conditional DSL
  // We can't interpret user-provided Dart at runtime
  final bool Function(int) isDone;

  final String label;
}

class PullPipe<T> {
  late final T Function() _handler;

  void registerPullHandler(T Function() handler) {
    _handler = handler;
  }

  T pull() => _handler();
}

class PushPipe<T> {
  late final void Function(T) _receiver;

  void registerPushHandler(void Function(T) receiver) {
    _receiver = receiver;
  }

  void push(T t) => _receiver(t);
}

class SchedulerDuration {
  const SchedulerDuration._(this.months);

  factory SchedulerDuration({
    int months = 0,
    int years = 0,
  }) =>
      SchedulerDuration._(years * 12 + months);

  final int months;
}
