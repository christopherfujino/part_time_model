void main(List<String> arguments) {
  final ctx = Context();
  final pipe1 = PushPipe<int>();
  final pushToInvestmentCapitalAccumulator = PushPipe<int>();
  Invest(
    ctx,
    interval: const SchedulerDuration._(1),
    pushers: [
      pipe1.push,
      pushToInvestmentCapitalAccumulator.push,
    ],
    amount: 100 * 100, // $100
  );
  // Plot from Investment Account
  final plotPullFromInvestment = PullPipe<int>();
  final plotPullFromInvestmentCapital = PullPipe<int>();
  // Interest from Investment Account
  final pipe3 = PullPipe<int>();
  // Interest to Investment Account
  final pipe4 = PushPipe<int>();

  // Investment account
  Accumulator(
    registerPushHandlers: [
      pipe1.registerPushHandler,
      pipe4.registerPushHandler,
    ],
    registerPullHandlers: [
      plotPullFromInvestment.registerPullHandler,
      pipe3.registerPullHandler,
    ],
  );

  // Sum of investment capital
  Accumulator(
    registerPushHandlers: [
      pushToInvestmentCapitalAccumulator.registerPushHandler
    ],
    registerPullHandlers: [plotPullFromInvestmentCapital.registerPullHandler],
  );

  // Interest
  Interest(
    ctx,
    rate: 0.1,
    pull: pipe3.pull,
    pushers: [pipe4.push],
  );
  Plotter(
    ctx,
    pull: plotPullFromInvestment.pull,
    isDone: (int x) => x >= 1000000 * 100, // $1M
    label: 'Investment balance',
    interval: SchedulerDuration._(12),
  );
  Plotter(
    ctx,
    pull: plotPullFromInvestmentCapital.pull,
    isDone: (int _) => false,
    label: 'Investment capital',
    interval: SchedulerDuration._(12),
  );
  while (true) {
    if (ctx.scheduler.tick()) {
      break;
    }
  }
  print('<END>');
}

/// Global state.
final class Context {
  Context();

  late final Scheduler scheduler = Scheduler(this);
  final tickables = <Tickable>[];
}

// TODO should all components have an optional isDone?
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
    //print('tickables = ${ctx.tickables}');
    // TODO do we need to be able to ensure the order of these?
    // TODO can we order by dependencies?
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
  _Pusher({required this.pushers});

  final List<void Function(T t)> pushers;
}

abstract class _PushReceiver<T> {
  _PushReceiver({required this.registerPushHandlers});

  final List<void Function(void Function(T))> registerPushHandlers;
}

/// Pulling should not cause side effects. Implement a [_Pusher] to cause side effects.
abstract class _Puller<T> {
  _Puller({required this.pull});

  final T Function() pull;
}

abstract class _PullReceiver<T> {
  _PullReceiver({required this.registerPullHandlers});

  final List<void Function(T Function())> registerPullHandlers;
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

final class Interest extends Tickable implements _Puller<int>, _Pusher<int> {
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
  final SchedulerDuration interval = SchedulerDuration._(1);

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

final class Accumulator implements _PushReceiver<int>, _PullReceiver<int> {
  Accumulator({
    required this.registerPushHandlers,
    required this.registerPullHandlers,
  }) {
    for (final handler in registerPushHandlers) {
      handler((int t) => _x += t);
    }
    for (final handler in registerPullHandlers) {
      handler(() => _x);
    }
  }

  @override
  final List<void Function(int Function())> registerPullHandlers;

  @override
  final List<void Function(void Function(int))> registerPushHandlers;

  int _x = 0;
}

final class Plotter extends Tickable implements _Puller<int> {
  Plotter(
    super.ctx, {
    required this.pull,
    required this.isDone,
    required this.label,
    required this.interval,
  });

  @override
  final int Function() pull;

  @override
  bool tick() {
    final int t = pull();
    final years = ctx.scheduler.months ~/ 12;
    final months = ctx.scheduler.months % 12;
    print('$label : (${years}Y ${months}M, \$${t / 100})');
    return isDone(t);
  }

  @override
  final SchedulerDuration interval;

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
