import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/order.dart';
import '../providers/trading_providers.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  final Order order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletBalanceProvider);
    final remainingBalance = walletAsync.value ?? Universe.initialWalletBalance;

    final isBuy = order.side == OrderSide.buy;
    final isPending = order.isPending;
    final themeColor = isPending
        ? AppColors.accent
        : (isBuy ? AppColors.gain : AppColors.loss);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm:ss').format(order.timestamp);
    final stock = Universe.bySymbol[order.symbol];

    final priceLabel = isPending
        ? (order.type == OrderType.stopLoss ? 'Trigger Price' : 'Limit Price')
        : 'Execution Price';

    return Scaffold(
      appBar: AppBar(
        title: Text(isPending ? 'Order Placed' : 'Order Confirmation',
            style: AppTypography.titleLarge),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Animated / Styled Success or Pending Badge
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor.withValues(alpha: 0.12),
                          border: Border.all(color: themeColor, width: 2),
                        ),
                        child: Icon(
                          isPending
                              ? Icons.schedule_rounded
                              : Icons.check_rounded,
                          size: 44,
                          color: themeColor,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        isPending ? 'Order Placed (Pending)' : 'Order Executed',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPending
                            ? '${order.type.label} • ${order.side.label} ${order.quantity} shares of ${order.symbol}'
                            : '${order.side.label} ${order.quantity} shares of ${order.symbol}',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Order Receipt Card
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildReceiptRow('Order ID', order.id, isMono: true),
                            const Divider(height: 20),
                            _buildReceiptRow('Status', order.status.label,
                                valueColor: themeColor, isBold: true),
                            const Divider(height: 20),
                            _buildReceiptRow('Timestamp', dateStr),
                            const Divider(height: 20),
                            _buildReceiptRow(
                              'Company',
                              stock?.name ?? order.symbol,
                            ),
                            const Divider(height: 20),
                            _buildReceiptRow(
                              'Side & Type',
                              '${order.side.label} (${order.type.label})',
                              valueColor: isBuy ? AppColors.gain : AppColors.loss,
                              isBold: true,
                            ),
                            const Divider(height: 20),
                            _buildReceiptRow(
                              'Quantity',
                              '${order.quantity} shares',
                              isMono: true,
                            ),
                            const Divider(height: 20),
                            _buildReceiptRow(
                              priceLabel,
                              order.price.format(),
                              isMono: true,
                            ),
                            const Divider(height: 20),
                            _buildReceiptRow(
                              'Total Amount',
                              order.value.format(),
                              isMono: true,
                              isBold: true,
                              fontSize: 18,
                            ),
                            const Divider(height: 20),
                            _buildReceiptRow(
                              'Available Cash',
                              remainingBalance.format(),
                              isMono: true,
                              valueColor: AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () =>
                          context.go(isPending ? '/orders' : '/holdings'),
                      child: Text(
                        isPending ? 'View in Orders' : 'View Holdings',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () => context.go('/market'),
                      child: Text(
                        'Back to Market',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isMono = false,
    bool isBold = false,
    Color? valueColor,
    double? fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall,
        ),
        Text(
          value,
          style: (isMono
                  ? AppTypography.numericMedium
                  : AppTypography.bodyMedium)
              .copyWith(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}
