import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kestrel/features/watchlists/providers/watchlist_providers.dart';
import 'package:kestrel/features/watchlists/screens/watchlist_detail_screen.dart';
import 'package:kestrel/features/watchlists/screens/watchlist_list_screen.dart';
import '../data/watchlist_repository_test.dart';

void main() {
  group('Watchlists Screen Widget Tests', () {
    late FakeWatchlistRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeWatchlistRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    testWidgets('WatchlistListScreen: empty state -> create dialog -> card rendered',
        (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/watchlists',
        routes: [
          GoRoute(
            path: '/watchlists',
            builder: (context, state) => const WatchlistListScreen(),
          ),
          GoRoute(
            path: '/watchlists/:id',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return WatchlistDetailScreen(watchlistId: id);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // 1. Verify Empty State
      expect(find.text('No Watchlists Yet'), findsOneWidget);
      expect(find.text('Create Watchlist'), findsOneWidget);

      // 2. Tap Create Watchlist button to open dialog
      await tester.tap(find.text('Create Watchlist'));
      await tester.pumpAndSettle();

      expect(find.text('New Watchlist'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Tech Giants');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // 3. Detail screen opens automatically for 'Tech Giants'
      expect(find.text('Tech Giants'), findsOneWidget);
      expect(find.text('No Stocks Added'), findsOneWidget);
      expect(find.text('0 Instruments'), findsOneWidget);
    });

    testWidgets('WatchlistDetailScreen: empty state -> add stock from sheet -> renders stock',
        (WidgetTester tester) async {
      // Seed a watchlist into the repository
      final created = await fakeRepo.createWatchlist('Core Holdings');

      final testRouter = GoRouter(
        initialLocation: '/watchlists/${created.id}',
        routes: [
          GoRoute(
            path: '/watchlists/:id',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return WatchlistDetailScreen(watchlistId: id);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Core Holdings'), findsOneWidget);
      expect(find.text('No Stocks Added'), findsOneWidget);

      // Open Stock Picker bottom sheet
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Stocks'));
      await tester.pumpAndSettle();

      expect(find.text('Add Stocks'), findsWidgets);
      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('TCS'), findsOneWidget);

      // Tap 'RELIANCE'
      await tester.tap(find.text('RELIANCE'));
      await tester.pumpAndSettle();

      // Verify stock row appears in the watchlist
      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('1 Instrument'), findsOneWidget);
    });
  });
}
