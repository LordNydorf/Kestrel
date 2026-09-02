import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/features/holdings/widgets/holding_detail_sheet.dart';

void main() {
  group('HoldingDetailSheet Widget Tests', () {
    testWidgets('Renders holding position metrics and Add More / Square Off buttons', (tester) async {
      final holding = Holding(
        symbol: 'TCS',
        quantity: 10,
        avgCost: Money.fromRupees(3800),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HoldingDetailSheet(holding: holding),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TCS'), findsOneWidget);
      expect(find.text('UNREALIZED P&L'), findsOneWidget);
      expect(find.text('Add More'), findsOneWidget);
      expect(find.text('Square Off'), findsOneWidget);
      expect(find.text('Total Quantity'), findsOneWidget);
      expect(find.text('Average Buy Price'), findsOneWidget);
    });
  });
}
