class Dollar {
  const Dollar.fromCents(this.cents);

  Dollar(num value) : cents = (value * 100).round();

  final int cents;
  double get value => cents.toDouble() / 100;

  operator +(Object other) => switch (other) {
        int other => Dollar.fromCents(cents + other * 100),
        double other => Dollar.fromCents(cents + (other * 100).round()),
        Dollar other => Dollar.fromCents(cents + other.cents),
        _ => throw StateError('cannot add $other to an instance of Dollar'),
      };

  operator -(Object other) => switch (other) {
        int other => Dollar.fromCents(cents - other * 100),
        double other => Dollar.fromCents(cents - (other * 100).round()),
        Dollar other => Dollar.fromCents(cents - other.cents),
        _ => throw StateError(
          'cannot subtract $other from an instance of Dollar',
        ),
      };

  operator *(Object other) => switch (other) {
        int other => Dollar.fromCents(cents * other),
        double other => Dollar.fromCents((cents * other).round()),
        _ => throw StateError(
          'cannot multiply $other by an instance of Dollar',
        ),
      };

  operator <(Object other) => switch (other) {
        int other => cents < other * 100,
        double other => cents < other * 100,
        Dollar other => cents < other.cents,
        _ => throw StateError(
          'cannot compare a Dollar to $other',
        ),
      };

  @override
  String toString() => '\$${(cents.toDouble() / 100.0).toStringAsFixed(2)}';
}
