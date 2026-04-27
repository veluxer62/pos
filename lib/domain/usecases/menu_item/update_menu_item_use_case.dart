import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';

class UpdateMenuItemUseCase {
  UpdateMenuItemUseCase({required this.repository});

  final IMenuItemRepository repository;

  Future<MenuItem> execute(
    String id, {
    String? name,
    int? price,
    String? category,
    bool? isAvailable,
  }) async =>
      repository.update(
        id,
        name: name,
        price: price,
        category: category,
        isAvailable: isAvailable,
      );
}
