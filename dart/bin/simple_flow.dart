void main(List<String> arguments) {
  final ctx = Context();
  final scheduler = Scheduler(ctx);
  final pipe1 = Pipe<int>();
  Invest(
    ctx,
    tickInterval: 1,
    out: pipe1.push,
    amount: 24,
  );
  final pipe2 = Pipe<int>();
  Accumulator(pipe1.registerPushReceiver, pipe2.push);
  Plotter<int>(
    ctx: ctx,
    input: pipe2.registerPushReceiver,
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
  final providers = <Provider>[];
}

abstract base class Component {
  Component(this.ctx);

  final Context ctx;
}

final class Scheduler extends Component {
  Scheduler(super.ctx);

  int ticks = 0;

  bool tick() {
    ticks += 1;
    bool isDone = false;
    for (final tickable in ctx.providers) {
      if (ticks % tickable.tickInterval == 0) {
        if (tickable.tick()) {
          // run all on this tick
          isDone = true;
        }
      }
    }
    return isDone;
  }
}

abstract base class Provider<T> extends Component {
  Provider(
    super.ctx, {
    required this.out,
  }) {
    ctx.providers.add(this);
  }

  bool tick();

  int get tickInterval;

  final Pusher<T> out;
}

abstract base class Join<T> {
  Join(this.input, this.out) {
    input(_listener);
  }

  bool _listener(T t);

  final PushReceiver<T> input;

  final Pusher<T> out;
}

abstract base class Consumer<T> {
  Consumer({required this.input, required this.ctx}) {
    input(_consume);
  }

  bool _consume(T t);

  final PushReceiver<T> input;

  final Context ctx;
}

final class Invest<T> extends Provider<T> {
  Invest(
    super.ctx, {
    required this.tickInterval,
    required this.amount,
    required super.out,
  });

  final T amount;

  @override
  bool tick() => out(amount);

  @override
  final int tickInterval;
}

final class Accumulator<T> extends Join<int> {
  Accumulator(super.input, super.out);

  int _x = 0;

  @override
  bool _listener(int t) {
    _x += t;
    return out(_x);
  }
}

final class Plotter<T> extends Consumer<T> {
  Plotter({
    required super.ctx,
    required super.input,
    required this.isDone,
    required this.label,
  });

  @override
  bool _consume(T t) {
    print('$label : (${ctx.scheduler.ticks}, $t)');
    return isDone(t);
  }

  // TODO make this a conditional DSL
  // We can't interpret user-provided Dart at runtime
  final bool Function(T) isDone;

  final String label;
}

class Account<T> {
  Account(this.input, this.out);

  final PushReceiver input;

  final Pusher<T> out;
}

typedef PushReceiver<T> = void Function(bool Function(T));
typedef Pusher<T> = bool Function(T);

class Pipe<T> {
  late final bool Function(T) _receiver;

  void registerPushReceiver(bool Function(T) receiver) {
    _receiver = receiver;
  }

  bool push(T t) => _receiver(t);
}
