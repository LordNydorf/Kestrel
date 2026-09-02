import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/features/orders/widgets/digital_receipt_sheet.dart';

void main() {
  group('DigitalReceiptSheet Widget Tests', () {
    testWidgets('Renders executed order details and regulatory fee breakdown', (tester) async {
      final order = Order(
        id: 'ORD-101',
        symbol: 'SBIN',
        side: OrderSide.buy,
        type: OrderType.limit,
        status: OrderStatus.executed,
        quantity: 10,
        price: Money.fromRupees(790),
        value: Money.fromRupees(7900),
        timestamp: DateTime(2026, 8, 25, 10, 29, 0),
        executedAt: DateTime(2026, 8, 25, 10, 30, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DigitalReceiptSheet(order: order),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SBIN'), findsOneWidget);
      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('Limit Order'), findsOneWidget);
      expect(find.text('Executed'), findsOneWidget);
      expect(find.text('FINANCIAL BREAKDOWN & STATUTORY CHARGES'), findsOneWidget);
      expect(find.text('STT / CTT (0.1%)'), findsOneWidget);
      expect(find.text('Net Amount Debited'), findsOneWidget);
    });

    testWidgets('Renders realized P&L for executed SELL orders', (tester) async {
      final order = Order(
        id: 'ORD-102',
        symbol: 'RELIANCE',
        side: OrderSide.sell,
        type: OrderType.market,
        status: OrderStatus.executed,
        quantity: 5,
        price: Money.fromRupees(3000),
        value: Money.fromRupees(15000),
        realizedPnl: Money.fromRupees(500),
        timestamp: DateTime(2026, 8, 25, 11, 0, 0),
        executedAt: DateTime(2026, 8, 25, 11, 0, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DigitalReceiptSheet(order: order),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('SELL'), findsOneWidget);
      expect(find.text('Net Amount Credited'), findsOneWidget);
      expect(find.text('Realized Profit & Loss'), findsOneWidget);
      expect(find.text('+₹500.00'), findsOneWidget);
    });
  });
}
