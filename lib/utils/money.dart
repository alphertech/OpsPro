class Money implements Comparable<Money> {
  final int cents;

  const Money._(this.cents);

  static const Money zero = Money._(0);

  factory Money.fromDouble(double amount) {
    return Money._((amount * 100).round());
  }

  factory Money.fromInt(int cents) {
    return Money._(cents);
  }

  static Money halfUp(double amount) {
    return Money.fromDouble(amount);
  }

  static Money parse(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty string');
    }
    final parts = trimmed.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid money format: $s');
    }
    final sign = trimmed.startsWith('-') ? -1 : 1;
    final whole = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
    int wholePart = int.tryParse(whole) ?? 0;
    String decimalPart = '0';
    if (parts.length == 2) {
      decimalPart = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
    }
    if (decimalPart.length == 1) {
      decimalPart = decimalPart.padRight(2, '0');
    } else if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }
    final decimalCents = int.tryParse(decimalPart) ?? 0;
    return Money._(sign * (wholePart * 100 + decimalCents));
  }

  double get asDouble => cents / 100.0;
  int get asCents => cents;

  Money operator +(Money other) => Money._(cents + other.cents);
  Money operator -(Money other) => Money._(cents - other.cents);
  Money operator -() => Money._(-cents);
  Money operator *(int multiplier) => Money._(cents * multiplier);
  Money operator /(int divisor) {
    if (divisor == 0) throw UnsupportedError('Division by zero');
    return Money._(cents ~/ divisor);
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  String toString() {
    final isNegative = cents < 0;
    final absCents = cents.abs();
    final major = absCents ~/ 100;
    final minor = absCents % 100;
    final sign = isNegative ? '-' : '';
    return '$sign$major.$minor';
  }

  String toFormattedString(String currencySymbol) {
    final isNegative = cents < 0;
    final absCents = cents.abs();
    final major = absCents ~/ 100;
    final minor = absCents % 100;
    final majorFormatted = major.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    final sign = isNegative ? '-' : '';
    return '$sign$currencySymbol $majorFormatted.$minor';
  }
}
