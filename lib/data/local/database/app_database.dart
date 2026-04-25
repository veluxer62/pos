import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos/data/local/database/tables.dart';
// app_database.g.dart가 생성 시 참조하는 enum 타입 — 직접 사용 없음
import 'package:pos/domain/value_objects/business_day_status.dart';
import 'package:pos/domain/value_objects/credit_transaction_type.dart';
import 'package:pos/domain/value_objects/order_status.dart';
import 'package:pos/domain/value_objects/payment_type.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    MenuItems,
    Seats,
    BusinessDays,
    Orders,
    OrderItems,
    CreditAccounts,
    CreditTransactions,
    DailySalesReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // 버전별 명시적 마이그레이션
          // if (from < 2) await m.addColumn(...);
        },
      );

  static LazyDatabase _openConnection() => LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'pos.db'));
        return NativeDatabase.createInBackground(file);
      });
}
