/// Pulling may not cause side effects. Implement a [_Pusher] to cause side effects.
interface class Puller<T> {
  Puller({required this.pull});

  final T Function() pull;
}

abstract base class PullReceiver<T> {
  PullReceiver({required this.registerPullHandlers}) {
    for (final handler in registerPullHandlers) {
      handler(() => pullValue);
    }
  }

  final List<void Function(T Function())> registerPullHandlers;

  T get pullValue;
}
