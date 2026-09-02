import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/symbols.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../domain/models/order.dart';

/// Institutional Digital Trade Receipt & Statutory Fee Breakdown Sheet.
class DigitalReceiptSheet extends StatelessWidget {
  final Order order;

  const DigitalReceiptSheet({super.key, required this.order});

  static void show(BuildContext context, Order order) {
    Haptics.medium();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DigitalReceiptSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    final stock = Universe.bySymbol[order.symbol];
    final tradedValuePaise = (order.price.paise * order.quantity).toInt();
    final tradedValue = Money.fromPaise(tradedValuePaise);

    // Statutory Charges Calculation (Simulation for Indian Equities Delivery)
    // 1. Brokerage: ₹0
    final brokerage = Money.zero;

    // 2. STT/CTT: 0.1% of Traded Value
    final sttPaise = (tradedValuePaise * 0.0010).round();
    final stt = Money.fromPaise(sttPaise);

    // 3. Exchange Txn Charge: 0.00345% of Traded Value
    final exchTxnPaise = (tradedValuePaise * 0.0000345).round();
    final exchTxn = Money.fromPaise(exchTxnPaise);

    // 4. GST: 18% of (Brokerage + Exchange Txn Charges)
    final gstPaise = ((brokerage.paise + exchTxnPaise) * 0.18).round();
    final gst = Money.fromPaise(gstPaise);

    // 5. Stamp Duty: 0.015% (BUY orders only)
    final stampDutyPaise = isBuy ? (tradedValuePaise * 0.00015).round() : 0;
    final stampDuty = Money.fromPaise(stampDutyPaise);

    // Total Charges
    final totalChargesPaise = sttPaise + exchTxnPaise + gstPaise + stampDutyPaise;
    final totalCharges = Money.fromPaise(totalChargesPaise);

    // Net Settlement
    final netSettlementPaise = isBuy
        ? tradedValuePaise + totalChargesPaise
        : tradedValuePaise - totalChargesPaise;
    final netSettlement = Money.fromPaise(netSettlementPaise);

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm:ss a');
    final formattedDate = dateFormat.format(order.executedAt ?? order.timestamp);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Grab Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Symbol, Side & Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isBuy
                        ? AppColors.gain.withValues(alpha: 0.15)
                        : AppColors.loss.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isBuy ? AppColors.gain : AppColors.loss,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(order.symbol, style: AppTypography.titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBuy
                                  ? AppColors.gain.withValues(alpha: 0.2)
                                  : AppColors.loss.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.side.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: isBuy ? AppColors.gain : AppColors.loss,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.type.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stock?.name ?? 'NSE Equity',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Order Metadata Grid
            _ReceiptRow(label: 'Order ID', value: '#${order.id.toString().padLeft(6, '0')}'),
            const SizedBox(height: 8),
            _ReceiptRow(label: 'Execution Time', value: formattedDate),
            const SizedBox(height: 8),
            _ReceiptRow(label: 'Exchange', value: 'NSE (National Stock Exchange)'),
            const SizedBox(height: 8),
            _ReceiptRow(label: 'Filled Quantity', value: '${order.quantity} Shares'),
            const SizedBox(height: 8),
            _ReceiptRow(label: 'Execution Price', value: order.price.format()),
            if (order.triggerPrice != null) ...[
              const SizedBox(height: 8),
              _ReceiptRow(label: 'Trigger Price', value: order.triggerPrice!.format()),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Financials & Charges Section
            Text(
              'FINANCIAL BREAKDOWN & STATUTORY CHARGES',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            _ReceiptRow(label: 'Gross Traded Value', value: tradedValue.format(), isBold: true),
            const SizedBox(height: 6),
            _ReceiptRow(label: 'Brokerage', value: '₹0.00 (Zero Brokerage)', isDimmed: true),
            const SizedBox(height: 6),
            _ReceiptRow(label: 'STT / CTT (0.1%)', value: stt.format(), isDimmed: true),
            const SizedBox(height: 6),
            _ReceiptRow(label: 'Exchange Txn Charges', value: exchTxn.format(), isDimmed: true),
            const SizedBox(height: 6),
            _ReceiptRow(label: 'GST (18%)', value: gst.format(), isDimmed: true),
            if (isBuy) ...[
              const SizedBox(height: 6),
              _ReceiptRow(label: 'Stamp Duty (0.015%)', value: stampDuty.format(), isDimmed: true),
            ],
            const SizedBox(height: 6),
            _ReceiptRow(label: 'Total Taxes & Charges', value: totalCharges.format()),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBuy ? 'Net Amount Debited' : 'Net Amount Credited',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    netSettlement.format(),
                    style: AppTypography.numericMedium.copyWith(
                      color: isBuy ? AppColors.ink : AppColors.gain,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            if (!order.realizedPnl.isZero) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: order.realizedPnl.isNegative
                      ? AppColors.loss.withValues(alpha: 0.1)
                      : AppColors.gain.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: order.realizedPnl.isNegative
                        ? AppColors.loss.withValues(alpha: 0.3)
                        : AppColors.gain.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Realized Profit & Loss',
                      style: AppTypography.bodySmall.copyWith(
                        color: order.realizedPnl.isNegative ? AppColors.loss : AppColors.gain,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      order.realizedPnl.format(explicitSign: true),
                      style: AppTypography.numericSmall.copyWith(
                        color: order.realizedPnl.isNegative ? AppColors.loss : AppColors.gain,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Haptics.selection();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              child: const Text('Close Receipt', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isDimmed;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDimmed ? AppColors.muted : AppColors.ink,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTypography.numericSmall.copyWith(
            color: isDimmed ? AppColors.muted : AppColors.ink,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case OrderStatus.executed:
        bg = AppColors.gain.withValues(alpha: 0.15);
        fg = AppColors.gain;
        icon = Icons.check_circle_rounded;
        break;
      case OrderStatus.pending:
        bg = AppColors.accent.withValues(alpha: 0.15);
        fg = AppColors.accent;
        icon = Icons.schedule_rounded;
        break;
      case OrderStatus.cancelled:
        bg = AppColors.muted.withValues(alpha: 0.15);
        fg = AppColors.muted;
        icon = Icons.cancel_outlined;
        break;
      case OrderStatus.rejected:
        bg = AppColors.loss.withValues(alpha: 0.15);
        fg = AppColors.loss;
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
