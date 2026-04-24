import 'package:pos/domain/entities/menu_item.dart';

abstract interface class IMenuItemRepository {
  Future<List<MenuItem>> findAll({bool onlyAvailable = false});
  Future<MenuItem?> findById(String id);
  Future<MenuItem> create({
    required String name,
    required int price,
    required String category,
  });
  Future<MenuItem> update(
    String id, {
    String? name,
    int? price,
    String? category,
    bool? isAvailable,
  });

  /// 활성 주문(PENDING/DELIVERED) 참조 중이면 [MenuItemInUseException].
  /// 그 외에는 isAvailable=false soft delete 처리.
  Future<void> delete(String id);
  Stream<List<MenuItem>> watchAll({bool onlyAvailable = false});
}
