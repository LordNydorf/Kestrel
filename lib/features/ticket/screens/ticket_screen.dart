import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../domain/models/order.dart';
import '../../../domain/services/order_validator.dart';
import '../../charts/widgets/technical_chart.dart';
import '../../market_depth/widgets/market_depth_ladder.dart';
import '../../market_overview/providers/price_provider.dart';
import '../../market_overview/widgets/price_cell.dart';
import '../providers/trading_providers.dart';
import '../widgets/order_type_selector.dart';

enum TicketViewMode { chart, depth }

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
  TicketViewMode _viewMode = TicketViewMode.chart;
  OrderSide _side = OrderSide.buy;
  OrderType _orderType = OrderType.market;
  int _quantity = 1;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  late final TextEditingController _triggerPriceController;
  Money? _customLimitPrice;
  Money? _customTriggerPrice;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '$_quantity');
    _priceController = TextEditingController();
    _triggerPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _triggerPriceController.dispose();
    super.dispose();
  }

  void _setQuantity(int newQty) {
    if (newQty < 1) newQty = 1;
    Haptics.selection();
    setState(() {
      _quantity = newQty;
      _qtyController.text = '$_quantity';
    });
  }

  void _addQuantity(int delta) {
    _setQuantity(_quantity + delta);
  }

  void _nudgeLimitPrice(double deltaRupees, Money currentLtp) {
    Haptics.selection();
    final current = _customLimitPrice ?? currentLtp;
    final newPaise = (current.paise + (deltaRupees * 100).round()).clamp(100, 100000000);
    final updated = Money.fromPaise(newPaise);
    setState(() {
      _customLimitPrice = updated;
      _priceController.text = updated.inRupees.toStringAsFixed(2);
    });
  }

  void _nudgeTriggerPrice(double deltaRupees, Money currentLtp) {
    Haptics.selection();
    final current = _customTriggerPrice ?? currentLtp;
    final newPaise = (current.paise + (deltaRupees * 100).round()).clamp(100, 100000000);
    final updated = Money.fromPaise(newPaise);
    setState(() {
      _customTriggerPrice = updated;
      _triggerPriceController.text = updated.inRupees.toStringAsFixed(2);
    });
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
    final livePrice = livePriceAsync.value?.ltp ?? fallbackTick.ltp;

    final walletAsync = ref.watch(walletBalanceProvider);
    final walletBalance = walletAsync.value ?? Universe.initialWalletBalance;

    final holding = ref.watch(holdingForSymbolProvider(widget.symbol));
    final tradingState = ref.watch(tradingControllerProvider);

    // Effective price for calculation
    final effectivePrice = _orderType == OrderType.limit
        ? (_customLimitPrice ?? livePrice)
        : (_orderType == OrderType.stopLoss
            ? (_customTriggerPrice ?? livePrice)
            : livePrice);

    final totalOrderValue = effectivePrice * _quantity;

    final validation = OrderValidator.validate(
      side: _side,
      type: _orderType,
      symbol: widget.symbol,
      quantity: _quantity,
      price: effectivePrice,
      triggerPrice: _customTriggerPrice,
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
      // STICKY BOTTOM EXECUTION BAR (Always visible before scrolling!)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Line: Total Order Value + Wallet/Holding Context
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL VALUE',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        totalOrderValue.format(),
                        style: AppTypography.numericLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBuy ? 'AVAILABLE CASH' : 'HELD SHARES',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        isBuy
                            ? walletBalance.format()
                            : '${holding?.quantity ?? 0} shares',
                        style: AppTypography.numericSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isBuy ? AppColors.accent : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Validation Warning Banner (if invalid)
              if (!validation.isValid) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.lossTint,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.loss, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          validation.errorMessage ?? 'Invalid order parameters',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.loss,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Primary Action Execution Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    disabledBackgroundColor: AppColors.surfaceElevated,
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
                          Haptics.heavy();
                          final order = await ref
                              .read(tradingControllerProvider.notifier)
                              .executeOrder(
                                symbol: widget.symbol,
                                side: _side,
                                type: _orderType,
                                quantity: _quantity,
                                price: effectivePrice,
                                triggerPrice: _customTriggerPrice,
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
                          '${_orderType == OrderType.market ? '' : '${_orderType.label.toUpperCase()} '}${_side.label} ${widget.symbol} • ${totalOrderValue.format()}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: validation.isValid ? Colors.black : AppColors.muted,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

              const SizedBox(height: 10),

              // 2. Tabbed Visual Section Switcher: Chart vs L2 Order Book
              Container(
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildViewTab(
                        mode: TicketViewMode.chart,
                        icon: Icons.candlestick_chart_rounded,
                        label: 'Technical Chart',
                        isSelected: _viewMode == TicketViewMode.chart,
                      ),
                    ),
                    Expanded(
                      child: _buildViewTab(
                        mode: TicketViewMode.depth,
                        icon: Icons.table_rows_rounded,
                        label: 'L2 Order Book',
                        isSelected: _viewMode == TicketViewMode.depth,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Visual Content (Chart or Depth Ladder)
              if (_viewMode == TicketViewMode.chart)
                TechnicalChart(symbol: widget.symbol)
              else
                MarketDepthLadder(symbol: widget.symbol),

              const SizedBox(height: 16),

              // 3. Order Type Switcher (Market, Limit, Stop-Loss)
              OrderTypeSelector(
                selectedType: _orderType,
                onTypeChanged: (type) {
                  setState(() {
                    _orderType = type;
                    if (type == OrderType.limit && _customLimitPrice == null) {
                      _customLimitPrice = livePrice;
                      _priceController.text = livePrice.inRupees.toStringAsFixed(2);
                    } else if (type == OrderType.stopLoss && _customTriggerPrice == null) {
                      _customTriggerPrice = livePrice;
                      _triggerPriceController.text = livePrice.inRupees.toStringAsFixed(2);
                    }
                  });
                },
              ),

              const SizedBox(height: 12),

              // 4. Buy / Sell Segmented Toggle
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

              // 5. Custom Price Inputs with Nudge Buttons (if Limit or Stop-Loss)
              if (_orderType == OrderType.limit) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIMIT TARGET PRICE (₹)',
                      style: AppTypography.labelSmall.copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Row(
                      children: [
                        _buildNudgeChip('-₹1', () => _nudgeLimitPrice(-1.0, livePrice)),
                        const SizedBox(width: 4),
                        _buildNudgeChip('+₹1', () => _nudgeLimitPrice(1.0, livePrice)),
                        const SizedBox(width: 4),
                        _buildNudgeChip('LTP', () {
                          setState(() {
                            _customLimitPrice = livePrice;
                            _priceController.text = livePrice.inRupees.toStringAsFixed(2);
                          });
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.numericMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: livePrice.inRupees.toStringAsFixed(2),
                      hintStyle: AppTypography.numericMedium.copyWith(color: AppColors.muted),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _customLimitPrice = Money.fromRupees(parsed));
                      }
                    },
                  ),
                ),
              ],

              if (_orderType == OrderType.stopLoss) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STOP-LOSS TRIGGER PRICE (₹)',
                      style: AppTypography.labelSmall.copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Row(
                      children: [
                        _buildNudgeChip('-₹1', () => _nudgeTriggerPrice(-1.0, livePrice)),
                        const SizedBox(width: 4),
                        _buildNudgeChip('+₹1', () => _nudgeTriggerPrice(1.0, livePrice)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _triggerPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.numericMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: livePrice.inRupees.toStringAsFixed(2),
                      hintStyle: AppTypography.numericMedium.copyWith(color: AppColors.muted),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _customTriggerPrice = Money.fromRupees(parsed));
                      }
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 6. Quantity Stepper & Quick Increment Chips
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
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewTab({
    required TicketViewMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          Haptics.selection();
          setState(() => _viewMode = mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.accent : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
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
      onTap: () {
        Haptics.medium();
        setState(() => _side = side);
      },
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
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 22,
          color: onTap != null ? AppColors.ink : AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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

  Widget _buildNudgeChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.numericSmall.copyWith(
            fontSize: 10,
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
