import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/entities/menu_item.dart';

void main() {
  final base = MenuItem(
    id: 'id-1',
    name: '김치찌개',
    price: 9000,
    category: '찌개',
    isAvailable: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  group('MenuItem copyWith', () {
    test('필드를 변경하면 새 인스턴스 반환', () {
      final updated = base.copyWith(name: '된장찌개', price: 8000);
      expect(updated.name, equals('된장찌개'));
      expect(updated.price, equals(8000));
      expect(updated.category, equals(base.category));
    });

    test('인자 없이 호출하면 동일 값 유지', () {
      final updated = base.copyWith();
      expect(updated.name, equals(base.name));
      expect(updated.price, equals(base.price));
    });
  });

  group('MenuItem equality', () {
    test('동일 id이면 동등', () {
      final other = base.copyWith(name: '된장찌개');
      expect(base, equals(other));
    });

    test('다른 id이면 비동등', () {
      final other = base.copyWith(id: 'id-2');
      expect(base, isNot(equals(other)));
    });

    test('hashCode가 id 기반으로 일관됨', () {
      final other = base.copyWith(name: '된장찌개');
      expect(base.hashCode, equals(other.hashCode));
    });
  });
}
