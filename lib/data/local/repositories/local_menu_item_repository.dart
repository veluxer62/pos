import 'package:drift/drift.dart';
import 'package:pos/data/local/daos/menu_item_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/exceptions/domain_exceptions.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';
import 'package:uuid/uuid.dart';

class LocalMenuItemRepository implements IMenuItemRepository {
  LocalMenuItemRepository(this._dao);

  final MenuItemDao _dao;
  final _uuid = const Uuid();

  @override
  Future<List<MenuItem>> findAll({bool onlyAvailable = false}) =>
      _dao.findAll(onlyAvailable: onlyAvailable);

  @override
  Future<MenuItem?> findById(String id) => _dao.findById(id);

  @override
  Future<MenuItem> create({
    required String name,
    required int price,
    required String category,
  }) {
    final now = DateTime.now();
    return _dao.insert(
      MenuItemsCompanion.insert(
        id: _uuid.v4(),
        name: name,
        price: price,
        category: category,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<MenuItem> update(
    String id, {
    String? name,
    int? price,
    String? category,
    bool? isAvailable,
  }) async {
    final existing = await _dao.findById(id);
    if (existing == null) throw MenuItemNotFoundException(id);

    final now = DateTime.now();
    return _dao.updateRow(
      id,
      MenuItemsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        price: price != null ? Value(price) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        isAvailable:
            isAvailable != null ? Value(isAvailable) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> delete(String id) => _dao.softDelete(id);

  @override
  Stream<List<MenuItem>> watchAll({bool onlyAvailable = false}) =>
      _dao.watchAll(onlyAvailable: onlyAvailable);
}
