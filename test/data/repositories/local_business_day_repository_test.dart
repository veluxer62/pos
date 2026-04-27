import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/daos/business_day_dao.dart';
import 'package:pos/data/local/database/app_database.dart';
import 'package:pos/data/local/repositories/local_business_day_repository.dart';

void main() {
  late AppDatabase db;
  late LocalBusinessDayRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalBusinessDayRepository(BusinessDayDao(db));
  });

  tearDown(() async => db.close());

  group('LocalBusinessDayRepository', () {
    test('getOpen — 열린 영업일이 없으면 null을 반환한다', () async {
      final result = await repository.getOpen();

      expect(result, isNull);
    });

    test('open — 영업일을 시작한다', () async {
      final day = await repository.open();

      expect(day.id, isNotEmpty);
    });

    test('open 후 getOpen — 열린 영업일을 반환한다', () async {
      await repository.open();

      final result = await repository.getOpen();

      expect(result, isNotNull);
    });

    test('watchOpen — 열린 영업일 스트림을 반환한다', () async {
      await repository.open();

      final stream = repository.watchOpen();
      final day = await stream.first;

      expect(day, isNotNull);
    });

    test('findAll — 영업일 목록을 반환한다', () async {
      await repository.open();
      await repository.close();

      final days = await repository.findAll();

      expect(days.length, 1);
    });

    test('close — 영업일을 마감하고 CloseResult를 반환한다', () async {
      await repository.open();

      final result = await repository.close();

      expect(result.businessDay.closedAt, isNotNull);
      expect(result.report, isNotNull);
    });

    test('getReport — 보고서가 없으면 null을 반환한다', () async {
      final result = await repository.getReport('nonexistent');

      expect(result, isNull);
    });

    test('getReports — 날짜 범위로 보고서를 반환한다', () async {
      await repository.open();
      await repository.close();

      final reports = await repository.getReports(
        from: DateTime.now().subtract(const Duration(days: 1)),
        to: DateTime.now().add(const Duration(days: 1)),
      );

      expect(reports.length, 1);
    });
  });
}
