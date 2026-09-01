import 'package:flutter/services.dart';

/// Tactile Haptic Feedback Utility for Kestrel.
///
/// Wraps system haptic calls safely with error suppression for unsupported environments.
class Haptics {
  const Haptics._();

  /// Subtle click for numeric steppers, quick quantity chips, and pill switches.
  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Medium tactile pulse for tab switches (BUY/SELL, Market/Watchlist) and timeframe selectors.
  static void medium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy tactile thud on atomic order execution, limit order placement, and trigger notifications.
  static void heavy() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Light tap for gentle UI interactions.
  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
