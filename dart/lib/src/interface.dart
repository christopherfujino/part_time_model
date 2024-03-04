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

/// Pulling may not cause side effects. Implement a [_Pusher] to cause side effects.
abstract interface class Puller<T> {
  Puller({required this.pull});

  final T Function() pull;
}

typedef PullHandler<T> = T Function();

abstract base class PullReceiver<T> {
  PullReceiver({required this.registerPullHandlers}) {
    for (final handler in registerPullHandlers) {
      handler(() => pullValue);
    }
  }

  final List<void Function(PullHandler<T>)> registerPullHandlers;

  T get pullValue;
}

// Return value is whether simulation should end
typedef PushHandler<T> = bool Function(T);

/// A [Pusher] may cause side effects on the side of the [PushReceiver].
abstract class Pusher<T> {
  Pusher({required this.pushHandlers});

  final List<PushHandler<T>> pushHandlers;
}

abstract interface class PushReceiver<T> {
  List<void Function(PushHandler)> get pushHandlerRegistrars;
}
