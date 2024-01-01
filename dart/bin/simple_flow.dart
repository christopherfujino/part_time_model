void main(List<String> arguments) {
  final ctx = Context();
  final pipe1 = Pipe<int>();
  Generator<int>(
    amount: 2,
    out: pipe1,
    tickInterval: 3,
    ctx: ctx,
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
    try {
      ctx.scheduler.tick();
    } on Done {
      break;
    }
  }
  print('yay!');
}

final class Context {
  Context();

  final scheduler = Scheduler();
}

class Scheduler {
  Scheduler();

  int ticks = 0;

  final tickables = <Tickable>[];

  void tick() {
    ticks += 1;
    for (final tickable in tickables) {
      if (ticks % tickable.tickInterval == 0) {
        tickable.tick();
      }
    }
  }
}

abstract base class Tickable {
  Tickable({
    required this.ctx,
  }) {
    ctx.scheduler.tickables.add(this);
  }

  void tick();

  int get tickInterval;

  final Context ctx;
}

final class Generator<T> extends Tickable {
  Generator({
    required this.amount,
    required this.out,
    required this.tickInterval,
    required super.ctx,
  });

  final T amount;

  final Out<T> out;

  @override
  void tick() {
    out.send(amount);
  }

  @override
  final int tickInterval;
}

class Sum {
  Sum(this.input, this.out) {
    input.listen((int t) {
      _x += t;
      out.send(_x);
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
      if (isDone(t)) {
        throw const Done();
      }
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
  void listen(void Function(T) listener);
}

abstract class Out<T> {
  void send(T t);
}

class Pipe<T> implements In<T>, Out<T> {
  late final void Function(T) _listener;

  @override
  void listen(void Function(T) listener) {
    _listener = listener;
  }

  @override
  void send(T t) {
    _listener(t);
  }
}

class Done implements Exception {
  const Done();
}
