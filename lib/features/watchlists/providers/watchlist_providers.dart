import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/watchlist_repository.dart';
import '../../../domain/models/watchlist.dart';

/// Watchlist repository provider.
final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = WatchlistRepository(db);
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Reactive stream of all user watchlists.
final watchlistsStreamProvider = StreamProvider<List<Watchlist>>((ref) {
  final repo = ref.watch(watchlistRepositoryProvider);
  return repo.watchWatchlists();
});

/// Reactive stream for a specific watchlist by ID.
final watchlistDetailProvider =
    StreamProvider.family<Watchlist?, int>((ref, id) {
  final watchlistsAsync = ref.watch(watchlistsStreamProvider);
  return watchlistsAsync.when(
    data: (watchlists) {
      try {
        final match = watchlists.firstWhere((w) => w.id == id);
        return Stream.value(match);
      } catch (_) {
        return Stream.value(null);
      }
    },
    error: (err, stack) => Stream.error(err, stack),
    loading: () => const Stream.empty(),
  );
});

/// Controller for performing mutations on watchlists.
final watchlistControllerProvider =
    StateNotifierProvider<WatchlistController, AsyncValue<void>>((ref) {
  final repo = ref.watch(watchlistRepositoryProvider);
  return WatchlistController(repo);
});

class WatchlistController extends StateNotifier<AsyncValue<void>> {
  final WatchlistRepository _repo;

  WatchlistController(this._repo) : super(const AsyncValue.data(null));

  Future<Watchlist?> createWatchlist(String name) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repo.createWatchlist(name);
      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> renameWatchlist(int id, String newName) async {
    state = const AsyncValue.loading();
    try {
      await _repo.renameWatchlist(id, newName);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWatchlist(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteWatchlist(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addStock(int watchlistId, String symbol) async {
    try {
      await _repo.addStock(watchlistId, symbol);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeStock(int watchlistId, String symbol) async {
    try {
      await _repo.removeStock(watchlistId, symbol);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderStocks(
    int watchlistId,
    List<String> orderedSymbols,
  ) async {
    try {
      await _repo.reorderStocks(watchlistId, orderedSymbols);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
