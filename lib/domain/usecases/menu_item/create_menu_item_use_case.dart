import 'package:pos/domain/entities/menu_item.dart';
import 'package:pos/domain/repositories/i_menu_item_repository.dart';

class CreateMenuItemUseCase {
  CreateMenuItemUseCase({required this.repository});

  final IMenuItemRepository repository;

  Future<MenuItem> execute({
    required String name,
    required int price,
    required String category,
  }) async =>
      repository.create(name: name, price: price, category: category);
}
