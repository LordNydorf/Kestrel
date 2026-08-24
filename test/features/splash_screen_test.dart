import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kestrel/features/splash/screens/splash_screen.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('SplashScreen renders brand title, subtitle, and engine status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            autoNavigate: false,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('KESTREL'), findsOneWidget);
      expect(find.text('REAL-TIME FINANCIAL TERMINAL'), findsOneWidget);
      expect(find.text('INITIALIZING 10-SYMBOL NSE FEED'), findsOneWidget);
      expect(find.text('v1.0.0 • Technical Instrument Engine'), findsOneWidget);
    });

    testWidgets('SplashScreen auto-navigates to /market after timer',
        (WidgetTester tester) async {
      var navigated = false;

      final testRouter = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(
              duration: Duration(milliseconds: 200),
            ),
          ),
          GoRoute(
            path: '/market',
            builder: (context, state) {
              navigated = true;
              return const Scaffold(body: Text('Market Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      expect(navigated, isTrue);
    });
  });
}
