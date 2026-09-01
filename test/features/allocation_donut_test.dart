import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/features/holdings/widgets/allocation_donut_chart.dart';
import 'package:kestrel/features/ticket/providers/trading_providers.dart';
import '../../test/data/trading_repository_test.dart';

void main() {
  group('AllocationDonutChart Widget Tests', () {
    late FakeTradingRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeTradingRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('Renders sector allocation breakdown and custom canvas donut', (tester) async {
      fakeRepo.seedHolding(Holding(
        symbol: 'RELIANCE',
        quantity: 10,
        avgCost: Money.fromRupees(2900),
        updatedAt: DateTime.now(),
      ));
      fakeRepo.seedHolding(Holding(
        symbol: 'TCS',
        quantity: 5,
        avgCost: Money.fromRupees(3800),
        updatedAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestApp(const AllocationDonutChart()));
      await tester.pumpAndSettle();

      expect(find.text('ASSET ALLOCATION'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
