import 'dart:async';
import 'dart:math';
import '../../core/constants/symbols.dart';
import '../../core/money/money.dart';
import 'price_tick.dart';

/// Single source of truth in-memory mock market-data feed.
///
/// Simulates realistic high-frequency market movement via a bounded random walk
/// with mean reversion and positive floor clamping.
class MarketDataService {
  final Random _random;

  /// Current prices keyed by symbol string.
  final Map<String, Money> _currentPrices = {};

  /// Previous close prices for change calculation.
  final Map<String, Money> _prevCloses = {};

  /// Latest emitted tick per symbol.
  final Map<String, PriceTick> _latestTicks = {};

  /// Broadcast stream for all ticks.
  final StreamController<PriceTick> _allTicksController =
      StreamController<PriceTick>.broadcast();

  /// Dedicated broadcast stream controllers per symbol for fine-grained listening.
  final Map<String, StreamController<PriceTick>> _symbolControllers = {};

  /// Periodic timer generating ticks.
  Timer? _tickTimer;

  /// Ticks per second per symbol (default: 1.0, configurable up to 5.0+).
  double _ticksPerSecondPerSymbol;

  /// Whether the feed is currently active.
  bool _isRunning = false;

  MarketDataService({
    double ticksPerSecondPerSymbol = 1.0,
    Random? random,
  })  : _ticksPerSecondPerSymbol = ticksPerSecondPerSymbol,
        _random = random ?? Random() {
    _initializeUniverse();
  }

  /// Initialize universe starting prices and stream controllers.
  void _initializeUniverse() {
    for (final stock in Universe.all) {
      _currentPrices[stock.symbol] = stock.startingPrice;
      _prevCloses[stock.symbol] = stock.startingPrice;
      _symbolControllers[stock.symbol] =
          StreamController<PriceTick>.broadcast();

      final initialTick = PriceTick(
        symbol: stock.symbol,
        ltp: stock.startingPrice,
        prevClose: stock.startingPrice,
        direction: TickDirection.neutral,
      );
      _latestTicks[stock.symbol] = initialTick;
    }
  }

  /// Stream of all market ticks across all symbols.
  Stream<PriceTick> get allTicks => _allTicksController.stream;

  /// Stream of ticks for a specific symbol only.
  Stream<PriceTick> tickStreamFor(String symbol) {
    final controller = _symbolControllers[symbol];
    if (controller != null) {
      return controller.stream;
    }
    // Fallback filter if symbol not yet registered
    return _allTicksController.stream.where((tick) => tick.symbol == symbol);
  }

  /// Current price snapshot for a symbol (synchronous, race-free for orders).
  Money getPrice(String symbol) {
    return _currentPrices[symbol] ??
        Universe.bySymbol[symbol]?.startingPrice ??
        Money.zero;
  }

  /// Latest PriceTick snapshot for a symbol.
  PriceTick getLatestTick(String symbol) {
    return _latestTicks[symbol] ??
        PriceTick(
          symbol: symbol,
          ltp: getPrice(symbol),
          prevClose: _prevCloses[symbol] ?? getPrice(symbol),
          direction: TickDirection.neutral,
        );
  }

  /// Current tick rate per symbol.
  double get ticksPerSecondPerSymbol => _ticksPerSecondPerSymbol;

  /// Whether the market data feed is active.
  bool get isRunning => _isRunning;

  /// Start the market data feed.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _scheduleTicks();
  }

  /// Pause/stop the market data feed.
  void stop() {
    _isRunning = false;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// Updates the tick generation rate (e.g. 1.0x to 5.0x for stress testing).
  void setTickRate(double ticksPerSecondPerSymbol) {
    if (ticksPerSecondPerSymbol <= 0) return;
    _ticksPerSecondPerSymbol = ticksPerSecondPerSymbol;
    if (_isRunning) {
      _tickTimer?.cancel();
      _scheduleTicks();
    }
  }

  void _scheduleTicks() {
    // Total aggregate ticks per second = symbolsCount * ticksPerSecondPerSymbol
    final totalTicksPerSecond =
        Universe.all.length * _ticksPerSecondPerSymbol;
    final intervalMs = (1000.0 / totalTicksPerSecond).round().clamp(5, 1000);

    _tickTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _generateTick();
    });
  }

  /// Generate a random walk tick for one randomly picked symbol.
  void _generateTick() {
    if (!_isRunning) return;

    final symbols = Universe.all;
    final stock = symbols[_random.nextInt(symbols.length)];
    final symbol = stock.symbol;

    final currentLtp = _currentPrices[symbol]!;
    final prevClose = _prevCloses[symbol]!;

    // Bounded random walk: -0.25% to +0.25% with gentle mean reversion toward prevClose
    final priceRatio = currentLtp.paise / prevClose.paise;
    double meanReversionDrift = 0.0;
    if (priceRatio > 1.05) {
      meanReversionDrift = -0.0005; // Gentle downward pull if up > 5%
    } else if (priceRatio < 0.95) {
      meanReversionDrift = 0.0005; // Gentle upward pull if down > 5%
    }

    final randomFactor = (_random.nextDouble() * 0.005) - 0.0025; // [-0.25%, +0.25%]
    final deltaPct = randomFactor + meanReversionDrift;

    // Minimum tick step is 5 paise (₹0.05)
    int deltaPaise = (currentLtp.paise * deltaPct).round();
    if (deltaPaise == 0) {
      deltaPaise = _random.nextBool() ? 5 : -5;
    }

    // Safety floor: clamp at minimum ₹1.00 (100 paise)
    final newPaise = max(100, currentLtp.paise + deltaPaise);
    final newLtp = Money.fromPaise(newPaise);

    final direction = newLtp > currentLtp
        ? TickDirection.up
        : (newLtp < currentLtp ? TickDirection.down : TickDirection.neutral);

    _currentPrices[symbol] = newLtp;

    final tick = PriceTick(
      symbol: symbol,
      ltp: newLtp,
      prevClose: prevClose,
      direction: direction,
      timestamp: DateTime.now(),
    );

    _latestTicks[symbol] = tick;

    // Broadcast to global and symbol streams
    _allTicksController.add(tick);
    _symbolControllers[symbol]?.add(tick);
  }

  /// Clean up all streams and timers.
  void dispose() {
    stop();
    _allTicksController.close();
    for (final controller in _symbolControllers.values) {
      controller.close();
    }
  }
}
