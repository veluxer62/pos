# Repository Contract: ISeatRepository

**Layer**: `domain/repositories/`
**Implementation**: `data/local/repositories/LocalSeatRepository`

---

```dart
abstract interface class ISeatRepository {
  /// 전체 좌석 목록 (seatNumber 오름차순).
  Future<List<Seat>> findAll();

  /// ID로 좌석 단건 조회. 없으면 null.
  Future<Seat?> findById(String id);

  /// 좌석 번호로 조회. 없으면 null.
  Future<Seat?> findBySeatNumber(String seatNumber);

  /// 좌석 등록. seatNumber 중복 시 DuplicateSeatNumberException.
  Future<Seat> create({
    required String seatNumber,
    required int capacity,
  });

  /// 좌석 수정.
  Future<Seat> update(
    String id, {
    String? seatNumber,
    int? capacity,
  });

  /// 좌석 삭제.
  /// 활성 주문(PENDING/DELIVERED)이 연결된 경우 SeatInUseException.
  Future<void> delete(String id);

  /// 좌석 목록 변경 스트림.
  Stream<List<Seat>> watchAll();
}
```

---

## 예외

| 예외 클래스 | 발생 조건 |
|------------|----------|
| `SeatNotFoundException` | 좌석 없음 |
| `DuplicateSeatNumberException` | 좌석 번호 중복 |
| `SeatInUseException` | 활성 주문 연결 중인 좌석 삭제 시도 |

---

## 비즈니스 규칙 요약

- `seatNumber`는 UNIQUE 제약 (애플리케이션 레벨에서 중복 검사)
- 수용 인원(`capacity`) 변경은 진행 중 주문에 영향 없음
- 활성 주문 연결 중인 좌석 삭제 불가
