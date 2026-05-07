import 'dart:convert';
import 'dart:io';

import 'package:pos/domain/entities/business_day.dart';
import 'package:pos/domain/entities/credit_transaction.dart';
import 'package:pos/domain/entities/order.dart';
import 'package:pos/domain/repositories/i_business_day_repository.dart';
import 'package:pos/domain/repositories/i_credit_account_repository.dart';
import 'package:pos/domain/repositories/i_order_repository.dart';

class ExportDataUseCase {
  ExportDataUseCase({
    required IBusinessDayRepository businessDayRepository,
    required IOrderRepository orderRepository,
    required ICreditAccountRepository creditAccountRepository,
  })  : _businessDayRepository = businessDayRepository,
        _orderRepository = orderRepository,
        _creditAccountRepository = creditAccountRepository;

  final IBusinessDayRepository _businessDayRepository;
  final IOrderRepository _orderRepository;
  final ICreditAccountRepository _creditAccountRepository;

  /// 전체 데이터를 JSON으로 직렬화하여 [dirPath] 디렉터리에 저장한다.
  /// 파일명: `pos_backup_YYYYMMDD.json`
  /// 반환값: 저장된 파일의 절대 경로.
  Future<String> execute(String dirPath) async {
    final businessDays = await _businessDayRepository.findAll(limit: 10000);

    final allOrders = <Order>[];
    for (final businessDay in businessDays) {
      final orders = await _orderRepository.findByBusinessDay(businessDay.id);
      allOrders.addAll(orders);
    }

    final creditAccounts = await _creditAccountRepository.findAll();
    final allTransactions = <CreditTransaction>[];
    for (final account in creditAccounts) {
      final transactions = await _creditAccountRepository.getTransactions(
        account.id,
        limit: 100000,
      );
      allTransactions.addAll(transactions);
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final fileName = 'pos_backup_$dateStr.json';

    final payload = {
      'exportedAt': now.toIso8601String(),
      'businessDays': businessDays.map(_businessDayToMap).toList(),
      'orders': allOrders.map(_orderToMap).toList(),
      'creditTransactions': allTransactions.map(_creditTransactionToMap).toList(),
    };

    final file = File('$dirPath/$fileName');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  Map<String, dynamic> _businessDayToMap(BusinessDay d) => {
        'id': d.id,
        'status': d.status.name,
        'openedAt': d.openedAt.toIso8601String(),
        'closedAt': d.closedAt?.toIso8601String(),
        'createdAt': d.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _orderToMap(Order o) => {
        'id': o.id,
        'businessDayId': o.businessDayId,
        'seatId': o.seatId,
        'status': o.status.name,
        'totalAmount': o.totalAmount,
        'paymentType': o.paymentType?.name,
        'creditAccountId': o.creditAccountId,
        'orderedAt': o.orderedAt.toIso8601String(),
        'deliveredAt': o.deliveredAt?.toIso8601String(),
        'paidAt': o.paidAt?.toIso8601String(),
        'creditedAt': o.creditedAt?.toIso8601String(),
        'cancelledAt': o.cancelledAt?.toIso8601String(),
        'refundedAt': o.refundedAt?.toIso8601String(),
        'createdAt': o.createdAt.toIso8601String(),
        'updatedAt': o.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _creditTransactionToMap(CreditTransaction t) => {
        'id': t.id,
        'creditAccountId': t.creditAccountId,
        'type': t.type.name,
        'amount': t.amount,
        'orderId': t.orderId,
        'note': t.note,
        'createdAt': t.createdAt.toIso8601String(),
      };
}
