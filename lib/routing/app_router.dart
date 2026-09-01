import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/symbols.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/haptics.dart';
import '../features/market_overview/screens/market_overview_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/watchlists/screens/watchlist_detail_screen.dart';
import '../features/watchlists/screens/watchlist_list_screen.dart';
import '../features/holdings/screens/holdings_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/ticket/screens/order_confirmation_screen.dart';
import '../features/ticket/screens/ticket_screen.dart';
import '../domain/models/order.dart';

/// Root navigation key.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// GoRouter configuration for Kestrel Mobile (4 Primary Tabs).
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Splash Route (Root Navigator)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Bottom Navigation Shell (Market, Watchlists, Holdings, Orders)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return _AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/market',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MarketOverviewScreen(),
          ),
        ),
        GoRoute(
          path: '/watchlists',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WatchlistListScreen(),
          ),
        ),
        GoRoute(
          path: '/holdings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HoldingsScreen(),
          ),
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OrdersScreen(),
          ),
        ),
      ],
    ),

    // Pushed Routes (Outside Shell)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/watchlists/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return WatchlistDetailScreen(watchlistId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/ticket/:symbol',
      builder: (context, state) {
        final symbol = state.pathParameters['symbol'] ?? 'RELIANCE';
        return TicketScreen(symbol: symbol);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/ticket',
      builder: (context, state) {
        final stock = state.extra as StockDefinition? ?? Universe.reliance;
        return TicketScreen(symbol: stock.symbol);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/order-confirmation',
      builder: (context, state) {
        final order = state.extra as Order;
        return OrderConfirmationScreen(order: order);
      },
    ),
  ],
);

/// Mobile 4-Tab bottom navigation container.
class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/market')) return 0;
    if (location.startsWith('/watchlists')) return 1;
    if (location.startsWith('/holdings')) return 2;
    if (location.startsWith('/orders')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    Haptics.selection();
    switch (index) {
      case 0:
        context.go('/market');
        break;
      case 1:
        context.go('/watchlists');
        break;
      case 2:
        context.go('/holdings');
        break;
      case 3:
        context.go('/orders');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.muted,
          selectedLabelStyle: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            fontSize: 11,
          ),
          unselectedLabelStyle: AppTypography.labelSmall.copyWith(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded),
              activeIcon: Icon(Icons.show_chart_rounded, color: AppColors.accent),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline_rounded),
              activeIcon: Icon(Icons.bookmark_rounded, color: AppColors.accent),
              label: 'Watchlists',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_rounded, color: AppColors.accent),
              label: 'Holdings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded, color: AppColors.accent),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}
