import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/watchlist.dart';
import '../db/app_database.dart';

/// Repository managing Watchlists and their stock memberships in SQLite.
class WatchlistRepository {
  final AppDatabase _appDatabase;
  final StreamController<List<Watchlist>> _watchlistsController =
      StreamController<List<Watchlist>>.broadcast();

  WatchlistRepository(this._appDatabase);

  /// Reactive stream of all watchlists, emitting updates whenever changes occur.
  Stream<List<Watchlist>> watchWatchlists() async* {
    yield await getWatchlists();
    yield* _watchlistsController.stream;
  }

  /// Notify all active stream listeners of updated watchlists.
  Future<void> _notifyChanges() async {
    if (_watchlistsController.hasListener) {
      final updated = await getWatchlists();
      _watchlistsController.add(updated);
    }
  }

  /// Get all watchlists in custom position order.
  Future<List<Watchlist>> getWatchlists() async {
    final db = await _appDatabase.database;

    final watchlistRows = await db.query(
      'watchlists',
      orderBy: 'position ASC, created_at ASC',
    );

    final List<Watchlist> watchlists = [];

    for (final row in watchlistRows) {
      final id = row['id'] as int;
      final name = row['name'] as String;
      final position = row['position'] as int;
      final createdAtMs = row['created_at'] as int;

      // Query stocks for this watchlist
      final stockRows = await db.query(
        'watchlist_stocks',
        columns: ['symbol'],
        where: 'watchlist_id = ?',
        whereArgs: [id],
        orderBy: 'position ASC',
      );

      final symbols = stockRows.map((r) => r['symbol'] as String).toList();

      watchlists.add(
        Watchlist(
          id: id,
          name: name,
          position: position,
          symbols: symbols,
          createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        ),
      );
    }

    return watchlists;
  }

  /// Get a single watchlist by ID.
  Future<Watchlist?> getWatchlistById(int id) async {
    final db = await _appDatabase.database;

    final watchlistRows = await db.query(
      'watchlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (watchlistRows.isEmpty) return null;

    final row = watchlistRows.first;
    final name = row['name'] as String;
    final position = row['position'] as int;
    final createdAtMs = row['created_at'] as int;

    final stockRows = await db.query(
      'watchlist_stocks',
      columns: ['symbol'],
      where: 'watchlist_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );

    final symbols = stockRows.map((r) => r['symbol'] as String).toList();

    return Watchlist(
      id: id,
      name: name,
      position: position,
      symbols: symbols,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }

  /// Create a new watchlist.
  Future<Watchlist> createWatchlist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Watchlist name cannot be empty.');
    }

    final db = await _appDatabase.database;

    // Determine next position
    final maxPosResult = await db.rawQuery(
      'SELECT MAX(position) as max_pos FROM watchlists',
    );
    final maxPos = (maxPosResult.first['max_pos'] as int?) ?? -1;
    final nextPos = maxPos + 1;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final id = await db.insert('watchlists', {
      'name': trimmedName,
      'position': nextPos,
      'created_at': nowMs,
    });

    final created = Watchlist(
      id: id,
      name: trimmedName,
      position: nextPos,
      symbols: const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
    );

    await _notifyChanges();
    return created;
  }

  /// Rename an existing watchlist.
  Future<void> renameWatchlist(int id, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Watchlist name cannot be empty.');
    }

    final db = await _appDatabase.database;
    await db.update(
      'watchlists',
      {'name': trimmedName},
      where: 'id = ?',
      whereArgs: [id],
    );

    await _notifyChanges();
  }

  /// Delete a watchlist (cascade deletes associated stocks).
  Future<void> deleteWatchlist(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      'watchlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    await _notifyChanges();
  }

  /// Add a stock to a watchlist.
  Future<void> addStock(int watchlistId, String symbol) async {
    final db = await _appDatabase.database;

    // Check if already present
    final existing = await db.query(
      'watchlist_stocks',
      where: 'watchlist_id = ? AND symbol = ?',
      whereArgs: [watchlistId, symbol],
    );

    if (existing.isNotEmpty) return; // Already present, idempotent

    // Determine next position for this watchlist
    final maxPosResult = await db.rawQuery(
      'SELECT MAX(position) as max_pos FROM watchlist_stocks WHERE watchlist_id = ?',
      [watchlistId],
    );
    final maxPos = (maxPosResult.first['max_pos'] as int?) ?? -1;
    final nextPos = maxPos + 1;

    await db.insert('watchlist_stocks', {
      'watchlist_id': watchlistId,
      'symbol': symbol,
      'position': nextPos,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _notifyChanges();
  }

  /// Remove a stock from a watchlist.
  Future<void> removeStock(int watchlistId, String symbol) async {
    final db = await _appDatabase.database;
    await db.delete(
      'watchlist_stocks',
      where: 'watchlist_id = ? AND symbol = ?',
      whereArgs: [watchlistId, symbol],
    );

    await _notifyChanges();
  }

  /// Reorder stocks within a watchlist using a single atomic transaction.
  Future<void> reorderStocks(
    int watchlistId,
    List<String> orderedSymbols,
  ) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (int i = 0; i < orderedSymbols.length; i++) {
        batch.update(
          'watchlist_stocks',
          {'position': i},
          where: 'watchlist_id = ? AND symbol = ?',
          whereArgs: [watchlistId, orderedSymbols[i]],
        );
      }
      await batch.commit(noResult: true);
    });

    await _notifyChanges();
  }

  /// Reorder multiple watchlists.
  Future<void> reorderWatchlists(List<int> orderedIds) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          'watchlists',
          {'position': i},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
      await batch.commit(noResult: true);
    });

    await _notifyChanges();
  }

  /// Close resources.
  void dispose() {
    _watchlistsController.close();
  }
}
