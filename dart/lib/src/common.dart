import 'pull.dart' show PullHandler;
import 'push.dart' show PushHandler;

const int maxMonths = 1000 * 12;
//const int maxMonths = 12;

final class Scheduler extends Component {
  Scheduler._(super.ctx);

  int months = 0;

  bool tick() {
    months += 1;
    if (months >= maxMonths) {
      throw Exception('Reached $maxMonths months!');
    }
    bool isDone = false;
    //print('tickables = ${ctx.tickables}');
    // TODO do we need to be able to ensure the order of these?
    // TODO can we order by dependencies?
    for (final tickable in ctx.schedulables) {
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
    ctx.schedulables.add(this);
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
  final schedulables = <Schedulable>[];
}

class PushPipe<T> {
  bool push(T t) => _handler(t);
  late final PushHandler<T> _handler;

  void registerHandler(PushHandler<T> handler) => _handler = handler;
}

class PullPipe<T> {
  T pull() => _handler();
  late final PullHandler<T> _handler;

  void registerHandler(PullHandler<T> handler) => _handler = handler;
}
