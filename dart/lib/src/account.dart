import 'dollar.dart';

class Account {
  Account({
    required this.name,
    this.value = const Dollar.fromCents(0),
  });

  final String name;
  Dollar value;
}
