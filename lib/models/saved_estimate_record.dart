import 'exterior_estimate_models.dart';
import 'paint_estimate_models.dart';
import 'room_dimension.dart';

/// Serializable snapshot of the full calculator form, stored in Hive.
class SavedEstimateRecord {
  SavedEstimateRecord({
    required this.id,
    required this.clientName,
    required this.savedAt,
    required this.wallSqFt,
    required this.pricePerSqFt,
    required this.pricePerGallon,
    required this.coats,
    required this.doors,
    required this.windows,
    required this.includeDoorsWindows,
    required this.colorLogs,
    required this.roomDimensions,
    required this.totalEstimate,
    this.blueprintFileName,
    this.blueprintBase64,
    this.jobKind = EstimateJobKind.interior,
    this.stainPricePerGallon = '55',
    this.laborPricePerLinFt = '',
    this.exteriorLines = const [],
  });

  final String id;
  final String clientName;
  final DateTime savedAt;
  final String wallSqFt;
  final String pricePerSqFt;
  final String pricePerGallon;
  final int coats;
  final int doors;
  final int windows;
  final bool includeDoorsWindows;
  final List<Map<String, dynamic>> colorLogs;
  final List<Map<String, dynamic>> roomDimensions;
  final double totalEstimate;
  final String? blueprintFileName;
  final String? blueprintBase64;
  final EstimateJobKind jobKind;
  final String stainPricePerGallon;
  final String laborPricePerLinFt;
  final List<Map<String, dynamic>> exteriorLines;

  bool get isExterior => jobKind == EstimateJobKind.exterior;

  String get summaryLabel {
    if (!isExterior) {
      if (wallSqFt.isEmpty) return '';
      return '$wallSqFt sq ft · $coats coat${coats == 1 ? '' : 's'}';
    }
    final named = exteriorLines
        .expand((line) => [
              (line['description'] as String?)?.trim() ?? '',
              (line['extraDescription'] as String?)?.trim() ?? '',
            ])
        .where((name) => name.isNotEmpty)
        .toList();
    if (named.isEmpty) return 'Exterior';
    return 'Exterior · ${named.join(', ')}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientName': clientName,
        'savedAt': savedAt.millisecondsSinceEpoch,
        'wallSqFt': wallSqFt,
        'pricePerSqFt': pricePerSqFt,
        'pricePerGallon': pricePerGallon,
        'coats': coats,
        'doors': doors,
        'windows': windows,
        'includeDoorsWindows': includeDoorsWindows,
        'colorLogs': colorLogs,
        'roomDimensions': roomDimensions,
        'totalEstimate': totalEstimate,
        'blueprintFileName': blueprintFileName,
        'blueprintBase64': blueprintBase64,
        'jobKind': jobKind.name,
        'stainPricePerGallon': stainPricePerGallon,
        'laborPricePerLinFt': laborPricePerLinFt,
        'exteriorLines': exteriorLines,
      };

  factory SavedEstimateRecord.fromMap(Map<dynamic, dynamic> map) {
    return SavedEstimateRecord(
      id: map['id'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['savedAt'] as num?)?.toInt() ?? 0,
      ),
      wallSqFt: map['wallSqFt'] as String? ?? '',
      pricePerSqFt: map['pricePerSqFt'] as String? ?? '',
      pricePerGallon: map['pricePerGallon'] as String? ?? '45',
      coats: (map['coats'] as num?)?.toInt() ?? 2,
      doors: (map['doors'] as num?)?.toInt() ?? 0,
      windows: (map['windows'] as num?)?.toInt() ?? 0,
      includeDoorsWindows: map['includeDoorsWindows'] as bool? ?? false,
      colorLogs: (map['colorLogs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      roomDimensions: (map['roomDimensions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      totalEstimate: (map['totalEstimate'] as num?)?.toDouble() ?? 0,
      blueprintFileName: map['blueprintFileName'] as String?,
      blueprintBase64: map['blueprintBase64'] as String?,
      jobKind: EstimateJobKind.fromName(map['jobKind'] as String?),
      stainPricePerGallon: map['stainPricePerGallon'] as String? ?? '55',
      laborPricePerLinFt: map['laborPricePerLinFt'] as String? ?? '',
      exteriorLines: (map['exteriorLines'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  List<ColorLog> toColorLogs() {
    return colorLogs.map((map) {
      final brandName = map['brand'] as String? ?? PaintBrand.sherwinWilliams.name;
      final brand = PaintBrand.values.firstWhere(
        (b) => b.name == brandName,
        orElse: () => PaintBrand.sherwinWilliams,
      );
      return ColorLog(
        id: map['id'] as String? ?? '0',
        roomName: map['roomName'] as String? ?? '',
        brand: brand,
        colorName: map['colorName'] as String? ?? '',
      );
    }).toList();
  }

  List<RoomDimension> toRoomDimensions() {
    return roomDimensions.map(RoomDimension.fromMap).toList();
  }

  List<ExteriorJobLine> toExteriorLines() {
    return exteriorLines.map(ExteriorJobLine.fromMap).toList();
  }
}

/// Live calculator state packaged for persistence.
class EstimateFormSnapshot {
  EstimateFormSnapshot({
    required this.wallSqFt,
    required this.pricePerSqFt,
    required this.pricePerGallon,
    required this.coats,
    required this.doors,
    required this.windows,
    required this.includeDoorsWindows,
    required this.colorLogs,
    required this.roomDimensions,
    required this.totalEstimate,
    this.blueprintFileName,
    this.blueprintBase64,
    this.jobKind = EstimateJobKind.interior,
    this.stainPricePerGallon = '55',
    this.laborPricePerLinFt = '',
    this.exteriorLines = const [],
  });

  final String wallSqFt;
  final String pricePerSqFt;
  final String pricePerGallon;
  final int coats;
  final int doors;
  final int windows;
  final bool includeDoorsWindows;
  final List<ColorLog> colorLogs;
  final List<RoomDimension> roomDimensions;
  final double totalEstimate;
  final String? blueprintFileName;
  final String? blueprintBase64;
  final EstimateJobKind jobKind;
  final String stainPricePerGallon;
  final String laborPricePerLinFt;
  final List<ExteriorJobLine> exteriorLines;

  SavedEstimateRecord toRecord({
    required String id,
    required String clientName,
    required DateTime savedAt,
  }) {
    return SavedEstimateRecord(
      id: id,
      clientName: clientName,
      savedAt: savedAt,
      wallSqFt: wallSqFt,
      pricePerSqFt: pricePerSqFt,
      pricePerGallon: pricePerGallon,
      coats: coats,
      doors: doors,
      windows: windows,
      includeDoorsWindows: includeDoorsWindows,
      colorLogs: colorLogs
          .map(
            (log) => {
              'id': log.id,
              'roomName': log.roomName,
              'brand': log.brand.name,
              'colorName': log.colorName,
            },
          )
          .toList(),
      roomDimensions: roomDimensions.map((r) => r.toMap()).toList(),
      totalEstimate: totalEstimate,
      blueprintFileName: blueprintFileName,
      blueprintBase64: blueprintBase64,
      jobKind: jobKind,
      stainPricePerGallon: stainPricePerGallon,
      laborPricePerLinFt: laborPricePerLinFt,
      exteriorLines: exteriorLines.map((line) => line.toMap()).toList(),
    );
  }
}
