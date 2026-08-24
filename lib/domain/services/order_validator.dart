import '../../core/money/money.dart';
import '../models/holding.dart';
import '../models/order.dart';

class OrderValidationResult {
  final bool isValid;
  final String? errorMessage;

  const OrderValidationResult._(this.isValid, this.errorMessage);

  factory OrderValidationResult.valid() =>
      const OrderValidationResult._(true, null);

  factory OrderValidationResult.invalid(String message) =>
      OrderValidationResult._(false, message);
}

class OrderValidator {
  const OrderValidator._();

  static OrderValidationResult validate({
    required OrderSide side,
    required String symbol,
    required int quantity,
    required Money price,
    required Money walletBalance,
    required Holding? holding,
  }) {
    if (quantity <= 0) {
      return OrderValidationResult.invalid('Quantity must be at least 1');
    }

    if (price.isZero || price.paise < 0) {
      return OrderValidationResult.invalid('Invalid market price');
    }

    final orderValue = price * quantity;

    if (side == OrderSide.buy) {
      if (orderValue > walletBalance) {
        final shortfall = orderValue - walletBalance;
        return OrderValidationResult.invalid(
          'Insufficient funds: Need $orderValue, Short by $shortfall',
        );
      }
    } else {
      final availableQuantity = holding?.quantity ?? 0;
      if (availableQuantity <= 0) {
        return OrderValidationResult.invalid(
          'No holdings available to sell for $symbol',
        );
      }

      if (quantity > availableQuantity) {
        return OrderValidationResult.invalid(
          'Cannot sell $quantity shares (Only $availableQuantity held)',
        );
      }
    }

    return OrderValidationResult.valid();
  }
}
