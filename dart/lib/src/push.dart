/// A [Pusher] may cause side effects on the side of the [PushReceiver].
abstract class Pusher<T> {
  Pusher({required this.pushers});

  final List<void Function(T t)> pushers;
}

abstract interface class PushReceiver<T> {
  List<void Function(void Function(T))> get registerPushHandlers;
}
