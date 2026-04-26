import 'package:drift/drift.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/database/tables.dart';
import 'package:pos/domain/entities/menu_item.dart';

part 'menu_item_dao.g.dart';

@DriftAccessor(tables: [MenuItems])
class MenuItemDao extends DatabaseAccessor<AppDatabase>
    with _$MenuItemDaoMixin {
  MenuItemDao(super.db);

  Future<List<MenuItem>> findAll({bool onlyAvailable = false}) async {
    final query = select(menuItems);
    if (onlyAvailable) {
      query.where((t) => t.isAvailable.equals(true));
    }
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  Future<MenuItem?> findById(String id) async {
    final query = select(menuItems)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<MenuItem> insert(MenuItemsCompanion companion) async {
    await into(menuItems).insert(companion);
    final row = await (select(menuItems)
          ..where((t) => t.id.equals(companion.id.value)))
        .getSingle();
    return _toEntity(row);
  }

  Future<MenuItem> updateRow(String id, MenuItemsCompanion companion) async {
    await (update(menuItems)..where((t) => t.id.equals(id))).write(companion);
    final row = await (select(menuItems)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _toEntity(row);
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now();
    await (update(menuItems)..where((t) => t.id.equals(id))).write(
      MenuItemsCompanion(
        isAvailable: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<MenuItem>> watchAll({bool onlyAvailable = false}) {
    final query = select(menuItems);
    if (onlyAvailable) {
      query.where((t) => t.isAvailable.equals(true));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  MenuItem _toEntity(MenuItemRow row) => MenuItem(
        id: row.id,
        name: row.name,
        price: row.price,
        category: row.category,
        isAvailable: row.isAvailable,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
