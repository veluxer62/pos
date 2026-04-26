import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/order/create_order_use_case.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/order_status.dart';

import 'create_order_use_case_test.mocks.dart';

@GenerateMocks([IOrderRepository, IBusinessDayRepository])
void main() {
  late MockIOrderRepository mockOrderRepo;
  late MockIBusinessDayRepository mockBusinessDayRepo;
  late CreateOrderUseCase sut;

  final openBusinessDay = BusinessDay(
    id: 'bd-1',
    status: BusinessDayStatus.open,
    openedAt: DateTime(2024),
    createdAt: DateTime(2024),
  );

  final items = [
    OrderItemInput(menuItemId: 'menu-1', quantity: 2),
    OrderItemInput(menuItemId: 'menu-2', quantity: 1),
  ];

  final createdOrder = Order(
    id: 'order-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusPending(),
    totalAmount: 15000,
    orderedAt: DateTime(2024),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUp(() {
    mockOrderRepo = MockIOrderRepository();
    mockBusinessDayRepo = MockIBusinessDayRepository();
    sut = CreateOrderUseCase(
      orderRepository: mockOrderRepo,
      businessDayRepository: mockBusinessDayRepo,
    );
  });

  group('CreateOrderUseCase', () {
    test('OPEN 영업일이 있으면 주문을 생성한다', () async {
      when(mockBusinessDayRepo.getOpen()).thenAnswer((_) async => openBusinessDay);
      when(
        mockOrderRepo.create(
          businessDayId: 'bd-1',
          seatId: 'seat-1',
          items: items,
        ),
      ).thenAnswer((_) async => createdOrder);

      final result = await sut.execute(seatId: 'seat-1', items: items);

      expect(result, createdOrder);
      verify(mockBusinessDayRepo.getOpen()).called(1);
      verify(
        mockOrderRepo.create(
          businessDayId: 'bd-1',
          seatId: 'seat-1',
          items: items,
        ),
      ).called(1);
    });

    test('OPEN 영업일이 없으면 BusinessDayNotFoundException을 던진다', () async {
      when(mockBusinessDayRepo.getOpen()).thenAnswer((_) async => null);

      await expectLater(
        sut.execute(seatId: 'seat-1', items: items),
        throwsA(isA<BusinessDayNotFoundException>()),
      );
      verifyNever(mockOrderRepo.create(
        businessDayId: anyNamed('businessDayId'),
        seatId: anyNamed('seatId'),
        items: anyNamed('items'),
      ),);
    });

    test('items가 비어 있으면 ArgumentError를 던진다', () async {
      when(mockBusinessDayRepo.getOpen()).thenAnswer((_) async => openBusinessDay);

      await expectLater(
        sut.execute(seatId: 'seat-1', items: <OrderItemInput>[]),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(mockOrderRepo.create(
        businessDayId: anyNamed('businessDayId'),
        seatId: anyNamed('seatId'),
        items: anyNamed('items'),
      ),);
    });
  });
}
