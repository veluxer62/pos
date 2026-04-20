# Repository Contract: IMenuItemRepository

**Layer**: `domain/repositories/`
**Implementation**: `data/local/repositories/LocalMenuItemRepository`

---

```dart
abstract interface class IMenuItemRepository {
  /// 전체 메뉴 목록. onlyAvailable=true: isAvailable=true인 메뉴만.
  Future<List<MenuItem>> findAll({bool onlyAvailable = false});

  /// ID로 메뉴 단건 조회. 없으면 null.
  Future<MenuItem?> findById(String id);

  /// 메뉴 등록.
  Future<MenuItem> create({
    required String name,
    required int price,
    required String category,
  });

  /// 메뉴 수정. 변경된 필드만 전달 (null은 변경 없음).
  Future<MenuItem> update(
    String id, {
    String? name,
    int? price,
    String? category,
    bool? isAvailable,
  });

  /// 메뉴 삭제.
  /// 활성 주문(PENDING/DELIVERED)이 참조 중이면 MenuItemInUseException.
  /// 그 외에는 isAvailable=false 처리 후 soft delete.
  Future<void> delete(String id);

  /// 메뉴 목록 변경 스트림.
  Stream<List<MenuItem>> watchAll({bool onlyAvailable = false});
}
```

---

## 예외

| 예외 클래스 | 발생 조건 |
|------------|----------|
| `MenuItemNotFoundException` | 메뉴 없음 |
| `MenuItemInUseException` | 활성 주문이 참조 중인 메뉴 삭제 시도 |

---

## 비즈니스 규칙 요약

- 가격 변경은 MenuItem만 수정, 기존 OrderItems의 `unitPrice` 스냅샷에 영향 없음
- 활성 주문 참조 중 삭제 불가 → `isAvailable=false` soft delete로 전환
- `isAvailable=false` 메뉴는 주문 생성 화면에서 숨김
