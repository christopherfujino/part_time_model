void main(List<String> arguments) {
  final ctx = Context();
  final scheduler = Scheduler(ctx);
  final pipe1 = Pipe<int>();
  Generator<int>(
    ctx,
    amount: 2,
    out: pipe1,
    tickInterval: 3,
  );
  final pipe2 = Pipe<int>();
  Sum(pipe1, pipe2);
  Plotter<int>(
    ctx: ctx,
    input: pipe2,
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

final class Context {
  Context();

  late Scheduler scheduler;
  final tickables = <Tickable>[];
}

abstract base class Component {
  Component(this.ctx);

  final Context ctx;
}

final class Scheduler extends Component {
  Scheduler(super.ctx) {
    ctx.scheduler = this;
  }

  int ticks = 0;

  bool tick() {
    ticks += 1;
    bool isDone = false;
    for (final tickable in ctx.tickables) {
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

abstract base class Tickable extends Component {
  Tickable(super.ctx) {
    ctx.tickables.add(this);
  }

  bool tick();

  int get tickInterval;
}

final class Generator<T> extends Tickable {
  Generator(
    super.ctx, {
    required this.amount,
    required this.out,
    required this.tickInterval,
  });

  final T amount;

  final Out<T> out;

  @override
  bool tick() => out.send(amount);

  @override
  final int tickInterval;
}

class Sum {
  Sum(this.input, this.out) {
    input.listen((int t) {
      _x += t;
      return out.send(_x);
    });
  }

  int _x = 0;

  final In<int> input;

  final Out<int> out;
}

class Plotter<T> {
  Plotter({
    required this.ctx,
    required this.input,
    required this.isDone,
    required this.label,
  }) {
    input.listen((T t) {
      print('$label : (${ctx.scheduler.ticks}, $t)');
      return isDone(t);
    });
  }

  final In<T> input;

  final Context ctx;

  // TODO make this a conditional DSL
  // We can't interpret user-provided Dart at runtime
  final bool Function(T) isDone;

  final String label;
}

class Account<T> {
  Account(this.input, this.out);

  final In<T> input;

  final Out<T> out;
}

abstract class In<T> {
  void listen(bool Function(T) listener);
}

abstract class Out<T> {
  bool send(T t);
}

class Pipe<T> implements In<T>, Out<T> {
  late final bool Function(T) _listener;

  @override
  void listen(bool Function(T) listener) {
    _listener = listener;
  }

  @override
  bool send(T t) => _listener(t);
}
