import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/entities/seat.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/presentation/pages/order/widgets/seat_grid_widget.dart';
import 'package:pos/presentation/theme/app_colors.dart';

void main() {
  final now = DateTime(2024);
  final seat = Seat(
    id: 'seat-1',
    seatNumber: 'A1',
    capacity: 4,
    createdAt: now,
    updatedAt: now,
  );

  Order makeOrder(OrderStatus status) => Order(
        id: 'order-1',
        businessDayId: 'bd-1',
        seatId: 'seat-1',
        status: status,
        totalAmount: 9000,
        orderedAt: now,
        createdAt: now,
        updatedAt: now,
      );

  Widget buildWidget({Order? activeOrder, VoidCallback? onTap}) => MaterialApp(
        home: Scaffold(
          body: SeatGridWidget(
            seat: seat,
            activeOrder: activeOrder,
            onTap: onTap ?? () {},
          ),
        ),
      );

  group('SeatGridWidget', () {
    testWidgets('좌석 번호와 인석 정보를 표시한다', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('A1'), findsOneWidget);
      expect(find.text('4인석'), findsOneWidget);
    });

    testWidgets('활성 주문 없으면 상태 레이블이 없다', (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('준비중'), findsNothing);
      expect(find.text('전달 완료'), findsNothing);
    });

    testWidgets('PENDING 주문이면 준비중 레이블과 statusPendingBg를 표시한다', (tester) async {
      await tester.pumpWidget(
        buildWidget(activeOrder: makeOrder(const OrderStatusPending())),
      );

      expect(find.text('준비중'), findsOneWidget);

      final ink = tester.widget<Ink>(find.byType(Ink).first);
      final decoration = ink.decoration as BoxDecoration;
      expect(decoration.color, AppColors.statusPendingBg);
    });

    testWidgets('DELIVERED 주문이면 전달 완료 레이블과 statusDeliveredBg를 표시한다',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(activeOrder: makeOrder(const OrderStatusDelivered())),
      );

      expect(find.text('전달 완료'), findsOneWidget);

      final ink = tester.widget<Ink>(find.byType(Ink).first);
      final decoration = ink.decoration as BoxDecoration;
      expect(decoration.color, AppColors.statusDeliveredBg);
    });

    testWidgets('활성 주문이 있으면 금액을 표시한다', (tester) async {
      await tester.pumpWidget(
        buildWidget(activeOrder: makeOrder(const OrderStatusPending())),
      );

      expect(find.text('9,000원'), findsOneWidget);
    });

    testWidgets('탭하면 onTap 콜백이 호출된다', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildWidget(onTap: () => tapped = true));

      await tester.tap(find.byType(SeatGridWidget));

      expect(tapped, isTrue);
    });

    testWidgets('Semantics 레이블이 좌석번호·인석·상태를 포함한다', (tester) async {
      await tester.pumpWidget(
        buildWidget(activeOrder: makeOrder(const OrderStatusPending())),
      );

      final semantics = tester.getSemantics(find.byType(SeatGridWidget));
      expect(semantics.label, contains('A1'));
      expect(semantics.label, contains('준비중'));
    });
  });
}
