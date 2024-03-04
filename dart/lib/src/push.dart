/// A [Pusher] may cause side effects on the side of the [PushReceiver].
abstract class Pusher<T> {
  Pusher({required this.pushHandlers});

  final List<PushHandler<T>> pushHandlers;
}

// Return value is whether simulation should end
typedef PushHandler<T> = bool Function(T);

abstract interface class PushReceiver<T> {
  List<void Function(PushHandler)> get pushHandlerRegistrars;
}
