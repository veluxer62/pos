import 'package:pos/domain/repositories/i_business_day_repository.dart';

class DiscardBusinessDayUseCase {
  DiscardBusinessDayUseCase({required this.repository});

  final IBusinessDayRepository repository;

  Future<void> execute() => repository.discard();
}
