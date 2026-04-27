class Seat {
  const Seat({
    required this.id,
    required this.seatNumber,
    required this.capacity,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String seatNumber;
  final int capacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Seat copyWith({
    String? id,
    String? seatNumber,
    int? capacity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Seat(
        id: id ?? this.id,
        seatNumber: seatNumber ?? this.seatNumber,
        capacity: capacity ?? this.capacity,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Seat && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
