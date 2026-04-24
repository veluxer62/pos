import 'package:drift/drift.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/domain/value_objects/payment_type.dart';

// OrderStatus는 sealed class이므로 수동 TypeConverter 사용
class OrderStatusConverter extends TypeConverter<OrderStatus, String> {
  const OrderStatusConverter();

  @override
  OrderStatus fromSql(String fromDb) {
    // OrderStatus.fromName이 알 수 없는 값에 ArgumentError를 던져 fail-fast 보장
    return OrderStatus.fromName(fromDb);
  }

  @override
  String toSql(OrderStatus value) => value.name;
}

@DataClassName('MenuItemRow')
class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get price => integer()();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  BoolColumn get isAvailable =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SeatRow')
class Seats extends Table {
  TextColumn get id => text()();
  TextColumn get seatNumber => text().withLength(min: 1, max: 20)();
  IntColumn get capacity => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {seatNumber},
      ];
}

@DataClassName('BusinessDayRow')
class BusinessDays extends Table {
  TextColumn get id => text()();
  TextColumn get status => textEnum<BusinessDayStatus>()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrderRow')
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get businessDayId =>
      text().references(BusinessDays, #id)();
  TextColumn get seatId => text().references(Seats, #id)();
  TextColumn get status =>
      text().map(const OrderStatusConverter())();
  IntColumn get totalAmount => integer()();
  TextColumn get paymentType =>
      textEnum<PaymentType>().nullable()();
  TextColumn get creditAccountId =>
      text().nullable().references(CreditAccounts, #id)();
  DateTimeColumn get orderedAt => dateTime()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get creditedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  DateTimeColumn get refundedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OrderItemRow')
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get menuItemId => text().references(MenuItems, #id)();
  TextColumn get menuName => text().withLength(min: 1, max: 100)();
  IntColumn get unitPrice => integer()();
  IntColumn get quantity => integer()();
  IntColumn get subtotal => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CreditAccountRow')
class CreditAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get customerName =>
      text().withLength(min: 1, max: 100)();
  IntColumn get balance =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CreditTransactionRow')
class CreditTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get creditAccountId =>
      text().references(CreditAccounts, #id)();
  TextColumn get type => textEnum<CreditTransactionType>()();
  IntColumn get amount => integer()();
  TextColumn get orderId =>
      text().nullable().references(Orders, #id)();
  TextColumn get note => text().withLength(max: 200).nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DailySalesReportRow')
class DailySalesReports extends Table {
  TextColumn get id => text()();
  TextColumn get businessDayId =>
      text().unique().references(BusinessDays, #id)();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime()();
  IntColumn get totalRevenue => integer()();
  IntColumn get paidOrderCount => integer()();
  IntColumn get creditedAmount => integer()();
  IntColumn get creditedOrderCount => integer()();
  IntColumn get cancelledOrderCount => integer()();
  IntColumn get refundedOrderCount => integer()();
  IntColumn get refundedAmount => integer()();
  IntColumn get netRevenue => integer()();
  TextColumn get menuSummaryJson => text()();
  TextColumn get hourlySummaryJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
