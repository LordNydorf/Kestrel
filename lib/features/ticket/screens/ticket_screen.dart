import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/order.dart';
import '../../../domain/services/order_validator.dart';
import '../../market_overview/providers/price_provider.dart';
import '../../market_overview/widgets/price_cell.dart';
import '../providers/trading_providers.dart';

class TicketScreen extends ConsumerStatefulWidget {
  final String symbol;

  const TicketScreen({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  OrderSide _side = OrderSide.buy;
  int _quantity = 1;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '$_quantity');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _setQuantity(int newQty) {
    if (newQty < 1) newQty = 1;
    setState(() {
      _quantity = newQty;
      _qtyController.text = '$_quantity';
    });
  }

  void _addQuantity(int delta) {
    _setQuantity(_quantity + delta);
  }

  StockDefinition get _stockMetadata {
    return Universe.bySymbol[widget.symbol] ??
        StockDefinition(
          symbol: widget.symbol,
          name: widget.symbol,
          sector: '',
          startingPrice: Universe.reliance.startingPrice,
        );
  }

  @override
  Widget build(BuildContext context) {
    final stock = _stockMetadata;
    final livePriceAsync = ref.watch(priceProvider(widget.symbol));
    final fallbackTick = ref.watch(latestTickProvider(widget.symbol));
    final currentPrice = livePriceAsync.value?.ltp ?? fallbackTick.ltp;

    final walletAsync = ref.watch(walletBalanceProvider);
    final walletBalance = walletAsync.value ?? Universe.initialWalletBalance;

    final holding = ref.watch(holdingForSymbolProvider(widget.symbol));
    final tradingState = ref.watch(tradingControllerProvider);

    final totalOrderValue = currentPrice * _quantity;

    final validation = OrderValidator.validate(
      side: _side,
      symbol: widget.symbol,
      quantity: _quantity,
      price: currentPrice,
      walletBalance: walletBalance,
      holding: holding,
    );

    final isBuy = _side == OrderSide.buy;
    final themeColor = isBuy ? AppColors.gain : AppColors.loss;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trade ${widget.symbol}',
          style: AppTypography.titleLarge,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Stock Header & Live Ticker Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: PriceCell(
                  stock: stock,
                ),
              ),

              const SizedBox(height: 16),

              // 2. Buy / Sell Segmented Toggle
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSideTab(
                        side: OrderSide.buy,
                        label: 'BUY',
                        isSelected: isBuy,
                        activeColor: AppColors.gain,
                      ),
                    ),
                    Expanded(
                      child: _buildSideTab(
                        side: OrderSide.sell,
                        label: 'SELL',
                        isSelected: !isBuy,
                        activeColor: AppColors.loss,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Quantity Stepper & Direct Input
              Text(
                'QUANTITY',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildStepButton(
                      icon: Icons.remove,
                      onTap: _quantity > 1 ? () => _addQuantity(-1) : null,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _qtyController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: AppTypography.numericLarge,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setState(() => _quantity = parsed);
                          }
                        },
                      ),
                    ),
                    _buildStepButton(
                      icon: Icons.add,
                      onTap: () => _addQuantity(1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Quick Quantity Increment Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickChip('+1', () => _addQuantity(1)),
                    _buildQuickChip('+5', () => _addQuantity(5)),
                    _buildQuickChip('+10', () => _addQuantity(10)),
                    _buildQuickChip('+25', () => _addQuantity(25)),
                    _buildQuickChip('+50', () => _addQuantity(50)),
                    _buildQuickChip('+100', () => _addQuantity(100)),
                    if (!isBuy && (holding?.quantity ?? 0) > 0)
                      _buildQuickChip('MAX (${holding!.quantity})', () {
                        _setQuantity(holding.quantity);
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Order Calculation & Balances Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Execution Price', currentPrice.format()),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Order Value',
                      totalOrderValue.format(),
                      isHighlight: true,
                    ),
                    const Divider(height: 16),
                    if (isBuy)
                      _buildSummaryRow(
                        'Available Wallet',
                        walletBalance.format(),
                      )
                    else
                      _buildSummaryRow(
                        'Shares in Portfolio',
                        '${holding?.quantity ?? 0} shares',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Validation Warning Banner
              if (!validation.isValid)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.lossTint,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.loss, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          validation.errorMessage ?? 'Invalid order parameters',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.loss,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // 6. Primary Action Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    disabledBackgroundColor: AppColors.surface,
                    foregroundColor: Colors.black,
                    disabledForegroundColor: AppColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (!validation.isValid || tradingState.isExecuting)
                      ? null
                      : () async {
                          final order = await ref
                              .read(tradingControllerProvider.notifier)
                              .executeOrder(
                                symbol: widget.symbol,
                                side: _side,
                                quantity: _quantity,
                                price: currentPrice,
                              );

                          if (order != null && context.mounted) {
                            context.push(
                              '/order-confirmation',
                              extra: order,
                            );
                          }
                        },
                  child: tradingState.isExecuting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '${_side.label} ${widget.symbol} • ${totalOrderValue.format()}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: validation.isValid
                                ? Colors.black
                                : AppColors.muted,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideTab({
    required OrderSide side,
    required String label,
    required bool isSelected,
    required Color activeColor,
  }) {
    return GestureDetector(
      key: ValueKey('tab_${side.name}'),
      onTap: () => setState(() => _side = side),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : AppColors.muted,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? AppColors.ink : AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isHighlight ? AppColors.ink : AppColors.muted,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: isHighlight
              ? AppTypography.numericMedium.copyWith(fontSize: 17)
              : AppTypography.numericSmall.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}
