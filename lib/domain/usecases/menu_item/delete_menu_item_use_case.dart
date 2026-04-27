import 'package:pos/domain/repositories/i_menu_item_repository.dart';

class DeleteMenuItemUseCase {
  DeleteMenuItemUseCase({required this.repository});

  final IMenuItemRepository repository;

  Future<void> execute(String id) async => repository.delete(id);
}
