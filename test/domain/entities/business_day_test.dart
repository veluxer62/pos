import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';

void main() {
  final base = BusinessDay(
    id: 'id-1',
    status: BusinessDayStatus.open,
    openedAt: DateTime(2026),
    createdAt: DateTime(2026),
  );

  group('BusinessDay copyWith', () {
    test('필드를 변경하면 새 인스턴스 반환', () {
      final updated = base.copyWith(status: BusinessDayStatus.closed);
      expect(updated.status, equals(BusinessDayStatus.closed));
      expect(updated.id, equals(base.id));
    });

    test('closedAt을 값으로 설정 가능', () {
      final closed = DateTime(2026, 4, 23, 22);
      final updated = base.copyWith(closedAt: closed);
      expect(updated.closedAt, equals(closed));
    });

    test('closedAt을 null로 되돌릴 수 있음 (sentinel 패턴)', () {
      final withClosed = base.copyWith(closedAt: DateTime(2026, 4, 23, 22));
      final reset = withClosed.copyWith(closedAt: null);
      expect(reset.closedAt, isNull);
    });

    test('인자 없이 호출하면 closedAt 유지', () {
      final withClosed = base.copyWith(closedAt: DateTime(2026));
      expect(withClosed.copyWith().closedAt, equals(DateTime(2026)));
    });
  });

  group('BusinessDay equality', () {
    test('동일 id이면 동등', () {
      expect(base, equals(base.copyWith(status: BusinessDayStatus.closed)));
    });

    test('다른 id이면 비동등', () {
      expect(base, isNot(equals(base.copyWith(id: 'id-2'))));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      expect(
        base.hashCode,
        equals(base.copyWith(status: BusinessDayStatus.closed).hashCode),
      );
    });
  });
}
