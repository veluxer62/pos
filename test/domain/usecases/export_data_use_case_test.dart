import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/credit_account.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';
import 'package:pos/domain/usecases/export_data_use_case.dart';
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/domain/value_objects/order_status.dart';

import 'export_data_use_case_test.mocks.dart';

@GenerateMocks([
  IBusinessDayRepository,
  IOrderRepository,
  ICreditAccountRepository,
])
void main() {
  late MockIBusinessDayRepository mockBdRepo;
  late MockIOrderRepository mockOrderRepo;
  late MockICreditAccountRepository mockCreditRepo;
  late ExportDataUseCase sut;
  late Directory tempDir;

  final baseTime = DateTime(2024, 1, 15);

  final businessDay = BusinessDay(
    id: 'bd-1',
    status: BusinessDayStatus.closed,
    openedAt: baseTime,
    createdAt: baseTime,
    closedAt: baseTime.add(const Duration(hours: 8)),
  );

  final order = Order(
    id: 'order-1',
    businessDayId: 'bd-1',
    seatId: 'seat-1',
    status: const OrderStatusPaid(),
    totalAmount: 9000,
    orderedAt: baseTime,
    createdAt: baseTime,
    updatedAt: baseTime,
  );

  final creditAccount = CreditAccount(
    id: 'account-1',
    customerName: '홍길동',
    balance: 5000,
    createdAt: baseTime,
    updatedAt: baseTime,
  );

  final transaction = CreditTransaction(
    id: 'tx-1',
    creditAccountId: 'account-1',
    type: CreditTransactionType.charge,
    amount: 5000,
    createdAt: baseTime,
    orderId: 'order-1',
  );

  setUp(() {
    mockBdRepo = MockIBusinessDayRepository();
    mockOrderRepo = MockIOrderRepository();
    mockCreditRepo = MockICreditAccountRepository();
    sut = ExportDataUseCase(
      businessDayRepository: mockBdRepo,
      orderRepository: mockOrderRepo,
      creditAccountRepository: mockCreditRepo,
    );
    tempDir = Directory.systemTemp.createTempSync('export_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ExportDataUseCase', () {
    test('데이터가 있으면 JSON 파일을 생성하고 경로를 반환한다', () async {
      when(mockBdRepo.findAll(limit: anyNamed('limit')))
          .thenAnswer((_) async => [businessDay]);
      when(mockOrderRepo.findByBusinessDay('bd-1'))
          .thenAnswer((_) async => [order]);
      when(mockCreditRepo.findAll())
          .thenAnswer((_) async => [creditAccount]);
      when(
        mockCreditRepo.getTransactions(
          'account-1',
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async => [transaction]);

      final path = await sut.execute(tempDir.path);

      expect(File(path).existsSync(), isTrue);
      final content =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      expect(content['businessDays'], hasLength(1));
      expect(content['orders'], hasLength(1));
      expect(content['creditTransactions'], hasLength(1));
      expect(content['exportedAt'], isNotNull);
    });

    test('데이터가 없으면 빈 리스트로 JSON 파일을 생성한다', () async {
      when(mockBdRepo.findAll(limit: anyNamed('limit')))
          .thenAnswer((_) async => []);
      when(mockCreditRepo.findAll()).thenAnswer((_) async => []);

      final path = await sut.execute(tempDir.path);

      expect(File(path).existsSync(), isTrue);
      final content =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      expect(content['businessDays'], isEmpty);
      expect(content['orders'], isEmpty);
      expect(content['creditTransactions'], isEmpty);
    });

    test('파일명은 pos_backup_YYYYMMDD.json 형식이다', () async {
      when(mockBdRepo.findAll(limit: anyNamed('limit')))
          .thenAnswer((_) async => []);
      when(mockCreditRepo.findAll()).thenAnswer((_) async => []);

      final path = await sut.execute(tempDir.path);

      expect(path, contains('pos_backup_'));
      expect(path, endsWith('.json'));
    });

    test('BusinessDay 데이터가 JSON에 올바르게 직렬화된다', () async {
      when(mockBdRepo.findAll(limit: anyNamed('limit')))
          .thenAnswer((_) async => [businessDay]);
      when(mockOrderRepo.findByBusinessDay('bd-1'))
          .thenAnswer((_) async => []);
      when(mockCreditRepo.findAll()).thenAnswer((_) async => []);

      final path = await sut.execute(tempDir.path);
      final content =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

      final bd = (content['businessDays'] as List)[0] as Map<String, dynamic>;
      expect(bd['id'], 'bd-1');
      expect(bd['status'], 'closed');
      expect(bd['closedAt'], isNotNull);
    });

    test('Order 데이터가 JSON에 올바르게 직렬화된다', () async {
      when(mockBdRepo.findAll(limit: anyNamed('limit')))
          .thenAnswer((_) async => [businessDay]);
      when(mockOrderRepo.findByBusinessDay('bd-1'))
          .thenAnswer((_) async => [order]);
      when(mockCreditRepo.findAll()).thenAnswer((_) async => []);

      final path = await sut.execute(tempDir.path);
      final content =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

      final o = (content['orders'] as List)[0] as Map<String, dynamic>;
      expect(o['id'], 'order-1');
      expect(o['totalAmount'], 9000);
      expect(o['status'], 'paid');
    });
  });
}
