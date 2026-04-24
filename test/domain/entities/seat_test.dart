import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/seat.dart';

void main() {
  final base = Seat(
    id: 'id-1',
    seatNumber: 'A1',
    capacity: 4,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('Seat copyWith', () {
    test('필드를 변경하면 새 인스턴스 반환', () {
      final updated = base.copyWith(seatNumber: 'B2', capacity: 6);
      expect(updated.seatNumber, equals('B2'));
      expect(updated.capacity, equals(6));
      expect(updated.id, equals(base.id));
    });

    test('인자 없이 호출하면 동일 값 유지', () {
      final updated = base.copyWith();
      expect(updated.seatNumber, equals(base.seatNumber));
    });
  });

  group('Seat equality', () {
    test('동일 id이면 동등', () {
      expect(base, equals(base.copyWith(capacity: 2)));
    });

    test('다른 id이면 비동등', () {
      expect(base, isNot(equals(base.copyWith(id: 'id-2'))));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      expect(base.hashCode, equals(base.copyWith(capacity: 2).hashCode));
    });
  });
}
