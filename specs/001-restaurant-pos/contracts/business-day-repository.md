# Repository Contract: IBusinessDayRepository

**Layer**: `domain/repositories/`
**Implementation**: `data/local/repositories/LocalBusinessDayRepository`

---

```dart
abstract interface class IBusinessDayRepository {
  /// 영업 시작. OPEN 영업일이 이미 존재하면 BusinessDayAlreadyOpenException.
  Future<BusinessDay> open();

  /// 현재 OPEN 영업일 조회. 없으면 null.
  Future<BusinessDay?> getOpen();

  /// 영업 마감.
  /// forceClose=false: PENDING/DELIVERED 주문 존재 시 PendingOrdersExistException.
  /// forceClose=true: 미처리 주문을 CANCELLED 처리 후 마감.
  /// 마감과 DailySalesReport 생성은 동일 트랜잭션 내 원자적 처리.
  Future<CloseResult> close({bool forceClose = false});

  /// ID로 영업일 단건 조회. 없으면 null.
  Future<BusinessDay?> findById(String id);

  /// 영업일 목록 (날짜 역순).
  Future<List<BusinessDay>> findAll({
    DateTime? from,
    DateTime? to,
    int limit = 30,
    int offset = 0,
  });

  /// 특정 영업일의 DailySalesReport 조회. 없으면 null.
  Future<DailySalesReport?> getReport(String businessDayId);

  /// 기간별 DailySalesReport 목록.
  Future<List<DailySalesReport>> getReports({
    required DateTime from,
    required DateTime to,
  });

  /// OPEN 영업일 변경 스트림.
  Stream<BusinessDay?> watchOpen();
}
```

---

## 타입 정의

```dart
enum BusinessDayStatus { open, closed }

class CloseResult {
  final BusinessDay businessDay;
  final DailySalesReport report;
}
```

---

## 예외

| 예외 클래스 | 발생 조건 |
|------------|----------|
| `BusinessDayAlreadyOpenException` | OPEN 영업일이 이미 존재 |
| `BusinessDayNotFoundException` | 대상 영업일 없음 |
| `PendingOrdersExistException` | 미처리 주문 존재 (forceClose=false 시) — `pendingCount`, `deliveredCount` 포함 |

---

## 비즈니스 규칙 요약

- OPEN 상태 영업일은 전체 DB에서 최대 1개
- `close()`는 drift `transaction()` 블록에서 마감 + 보고서 생성 원자적 수행
- `DailySalesReport`는 마감 시 스냅샷으로 생성, 이후 읽기 전용
- 영업일 없이 주문 생성·상태 변경 불가 (`IOrderRepository` 참조)
