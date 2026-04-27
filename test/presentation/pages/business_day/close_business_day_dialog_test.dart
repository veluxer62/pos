import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/pages/business_day/widgets/close_business_day_dialog.dart';
import 'package:pos/presentation/providers/business_day_providers.dart';
import 'package:pos/presentation/providers/order_providers.dart';

final _now = DateTime(2024, 1, 1, 9);

final _openDay = BusinessDay(
  id: 'bd-1',
  status: BusinessDayStatus.open,
  openedAt: _now,
  createdAt: _now,
);

Order _makeOrder(String id, OrderStatus status) => Order(
      id: id,
      businessDayId: 'bd-1',
      seatId: 'seat-1',
      status: status,
      totalAmount: 10000,
      orderedAt: _now,
      createdAt: _now,
      updatedAt: _now,
    );

Widget buildDialog({
  required AsyncValue<BusinessDay?> openDayState,
  List<Order> activeOrders = const [],
}) =>
    ProviderScope(
      overrides: [
        openBusinessDayProvider.overrideWith((_) {
          if (openDayState is AsyncLoading) {
            return const Stream.empty();
          } else if (openDayState is AsyncError) {
            return Stream.error((openDayState as AsyncError).error);
          } else {
            return Stream.value(
              (openDayState as AsyncData<BusinessDay?>).value,
            );
          }
        }),
        activeOrdersByBusinessDayProvider('bd-1').overrideWith(
          (_) async => activeOrders,
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => CloseBusinessDayDialog.show(context),
            child: const Text('마감 다이얼로그 열기'),
          ),
        ),
      ),
    );

void main() {
  group('CloseBusinessDayDialog', () {
    testWidgets('미처리 주문 없으면 일반 마감 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildDialog(
          openDayState: AsyncData(_openDay),
          activeOrders: const [],
        ),
      );

      await tester.tap(find.text('마감 다이얼로그 열기'));
      await tester.pumpAndSettle();

      expect(find.text('영업 마감'), findsOneWidget);
      expect(find.text('마감'), findsOneWidget);
      expect(find.text('강제 마감'), findsNothing);
    });

    testWidgets('PENDING 주문이 있으면 강제 마감 버튼과 경고가 표시된다', (tester) async {
      final orders = [
        _makeOrder('o-1', const OrderStatusPending()),
      ];

      await tester.pumpWidget(
        buildDialog(
          openDayState: AsyncData(_openDay),
          activeOrders: orders,
        ),
      );

      await tester.tap(find.text('마감 다이얼로그 열기'));
      await tester.pumpAndSettle();

      expect(find.text('강제 마감'), findsOneWidget);
      expect(find.text('미처리 주문이 있습니다'), findsOneWidget);
      expect(find.textContaining('준비중: 1건'), findsOneWidget);
    });

    testWidgets('DELIVERED 주문이 있으면 전달 완료 건수가 표시된다', (tester) async {
      final orders = [
        _makeOrder('o-1', const OrderStatusDelivered()),
        _makeOrder('o-2', const OrderStatusDelivered()),
      ];

      await tester.pumpWidget(
        buildDialog(
          openDayState: AsyncData(_openDay),
          activeOrders: orders,
        ),
      );

      await tester.tap(find.text('마감 다이얼로그 열기'));
      await tester.pumpAndSettle();

      expect(find.textContaining('전달 완료: 2건'), findsOneWidget);
    });

    testWidgets('취소 버튼을 누르면 null을 반환한다', (tester) async {
      CloseDialogResult? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            openBusinessDayProvider.overrideWith(
              (_) => Stream.value(_openDay),
            ),
            activeOrdersByBusinessDayProvider('bd-1').overrideWith(
              (_) async => <Order>[],
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CloseBusinessDayDialog.show(context);
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('열린 영업일이 없으면 안내 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(
        buildDialog(openDayState: const AsyncData(null)),
      );

      await tester.tap(find.text('마감 다이얼로그 열기'));
      await tester.pumpAndSettle();

      expect(find.text('현재 열린 영업일이 없습니다.'), findsOneWidget);
    });
  });
}
