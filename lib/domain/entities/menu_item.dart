class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MenuItem(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    category: category ?? this.category,
    isAvailable: isAvailable ?? this.isAvailable,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
