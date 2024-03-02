final class Scheduler extends Component {
  Scheduler._(super.ctx);

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

class SchedulerDuration {
  const SchedulerDuration._(this.months);

  factory SchedulerDuration({
    int months = 0,
    int years = 0,
  }) =>
      SchedulerDuration._(years * 12 + months);

  final int months;
}

/// Sends a value to [out] once per [interval].
///
/// Registered to the context, from where the [Scheduler] will call [tick].
abstract base class Schedulable<T> extends Component {
  Schedulable(super.ctx) {
    ctx.tickables.add(this);
  }

  /// Returns whether or not the simulation should end.
  bool tick();

  // TODO should this instead be a bool callback?
  SchedulerDuration get interval;
}

// TODO should all components have an optional isDone?
abstract base class Component {
  Component(this.ctx);

  final Context ctx;
}

/// Global state.
final class Context {
  Context();

  late final Scheduler scheduler = Scheduler._(this);
  final tickables = <Schedulable>[];
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
