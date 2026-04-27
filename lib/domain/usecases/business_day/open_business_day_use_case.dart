import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';

class OpenBusinessDayUseCase {
  OpenBusinessDayUseCase({required this.repository});

  final IBusinessDayRepository repository;

  Future<BusinessDay> execute() async => repository.open();
}
