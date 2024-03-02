/// Pulling may not cause side effects. Implement a [_Pusher] to cause side effects.
interface class Puller<T> {
  Puller({required this.pull});

  final T Function() pull;
}

interface class PullReceiver<T> {
  PullReceiver({required this.registerPullHandlers});

  final List<void Function(T Function())> registerPullHandlers;
}
