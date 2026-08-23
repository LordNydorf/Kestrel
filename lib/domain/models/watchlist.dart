import 'package:flutter/foundation.dart';

/// Immutable domain model representing a user watchlist.
@immutable
class Watchlist {
  final int id;
  final String name;
  final int position;
  final List<String> symbols;
  final DateTime createdAt;

  const Watchlist({
    required this.id,
    required this.name,
    required this.position,
    required this.symbols,
    required this.createdAt,
  });

  /// Stock count in this watchlist.
  int get stockCount => symbols.length;

  /// Whether this watchlist contains a given symbol.
  bool containsSymbol(String symbol) => symbols.contains(symbol);

  Watchlist copyWith({
    int? id,
    String? name,
    int? position,
    List<String>? symbols,
    DateTime? createdAt,
  }) {
    return Watchlist(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      symbols: symbols ?? this.symbols,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Watchlist &&
          other.id == id &&
          other.name == name &&
          other.position == position &&
          listEquals(other.symbols, symbols) &&
          other.createdAt == createdAt);

  @override
  int get hashCode =>
      Object.hash(id, name, position, Object.hashAll(symbols), createdAt);

  @override
  String toString() =>
      'Watchlist(id: $id, name: "$name", position: $position, symbols: $symbols)';
}
