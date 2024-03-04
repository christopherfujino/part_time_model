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
