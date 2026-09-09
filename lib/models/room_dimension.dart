/// How a room's wall area is measured in the Floor Plan Assistant.
enum RoomMeasureMode {
  /// Measure one L-shaped run (typically L + W), then × 2 × height.
  painterDouble,

  /// Enter length and width separately: 2 × (L + W) × height.
  lengthWidth,
}

/// A single room used to auto-calculate paintable wall area from dimensions.
class RoomDimension {
  RoomDimension({
    required this.id,
    this.name = '',
    this.measureMode = RoomMeasureMode.painterDouble,
    this.roomRunFt = 0,
    this.lengthFt = 0,
    this.widthFt = 0,
    this.heightFt = 8,
  });

  final String id;
  String name;
  RoomMeasureMode measureMode;

  /// Painter Double: one-side run (typically L + W) in feet.
  double roomRunFt;
  double lengthFt;
  double widthFt;
  double heightFt;

  /// Full perimeter used for display hints.
  double get perimeterFt {
    if (measureMode == RoomMeasureMode.painterDouble) {
      return roomRunFt > 0 ? roomRunFt * 2 : 0;
    }
    if (lengthFt <= 0 || widthFt <= 0) return 0;
    return 2 * (lengthFt + widthFt);
  }

  /// Paintable wall surface for this room.
  double get wallSqFt {
    if (heightFt <= 0) return 0;
    if (measureMode == RoomMeasureMode.painterDouble) {
      if (roomRunFt <= 0) return 0;
      return roomRunFt * 2 * heightFt;
    }
    if (lengthFt <= 0 || widthFt <= 0) return 0;
    return 2 * (lengthFt + widthFt) * heightFt;
  }

  bool get isEmpty {
    if (name.trim().isNotEmpty) return false;
    if (measureMode == RoomMeasureMode.painterDouble) {
      return roomRunFt == 0;
    }
    return lengthFt == 0 && widthFt == 0;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'measureMode': measureMode.name,
        'roomRunFt': roomRunFt,
        'lengthFt': lengthFt,
        'widthFt': widthFt,
        'heightFt': heightFt,
      };

  factory RoomDimension.fromMap(Map<dynamic, dynamic> map) {
    final modeName = map['measureMode'] as String?;
    final measureMode = RoomMeasureMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => RoomMeasureMode.painterDouble,
    );

    return RoomDimension(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      measureMode: measureMode,
      roomRunFt: (map['roomRunFt'] as num?)?.toDouble() ?? 0,
      lengthFt: (map['lengthFt'] as num?)?.toDouble() ?? 0,
      widthFt: (map['widthFt'] as num?)?.toDouble() ?? 0,
      heightFt: (map['heightFt'] as num?)?.toDouble() ?? 8,
    );
  }

  RoomDimension copyWith({
    String? name,
    RoomMeasureMode? measureMode,
    double? roomRunFt,
    double? lengthFt,
    double? widthFt,
    double? heightFt,
  }) {
    return RoomDimension(
      id: id,
      name: name ?? this.name,
      measureMode: measureMode ?? this.measureMode,
      roomRunFt: roomRunFt ?? this.roomRunFt,
      lengthFt: lengthFt ?? this.lengthFt,
      widthFt: widthFt ?? this.widthFt,
      heightFt: heightFt ?? this.heightFt,
    );
  }

  static double totalWallSqFt(Iterable<RoomDimension> rooms) {
    return rooms.fold(0.0, (sum, room) => sum + room.wallSqFt);
  }
}
