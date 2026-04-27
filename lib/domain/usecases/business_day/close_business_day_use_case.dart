import 'package:pos/domain/repositories/i_business_day_repository.dart';

class CloseBusinessDayUseCase {
  CloseBusinessDayUseCase({required this.repository});

  final IBusinessDayRepository repository;

  Future<CloseResult> execute({bool forceClose = false}) async =>
      repository.close(forceClose: forceClose);
}
