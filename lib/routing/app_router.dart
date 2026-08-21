import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/symbols.dart';
import '../core/theme/app_theme.dart';
import '../features/market_overview/screens/market_overview_screen.dart';

/// Root navigation key.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// GoRouter configuration for Kestrel Mobile.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/market',
  routes: [
    // Bottom Navigation Shell (Market, Watchlists, Holdings)
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
            child: _PlaceholderTabScreen(
              title: 'Watchlists',
              icon: Icons.bookmark_border_outlined,
              description: 'Watchlists CRUD (Step 2 Milestone)',
            ),
          ),
        ),
        GoRoute(
          path: '/holdings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _PlaceholderTabScreen(
              title: 'Holdings',
              icon: Icons.pie_chart_outline,
              description: 'Holdings & Realtime P&L (Step 4 Milestone)',
            ),
          ),
        ),
      ],
    ),

    // Pushed Routes (Outside Shell)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/ticket',
      builder: (context, state) {
        final stock = state.extra as StockDefinition? ?? Universe.reliance;
        return _PlaceholderTicketScreen(stock: stock);
      },
    ),
  ],
);

/// Mobile bottom navigation container.
class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/market')) return 0;
    if (location.startsWith('/watchlists')) return 1;
    if (location.startsWith('/holdings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
        unselectedLabelStyle: AppTypography.labelSmall,
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
        ],
      ),
    );
  }
}

/// Placeholder screen for upcoming tabs.
class _PlaceholderTabScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderTabScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: AppTypography.titleLarge)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(title, style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder screen for ticket.
class _PlaceholderTicketScreen extends StatelessWidget {
  final StockDefinition stock;

  const _PlaceholderTicketScreen({required this.stock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${stock.symbol} Ticket', style: AppTypography.titleLarge),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stock.name,
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Buy/Sell Ticket (Step 3 Milestone)',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceHover,
                  foregroundColor: AppColors.ink,
                ),
                child: const Text('Back to Market'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
