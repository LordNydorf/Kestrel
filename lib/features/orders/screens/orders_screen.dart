import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../domain/models/order.dart';
import '../../ticket/providers/trading_providers.dart';

final ordersFilterProvider = StateProvider<OrderStatus?>((ref) => null);

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    final selectedStatus = ref.watch(ordersFilterProvider);
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders & Activity', style: AppTypography.titleLarge),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterPill(ref, 'All Orders', null, selectedStatus == null),
                  _buildFilterPill(
                      ref, 'Pending', OrderStatus.pending, selectedStatus == OrderStatus.pending),
                  _buildFilterPill(
                      ref, 'Executed', OrderStatus.executed, selectedStatus == OrderStatus.executed),
                  _buildFilterPill(
                      ref, 'Cancelled', OrderStatus.cancelled, selectedStatus == OrderStatus.cancelled),
                ],
              ),
            ),

            const Divider(height: 1),

            // Orders List
            Expanded(
              child: ordersAsync.when(
                data: (allOrders) {
                  final orders = selectedStatus == null
                      ? allOrders
                      : allOrders.where((o) => o.status == selectedStatus).toList();

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.muted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selectedStatus == null
                                ? 'No order activity yet'
                                : 'No ${selectedStatus.label.toLowerCase()} orders',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Haptics.selection();
                              context.go('/market');
                            },
                            icon: const Icon(Icons.explore_outlined, size: 18),
                            label: const Text('Explore Market'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: orders.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final isBuy = order.side == OrderSide.buy;
                      final stock = Universe.bySymbol[order.symbol];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Side + Symbol + Status Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isBuy ? AppColors.gainTint : AppColors.lossTint,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        order.side.label,
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isBuy ? AppColors.gain : AppColors.loss,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      order.symbol,
                                      style: AppTypography.titleMedium.copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${order.type.label}',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildStatusBadge(order.status),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Company Name
                            if (stock != null)
                              Text(
                                stock.name,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
                              ),

                            const SizedBox(height: 10),

                            // Metrics Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetric('Quantity', '${order.quantity} shares'),
                                _buildMetric(
                                  order.isExecuted ? 'Filled Price' : 'Target Price',
                                  order.price.format(),
                                ),
                                _buildMetric('Total Value', order.value.format(),
                                    isBold: true),
                              ],
                            ),

                            // Realized PnL (if SELL & executed)
                            if (order.side == OrderSide.sell &&
                                order.isExecuted &&
                                !order.realizedPnl.isZero) ...[
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Realized P&L:',
                                    style: AppTypography.labelSmall.copyWith(fontSize: 11),
                                  ),
                                  Text(
                                    '${order.realizedPnl.paise > 0 ? '+' : ''}${order.realizedPnl.format()}',
                                    style: AppTypography.numericSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: order.realizedPnl.paise > 0
                                          ? AppColors.gain
                                          : AppColors.loss,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const Divider(height: 16),

                            // Timestamp + Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormat.format(order.timestamp),
                                  style: AppTypography.numericSmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                  ),
                                ),
                                if (order.isPending)
                                  InkWell(
                                    onTap: () async {
                                      Haptics.medium();
                                      await ref
                                          .read(tradingControllerProvider.notifier)
                                          .cancelOrder(order.id);
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.lossTint,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppColors.loss.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel Order',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.loss,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (err, _) => Center(
                  child: Text('Error loading orders: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    WidgetRef ref,
    String label,
    OrderStatus? status,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          ref.read(ordersFilterProvider.notifier).state = status;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.muted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.executed:
        color = AppColors.gain;
        break;
      case OrderStatus.pending:
        color = const Color(0xFFF59E0B); // Amber
        break;
      case OrderStatus.cancelled:
        color = AppColors.muted;
        break;
      case OrderStatus.rejected:
        color = AppColors.loss;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.numericSmall.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
