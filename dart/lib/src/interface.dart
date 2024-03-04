class PushPipe<T> {
  PushPipe([this.debugLabel]);

  final String? debugLabel; // TODO

  bool push(T t) {
    try {
      return _handler(t);
    } on Object {
      print(debugLabel ?? '');
      rethrow;
    }
  }

  late final PushHandler<T> _handler;

  void registerHandler(PushHandler<T> handler) => _handler = handler;
}

class PullPipe<T> {
  T pull() => _handler();
  late final PullHandler<T> _handler;

  void registerHandler(PullHandler<T> handler) => _handler = handler;
}

/// Pulling may not cause side effects. Implement a [_Pusher] to cause side effects.
abstract interface class Puller<T> {
  late final T Function() pull;
}

typedef PullHandler<T> = T Function();

abstract base class PullReceiver<T> {
  PullReceiver({required this.pullHandlerRegistrars}) {
    for (final handler in pullHandlerRegistrars) {
      handler(() => pullValue);
    }
  }

  final List<void Function(PullHandler<T>)> pullHandlerRegistrars;

  T get pullValue;
}

// Return value is whether simulation should end
typedef PushHandler<T> = bool Function(T);

/// A [Pusher] may cause side effects on the side of the [PushReceiver].
abstract class Pusher<T> {
  final List<PushHandler<T>> pushHandlers = [];
}

abstract interface class PushReceiver<T> {
  List<void Function(PushHandler)> get pushHandlerRegistrars;
}

void connectPull<T>(
    PullPipe<T> pipe, Puller<T> puller, PullReceiver<T> receiver) {
  puller.pull = pipe.pull;
  receiver.pullHandlerRegistrars.add(pipe.registerHandler);
}

void connectPush<T>(
    PushPipe<T> pipe, Pusher<T> pusher, PushReceiver<T> receiver,) {
  pusher.pushHandlers.add(pipe.push);
  receiver.pushHandlerRegistrars.add(pipe.registerHandler);
}
