import '../money/money.dart';

/// Definition of a stock in the Kestrel universe.
class StockDefinition {
  final String symbol;
  final String name;
  final String sector;
  final Money startingPrice;

  const StockDefinition({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.startingPrice,
  });
}

/// The fixed 10-symbol NSE universe defined in PRD §4.
class Universe {
  static const StockDefinition reliance = StockDefinition(
    symbol: 'RELIANCE',
    name: 'Reliance Industries Ltd',
    sector: 'Energy & Conglomerate',
    startingPrice: Money.fromPaise(295000), // ₹2,950.00
  );

  static const StockDefinition tcs = StockDefinition(
    symbol: 'TCS',
    name: 'Tata Consultancy Services',
    sector: 'Information Technology',
    startingPrice: Money.fromPaise(385000), // ₹3,850.00
  );

  static const StockDefinition infy = StockDefinition(
    symbol: 'INFY',
    name: 'Infosys Ltd',
    sector: 'Information Technology',
    startingPrice: Money.fromPaise(165000), // ₹1,650.00
  );

  static const StockDefinition hdfcBank = StockDefinition(
    symbol: 'HDFCBANK',
    name: 'HDFC Bank Ltd',
    sector: 'Banking & Financials',
    startingPrice: Money.fromPaise(162000), // ₹1,620.00
  );

  static const StockDefinition iciciBank = StockDefinition(
    symbol: 'ICICIBANK',
    name: 'ICICI Bank Ltd',
    sector: 'Banking & Financials',
    startingPrice: Money.fromPaise(115000), // ₹1,150.00
  );

  static const StockDefinition sbin = StockDefinition(
    symbol: 'SBIN',
    name: 'State Bank of India',
    sector: 'Banking & Financials',
    startingPrice: Money.fromPaise(81000), // ₹810.00
  );

  static const StockDefinition itc = StockDefinition(
    symbol: 'ITC',
    name: 'ITC Ltd',
    sector: 'Consumer Goods (FMCG)',
    startingPrice: Money.fromPaise(46500), // ₹465.00
  );

  static const StockDefinition lt = StockDefinition(
    symbol: 'LT',
    name: 'Larsen & Toubro Ltd',
    sector: 'Infrastructure & Eng',
    startingPrice: Money.fromPaise(360000), // ₹3,600.00
  );

  static const StockDefinition bhartiAirtel = StockDefinition(
    symbol: 'BHARTIARTL',
    name: 'Bharti Airtel Ltd',
    sector: 'Telecommunications',
    startingPrice: Money.fromPaise(158000), // ₹1,580.00
  );

  static const StockDefinition axisBank = StockDefinition(
    symbol: 'AXISBANK',
    name: 'Axis Bank Ltd',
    sector: 'Banking & Financials',
    startingPrice: Money.fromPaise(109000), // ₹1,090.00
  );

  /// All 10 stocks in canonical order.
  static const List<StockDefinition> all = [
    reliance,
    tcs,
    infy,
    hdfcBank,
    iciciBank,
    sbin,
    itc,
    lt,
    bhartiAirtel,
    axisBank,
  ];

  /// Fast lookup map by symbol string.
  static final Map<String, StockDefinition> bySymbol = {
    for (final stock in all) stock.symbol: stock,
  };

  /// Initial mock wallet balance (₹1,00,000.00 = 100,000 × 100 paise).
  static const Money initialWalletBalance = Money.fromPaise(10000000);
}
