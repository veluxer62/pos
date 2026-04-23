sealed class OrderStatus {
  const OrderStatus();

  String get name;

  static OrderStatus fromName(String statusName) => switch (statusName) {
    OrderStatusPending.statusName => const OrderStatusPending(),
    OrderStatusDelivered.statusName => const OrderStatusDelivered(),
    OrderStatusPaid.statusName => const OrderStatusPaid(),
    OrderStatusCredited.statusName => const OrderStatusCredited(),
    OrderStatusCancelled.statusName => const OrderStatusCancelled(),
    OrderStatusRefunded.statusName => const OrderStatusRefunded(),
    _ => throw ArgumentError('Unknown OrderStatus: $statusName'),
  };
}

final class OrderStatusPending extends OrderStatus {
  static const statusName = 'pending';

  const OrderStatusPending();

  @override
  String get name => statusName;
}

final class OrderStatusDelivered extends OrderStatus {
  static const statusName = 'delivered';

  const OrderStatusDelivered();

  @override
  String get name => statusName;
}

final class OrderStatusPaid extends OrderStatus {
  static const statusName = 'paid';

  const OrderStatusPaid();

  @override
  String get name => statusName;
}

final class OrderStatusCredited extends OrderStatus {
  static const statusName = 'credited';

  const OrderStatusCredited();

  @override
  String get name => statusName;
}

final class OrderStatusCancelled extends OrderStatus {
  static const statusName = 'cancelled';

  const OrderStatusCancelled();

  @override
  String get name => statusName;
}

final class OrderStatusRefunded extends OrderStatus {
  static const statusName = 'refunded';

  const OrderStatusRefunded();

  @override
  String get name => statusName;
}
