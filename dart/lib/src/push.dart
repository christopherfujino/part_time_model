/// A [Pusher] may cause side effects on the side of the [PushReceiver].
abstract class Pusher<T> {
  Pusher({required this.pushers});

  final List<void Function(T t)> pushers;
}

abstract class PushReceiver<T> {
  PushReceiver({required this.registerPushHandlers});

  final List<void Function(void Function(T))> registerPushHandlers;
}
