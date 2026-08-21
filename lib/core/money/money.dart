import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Immutable value object representing monetary amounts in Indian Rupees (INR),
/// backed internally by integer paise (1 Rupee = 100 Paise).
///
/// This eliminates floating-point representation and precision issues in
/// price × quantity math, portfolio values, and order validations.
@immutable
class Money implements Comparable<Money> {
  final int _paise;

  const Money._(this._paise);

  /// Creates a [Money] instance from an integer number of paise.
  const Money.fromPaise(int paise) : _paise = paise;

  /// Creates a [Money] instance from a rupee amount (num: int or double),
  /// rounding deterministically to the nearest paisa.
  factory Money.fromRupees(num rupees) {
    return Money.fromPaise((rupees * 100).round());
  }

  /// Zero Rupees instance.
  static const Money zero = Money._(0);

  /// Raw integer paise.
  int get paise => _paise;

  /// Converts to rupee decimal value as double (for display calculations if needed).
  double get inRupees => _paise / 100.0;

  /// Convenience getters for sign checks
  bool get isZero => _paise == 0;
  bool get isPositive => _paise > 0;
  bool get isNegative => _paise < 0;

  /// Returns the absolute value.
  Money abs() => Money._(_paise.abs());

  // --- Arithmetic operators ---

  Money operator +(Money other) => Money._(_paise + other._paise);

  Money operator -(Money other) => Money._(_paise - other._paise);

  Money operator *(num factor) => Money._((_paise * factor).round());

  Money operator /(num divisor) {
    if (divisor == 0) {
      throw ArgumentError('Division by zero is not allowed.');
    }
    return Money._((_paise / divisor).round());
  }

  Money operator -() => Money._(-_paise);

  // --- Comparison operators ---

  bool operator <(Money other) => _paise < other._paise;
  bool operator <=(Money other) => _paise <= other._paise;
  bool operator >(Money other) => _paise > other._paise;
  bool operator >=(Money other) => _paise >= other._paise;

  @override
  int compareTo(Money other) => _paise.compareTo(other._paise);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other._paise == _paise);

  @override
  int get hashCode => _paise.hashCode;

  /// Formats the money into Indian numbering format, e.g. `₹2,950.00` or `-₹120.50`.
  ///
  /// [showSymbol] defaults to true (prepends `₹`).
  /// [explicitSign] prepends `+` for positive amounts when true.
  String format({bool showSymbol = true, bool explicitSign = false}) {
    final absRupees = _paise.abs() / 100.0;
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    final formattedNumber = formatter.format(absRupees);

    final symbol = showSymbol ? '₹' : '';

    if (_paise < 0) {
      return '-$symbol$formattedNumber';
    } else if (_paise > 0 && explicitSign) {
      return '+$symbol$formattedNumber';
    } else {
      return '$symbol$formattedNumber';
    }
  }

  @override
  String toString() => format();
}
