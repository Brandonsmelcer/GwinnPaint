import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/room_dimension.dart';
import '../services/blueprint_service.dart';
import '../theme/paint_estimate_theme.dart';

/// Free floor-plan helper: import a blueprint for reference and auto-calc
/// wall sq ft — default is Painter Double (measure one side, × 2 × height).
class FloorPlanAssistant extends StatefulWidget {
  const FloorPlanAssistant({
    super.key,
    required this.rooms,
    required this.onRoomsChanged,
    required this.onApplyTotal,
    this.blueprintFileName,
    this.blueprintBase64,
    this.onBlueprintChanged,
  });

  final List<RoomDimension> rooms;
  final ValueChanged<List<RoomDimension>> onRoomsChanged;
  final ValueChanged<double> onApplyTotal;
  final String? blueprintFileName;
  final String? blueprintBase64;
  final void Function(String? fileName, String? base64, bool isPdf)? onBlueprintChanged;

  @override
  State<FloorPlanAssistant> createState() => _FloorPlanAssistantState();
}

class _FloorPlanAssistantState extends State<FloorPlanAssistant> {
  bool _isPdf = false;
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    _resolveBlueprintPath();
  }

  @override
  void didUpdateWidget(FloorPlanAssistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blueprintFileName != widget.blueprintFileName) {
      _resolveBlueprintPath();
    }
  }

  Future<void> _resolveBlueprintPath() async {
    if (widget.blueprintFileName == null) {
      setState(() => _resolvedPath = null);
      return;
    }
    final file = await BlueprintService.resolveFile(widget.blueprintFileName);
    if (mounted) {
      setState(() {
        _resolvedPath = file?.path;
        _isPdf = widget.blueprintFileName!.endsWith('.pdf');
      });
    }
  }

  double get _totalWallSqFt => RoomDimension.totalWallSqFt(widget.rooms);

  Future<void> _importBlueprint() async {
    final result = await BlueprintService.pickAndSave();
    if (result == null || !mounted) return;

    widget.onBlueprintChanged?.call(
      result.fileName,
      result.base64Data,
      result.isPdf,
    );

    setState(() {
      _isPdf = result.isPdf;
      _resolvedPath = result.filePath;
    });
  }

  void _addRoom() {
    final updated = [
      ...widget.rooms,
      RoomDimension(id: '${DateTime.now().millisecondsSinceEpoch}'),
    ];
    widget.onRoomsChanged(updated);
  }

  void _removeRoom(String id) {
    var updated = widget.rooms.where((r) => r.id != id).toList();
    if (updated.isEmpty) {
      updated = [RoomDimension(id: '${DateTime.now().millisecondsSinceEpoch}')];
    }
    widget.onRoomsChanged(updated);
  }

  void _updateRoom(String id, RoomDimension Function(RoomDimension) updater) {
    widget.onRoomsChanged(
      widget.rooms.map((r) => r.id == id ? updater(r) : r).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import a floor plan for reference, then enter room measurements. '
          'Painter Double: measure one side of the room (L + W), we × 2 × height.',
          style: PaintEstimateTheme.bodyStyle(
            size: 12,
            color: PaintEstimateTheme.charcoal.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _importBlueprint,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Import Blueprint'),
            ),
            if (widget.blueprintFileName != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  widget.onBlueprintChanged?.call(null, null, false);
                  setState(() {
                    _resolvedPath = null;
                    _isPdf = false;
                  });
                },
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Remove blueprint',
                color: PaintEstimateTheme.charcoal.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
        if (widget.blueprintFileName != null) ...[
          const SizedBox(height: 12),
          _BlueprintPreview(
            filePath: _resolvedPath,
            base64Data: widget.blueprintBase64,
            isPdf: _isPdf,
          ),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < widget.rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _RoomDimensionRow(
            room: widget.rooms[i],
            index: i,
            canRemove: widget.rooms.length > 1,
            onChanged: (updater) => _updateRoom(widget.rooms[i].id, updater),
            onRemove: () => _removeRoom(widget.rooms[i].id),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addRoom,
            icon: const Icon(Icons.add, size: 18, color: PaintEstimateTheme.warmGold),
            label: Text(
              'Add Room',
              style: PaintEstimateTheme.bodyStyle(
                color: PaintEstimateTheme.midnightNavy,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PaintEstimateTheme.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculated Wall Area',
                      style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700),
                    ),
                    Text(
                      '${_totalWallSqFt.toStringAsFixed(0)} sq ft total',
                      style: PaintEstimateTheme.monoStyle(
                        size: 16,
                        color: PaintEstimateTheme.warmGold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _totalWallSqFt > 0
                    ? () => widget.onApplyTotal(_totalWallSqFt)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaintEstimateTheme.warmGold,
                  foregroundColor: PaintEstimateTheme.midnightNavy,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlueprintPreview extends StatelessWidget {
  const _BlueprintPreview({
    required this.filePath,
    required this.base64Data,
    required this.isPdf,
  });

  final String? filePath;
  final String? base64Data;
  final bool isPdf;

  @override
  Widget build(BuildContext context) {
    if (isPdf) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PaintEstimateTheme.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              color: PaintEstimateTheme.midnightNavy.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'PDF floor plan attached',
              style: PaintEstimateTheme.bodyStyle(size: 12),
            ),
          ],
        ),
      );
    }

    Widget? image;
    if (!kIsWeb && filePath != null) {
      image = Image.file(
        File(filePath!),
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      final bytes = BlueprintService.decodeBase64(base64Data);
      if (bytes != null) {
        image = Image.memory(
          bytes,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    if (image == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: image,
    );
  }
}

class _RoomDimensionRow extends StatelessWidget {
  const _RoomDimensionRow({
    required this.room,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final RoomDimension room;
  final int index;
  final bool canRemove;
  final ValueChanged<RoomDimension Function(RoomDimension)> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isPainter = room.measureMode == RoomMeasureMode.painterDouble;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PaintEstimateTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Room ${index + 1}',
                style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700),
              ),
              const Spacer(),
              if (room.wallSqFt > 0)
                Text(
                  '${room.wallSqFt.toStringAsFixed(0)} sq ft',
                  style: PaintEstimateTheme.monoStyle(
                    size: 12,
                    color: PaintEstimateTheme.warmGold,
                  ),
                ),
              if (canRemove) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close, size: 18),
                  color: PaintEstimateTheme.charcoal,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<RoomMeasureMode>(
            segments: const [
              ButtonSegment(
                value: RoomMeasureMode.painterDouble,
                label: Text('Painter Double'),
                icon: Icon(Icons.straighten, size: 16),
              ),
              ButtonSegment(
                value: RoomMeasureMode.lengthWidth,
                label: Text('L × W'),
                icon: Icon(Icons.crop_square_outlined, size: 16),
              ),
            ],
            selected: {room.measureMode},
            onSelectionChanged: (selected) {
              onChanged((r) => r.copyWith(measureMode: selected.first));
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                PaintEstimateTheme.bodyStyle(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: room.name,
            onChanged: (v) => onChanged((r) => r.copyWith(name: v)),
            style: PaintEstimateTheme.bodyStyle(),
            decoration: const InputDecoration(
              labelText: 'Room Name',
              hintText: 'Living Room',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          if (isPainter) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _DimField(
                    label: 'Room Run (ft)',
                    value: room.roomRunFt,
                    onChanged: (v) => onChanged((r) => r.copyWith(roomRunFt: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DimField(
                    label: 'Height (ft)',
                    value: room.heightFt,
                    onChanged: (v) => onChanged((r) => r.copyWith(heightFt: v)),
                  ),
                ),
              ],
            ),
            if (room.roomRunFt > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Perimeter = ${room.roomRunFt.toStringAsFixed(0)} × 2 '
                '= ${room.perimeterFt.toStringAsFixed(0)} ft  ·  '
                'Walls = ${room.wallSqFt.toStringAsFixed(0)} sq ft',
                style: PaintEstimateTheme.bodyStyle(
                  size: 11,
                  color: PaintEstimateTheme.charcoal.withValues(alpha: 0.55),
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _DimField(
                    label: 'Length (ft)',
                    value: room.lengthFt,
                    onChanged: (v) => onChanged((r) => r.copyWith(lengthFt: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DimField(
                    label: 'Width (ft)',
                    value: room.widthFt,
                    onChanged: (v) => onChanged((r) => r.copyWith(widthFt: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DimField(
                    label: 'Height (ft)',
                    value: room.heightFt,
                    onChanged: (v) => onChanged((r) => r.copyWith(heightFt: v)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DimField extends StatelessWidget {
  const _DimField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value > 0 ? _format(value) : '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (text) => onChanged(double.tryParse(text.trim()) ?? 0),
      style: PaintEstimateTheme.monoStyle(size: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  String _format(double v) {
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }
}
