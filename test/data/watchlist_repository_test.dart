import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/domain/models/watchlist.dart';
import 'package:kestrel/data/repositories/watchlist_repository.dart';

/// In-memory Fake implementation of WatchlistRepository for pure Dart unit testing.
class FakeWatchlistRepository implements WatchlistRepository {
  final List<Watchlist> _watchlists = [];
  final StreamController<List<Watchlist>> _controller =
      StreamController<List<Watchlist>>.broadcast();
  int _nextId = 1;

  @override
  Stream<List<Watchlist>> watchWatchlists() async* {
    yield List.unmodifiable(_watchlists);
    yield* _controller.stream;
  }

  @override
  Future<List<Watchlist>> getWatchlists() async =>
      List.unmodifiable(_watchlists);

  @override
  Future<Watchlist?> getWatchlistById(int id) async {
    try {
      return _watchlists.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Watchlist> createWatchlist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Watchlist name cannot be empty.');
    }
    final wl = Watchlist(
      id: _nextId++,
      name: trimmed,
      position: _watchlists.length,
      symbols: const [],
      createdAt: DateTime.now(),
    );
    _watchlists.add(wl);
    _controller.add(List.unmodifiable(_watchlists));
    return wl;
  }

  @override
  Future<void> renameWatchlist(int id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Watchlist name cannot be empty.');
    }
    final index = _watchlists.indexWhere((w) => w.id == id);
    if (index != -1) {
      _watchlists[index] = _watchlists[index].copyWith(name: trimmed);
      _controller.add(List.unmodifiable(_watchlists));
    }
  }

  @override
  Future<void> deleteWatchlist(int id) async {
    _watchlists.removeWhere((w) => w.id == id);
    _controller.add(List.unmodifiable(_watchlists));
  }

  @override
  Future<void> addStock(int watchlistId, String symbol) async {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final current = _watchlists[index];
      if (!current.symbols.contains(symbol)) {
        _watchlists[index] =
            current.copyWith(symbols: [...current.symbols, symbol]);
        _controller.add(List.unmodifiable(_watchlists));
      }
    }
  }

  @override
  Future<void> removeStock(int watchlistId, String symbol) async {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final current = _watchlists[index];
      _watchlists[index] = current.copyWith(
        symbols: current.symbols.where((s) => s != symbol).toList(),
      );
      _controller.add(List.unmodifiable(_watchlists));
    }
  }

  @override
  Future<void> reorderStocks(
    int watchlistId,
    List<String> orderedSymbols,
  ) async {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      _watchlists[index] = _watchlists[index].copyWith(symbols: orderedSymbols);
      _controller.add(List.unmodifiable(_watchlists));
    }
  }

  @override
  Future<void> reorderWatchlists(List<int> orderedIds) async {
    final Map<int, Watchlist> map = {for (var w in _watchlists) w.id: w};
    _watchlists.clear();
    for (int i = 0; i < orderedIds.length; i++) {
      final wl = map[orderedIds[i]];
      if (wl != null) {
        _watchlists.add(wl.copyWith(position: i));
      }
    }
    _controller.add(List.unmodifiable(_watchlists));
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('WatchlistRepository Contract Unit Tests', () {
    late FakeWatchlistRepository repository;

    setUp(() {
      repository = FakeWatchlistRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('Initial watchlists list is empty', () async {
      final watchlists = await repository.getWatchlists();
      expect(watchlists, isEmpty);
    });

    test('Create watchlist assigns incremental position and persists', () async {
      final wl1 = await repository.createWatchlist('Tech & IT');
      final wl2 = await repository.createWatchlist('Banking');

      expect(wl1.name, 'Tech & IT');
      expect(wl1.position, 0);
      expect(wl1.symbols, isEmpty);

      expect(wl2.name, 'Banking');
      expect(wl2.position, 1);

      final all = await repository.getWatchlists();
      expect(all.length, 2);
      expect(all[0].name, 'Tech & IT');
      expect(all[1].name, 'Banking');
    });

    test('Rename watchlist updates name successfully', () async {
      final wl = await repository.createWatchlist('Original Name');
      await repository.renameWatchlist(wl.id, 'Updated Name');

      final fetched = await repository.getWatchlistById(wl.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Updated Name');
    });

    test('Add and remove stocks from watchlist', () async {
      final wl = await repository.createWatchlist('Core Holdings');

      await repository.addStock(wl.id, 'RELIANCE');
      await repository.addStock(wl.id, 'TCS');
      await repository.addStock(wl.id, 'INFY');

      var fetched = await repository.getWatchlistById(wl.id);
      expect(fetched!.symbols, ['RELIANCE', 'TCS', 'INFY']);
      expect(fetched.stockCount, 3);
      expect(fetched.containsSymbol('TCS'), isTrue);
      expect(fetched.containsSymbol('SBIN'), isFalse);

      // Remove stock
      await repository.removeStock(wl.id, 'TCS');
      fetched = await repository.getWatchlistById(wl.id);
      expect(fetched!.symbols, ['RELIANCE', 'INFY']);
    });

    test('Reorder stocks within watchlist updates positions', () async {
      final wl = await repository.createWatchlist('Reorder Test');
      await repository.addStock(wl.id, 'RELIANCE');
      await repository.addStock(wl.id, 'TCS');
      await repository.addStock(wl.id, 'INFY');
      await repository.addStock(wl.id, 'HDFCBANK');

      // Move HDFCBANK to top
      await repository.reorderStocks(
        wl.id,
        ['HDFCBANK', 'RELIANCE', 'TCS', 'INFY'],
      );

      final fetched = await repository.getWatchlistById(wl.id);
      expect(fetched!.symbols, ['HDFCBANK', 'RELIANCE', 'TCS', 'INFY']);
    });

    test('Delete watchlist removes it completely', () async {
      final wl = await repository.createWatchlist('To Delete');
      await repository.addStock(wl.id, 'RELIANCE');

      await repository.deleteWatchlist(wl.id);

      final allWatchlists = await repository.getWatchlists();
      expect(allWatchlists, isEmpty);
    });

    test('watchWatchlists stream emits updates on mutations', () async {
      final emissions = <List<String>>[];

      final sub = repository.watchWatchlists().listen((watchlists) {
        emissions.add(watchlists.map((w) => w.name).toList());
      });

      await Future.delayed(const Duration(milliseconds: 50));
      await repository.createWatchlist('First');
      await Future.delayed(const Duration(milliseconds: 50));
      await repository.createWatchlist('Second');
      await Future.delayed(const Duration(milliseconds: 50));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(3));
      expect(emissions.last, ['First', 'Second']);
    });
  });
}
