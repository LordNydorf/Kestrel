import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/constants/symbols.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/data/feed/market_data_service.dart';
import 'package:kestrel/data/feed/price_tick.dart';

void main() {
  group('MarketDataService Unit Tests', () {
    late MarketDataService service;

    setUp(() {
      service = MarketDataService(ticksPerSecondPerSymbol: 10.0);
    });

    tearDown(() {
      service.dispose();
    });

    test('Initializes with exact 10 PRD starting prices', () {
      expect(service.getPrice('RELIANCE'), Money.fromPaise(295000));
      expect(service.getPrice('TCS'), Money.fromPaise(385000));
      expect(service.getPrice('INFY'), Money.fromPaise(165000));
      expect(service.getPrice('HDFCBANK'), Money.fromPaise(162000));
      expect(service.getPrice('ICICIBANK'), Money.fromPaise(115000));
      expect(service.getPrice('SBIN'), Money.fromPaise(81000));
      expect(service.getPrice('ITC'), Money.fromPaise(46500));
      expect(service.getPrice('LT'), Money.fromPaise(360000));
      expect(service.getPrice('BHARTIARTL'), Money.fromPaise(158000));
      expect(service.getPrice('AXISBANK'), Money.fromPaise(109000));
    });

    test('Emits ticks on allTicks stream when started', () async {
      final ticks = <PriceTick>[];
      final completer = Completer<void>();

      final sub = service.allTicks.listen((tick) {
        ticks.add(tick);
        if (ticks.length >= 5 && !completer.isCompleted) {
          completer.complete();
        }
      });

      service.start();
      await completer.future.timeout(const Duration(seconds: 2));
      await sub.cancel();

      expect(ticks.length, greaterThanOrEqualTo(5));
      for (final tick in ticks) {
        expect(Universe.bySymbol.containsKey(tick.symbol), isTrue);
        expect(tick.ltp.paise, greaterThan(0));
      }
    });

    test('Filters ticks properly on symbol-specific stream', () async {
      final relianceTicks = <PriceTick>[];
      final completer = Completer<void>();

      final sub = service.tickStreamFor('RELIANCE').listen((tick) {
        relianceTicks.add(tick);
        if (relianceTicks.length >= 2 && !completer.isCompleted) {
          completer.complete();
        }
      });

      service.start();
      await completer.future.timeout(const Duration(seconds: 3));
      await sub.cancel();

      expect(relianceTicks.isNotEmpty, isTrue);
      for (final tick in relianceTicks) {
        expect(tick.symbol, 'RELIANCE');
      }
    });

    test('Synchronous price snapshot updates after ticks', () async {
      final initialPrice = service.getPrice('RELIANCE');
      final completer = Completer<void>();

      service.tickStreamFor('RELIANCE').listen((tick) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      service.start();
      await completer.future.timeout(const Duration(seconds: 3));

      final latestTick = service.getLatestTick('RELIANCE');
      expect(latestTick.symbol, 'RELIANCE');
      expect(service.getPrice('RELIANCE'), latestTick.ltp);
      expect(latestTick.prevClose, initialPrice);
    });

    test('Tick rate update adjusts simulation speed safely', () {
      expect(service.ticksPerSecondPerSymbol, 10.0);
      service.setTickRate(5.0);
      expect(service.ticksPerSecondPerSymbol, 5.0);
    });
  });
}
