import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/paint_estimate_models.dart';
import '../models/room_dimension.dart';
import '../models/saved_estimate_record.dart';
import '../screens/saved_estimates_screen.dart';
import '../services/estimate_export_service.dart';
import '../services/estimate_storage_service.dart';
import '../theme/paint_estimate_theme.dart';
import '../widgets/floor_plan_assistant.dart';

/// Premium, responsive Paint Estimate Calculator with invoice-style output.
class PaintEstimateCalculatorScreen extends StatefulWidget {
  const PaintEstimateCalculatorScreen({super.key, this.initialRecord});

  final SavedEstimateRecord? initialRecord;

  @override
  State<PaintEstimateCalculatorScreen> createState() =>
      _PaintEstimateCalculatorScreenState();
}

class _PaintEstimateCalculatorScreenState
    extends State<PaintEstimateCalculatorScreen> {
  final _wallSqFtController = TextEditingController();
  final _pricePerSqFtController = TextEditingController();
  final _pricePerGallonController = TextEditingController(text: '45');

  int _coats = 2;
  int _doors = 0;
  int _windows = 0;
  bool _includeDoorsWindows = false;

  final List<ColorLog> _colorLogs = [
    ColorLog(id: '0'),
  ];

  final List<RoomDimension> _roomDimensions = [
    RoomDimension(id: '0'),
  ];

  String? _blueprintFileName;
  String? _blueprintBase64;

  int _nextColorLogId = 1;
  int _formGeneration = 0;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _wallSqFtController,
      _pricePerSqFtController,
      _pricePerGallonController,
    ]) {
      controller.addListener(_onInputsChanged);
    }
    if (widget.initialRecord != null) {
      _loadFromRecord(widget.initialRecord!);
    }
  }

  @override
  void dispose() {
    _wallSqFtController.dispose();
    _pricePerSqFtController.dispose();
    _pricePerGallonController.dispose();
    super.dispose();
  }

  void _onInputsChanged() => setState(() {});

  double _parseDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  EstimateBreakdown get _breakdown {
    return EstimateBreakdown.calculate(
      totalSqFt: _parseDouble(_wallSqFtController),
      pricePerSqFt: _parseDouble(_pricePerSqFtController),
      coats: _coats,
      doors: _doors,
      windows: _windows,
      includeDoorsWindows: _includeDoorsWindows,
      pricePerGallon: _parseDouble(_pricePerGallonController).clamp(0, double.infinity),
    );
  }

  List<ColorLog> get _visibleColorLogs =>
      _colorLogs.where((log) => !log.isEmpty).toList(growable: false);

  void _addColorLog() {
    setState(() {
      _colorLogs.add(ColorLog(id: '${_nextColorLogId++}'));
    });
  }

  void _removeColorLog(String id) {
    setState(() {
      _colorLogs.removeWhere((log) => log.id == id);
      if (_colorLogs.isEmpty) {
        _colorLogs.add(ColorLog(id: '${_nextColorLogId++}'));
      }
    });
  }

  void _updateColorLog(String id, ColorLog Function(ColorLog) updater) {
    setState(() {
      final index = _colorLogs.indexWhere((log) => log.id == id);
      if (index != -1) {
        _colorLogs[index] = updater(_colorLogs[index]);
      }
    });
  }

  String _formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatNumber(double value, {int decimals = 1}) {
    return value.toStringAsFixed(decimals);
  }

  Future<void> _textEstimate() async {
    await EstimateExportService.shareTextEstimate(_breakdown);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Estimate copied — share via SMS or WhatsApp',
          style: PaintEstimateTheme.bodyStyle(color: PaintEstimateTheme.white),
        ),
        backgroundColor: PaintEstimateTheme.midnightNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    await EstimateExportService.downloadPdfProposal(
      breakdown: _breakdown,
      colorLogs: _visibleColorLogs,
    );
  }

  EstimateFormSnapshot _buildSnapshot() {
    return EstimateFormSnapshot(
      wallSqFt: _wallSqFtController.text.trim(),
      pricePerSqFt: _pricePerSqFtController.text.trim(),
      pricePerGallon: _pricePerGallonController.text.trim(),
      coats: _coats,
      doors: _doors,
      windows: _windows,
      includeDoorsWindows: _includeDoorsWindows,
      colorLogs: List<ColorLog>.from(_colorLogs),
      roomDimensions: List<RoomDimension>.from(_roomDimensions),
      totalEstimate: _breakdown.totalEstimate,
      blueprintFileName: _blueprintFileName,
      blueprintBase64: _blueprintBase64,
    );
  }

  void _loadFromRecord(SavedEstimateRecord record) {
    setState(() {
      _formGeneration++;
      _wallSqFtController.text = record.wallSqFt;
      _pricePerSqFtController.text = record.pricePerSqFt;
      _pricePerGallonController.text = record.pricePerGallon;
      _coats = record.coats;
      _doors = record.doors;
      _windows = record.windows;
      _includeDoorsWindows = record.includeDoorsWindows;

      _colorLogs
        ..clear()
        ..addAll(record.toColorLogs());
      if (_colorLogs.isEmpty) {
        _colorLogs.add(ColorLog(id: '0'));
      }
      _nextColorLogId = _colorLogs.length + 1;

      _roomDimensions
        ..clear()
        ..addAll(record.toRoomDimensions());
      if (_roomDimensions.isEmpty) {
        _roomDimensions.add(RoomDimension(id: '0'));
      }

      _blueprintFileName = record.blueprintFileName;
      _blueprintBase64 = record.blueprintBase64;
    });
  }

  Future<void> _saveEstimate() async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save Estimate', style: PaintEstimateTheme.titleStyle()),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Client Name',
            hintText: 'e.g. Johnson Residence',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final clientName = nameController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a client name',
            style: PaintEstimateTheme.bodyStyle(color: PaintEstimateTheme.white),
          ),
          backgroundColor: PaintEstimateTheme.midnightNavy,
        ),
      );
      return;
    }

    final record = _buildSnapshot().toRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientName: clientName,
      savedAt: DateTime.now(),
    );
    await EstimateStorageService.save(record);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Estimate saved for $clientName',
          style: PaintEstimateTheme.bodyStyle(color: PaintEstimateTheme.white),
        ),
        backgroundColor: PaintEstimateTheme.midnightNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openSavedEstimates() async {
    final record = await Navigator.push<SavedEstimateRecord>(
      context,
      MaterialPageRoute(builder: (_) => const SavedEstimatesScreen()),
    );
    if (record != null) {
      _loadFromRecord(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loaded estimate for ${record.clientName}',
            style: PaintEstimateTheme.bodyStyle(color: PaintEstimateTheme.white),
          ),
          backgroundColor: PaintEstimateTheme.midnightNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _applyRoomTotal(double totalSqFt) {
    _wallSqFtController.text = totalSqFt.toStringAsFixed(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied ${totalSqFt.toStringAsFixed(0)} sq ft to Wall Sq Ft',
          style: PaintEstimateTheme.bodyStyle(color: PaintEstimateTheme.white),
        ),
        backgroundColor: PaintEstimateTheme.midnightNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _breakdown;
    const wideBreakpoint = 900.0;

    return Scaffold(
      backgroundColor: PaintEstimateTheme.background,
      body: Column(
        children: [
          _BrandAppBar(
            onSave: _saveEstimate,
            onOpenSaved: _openSavedEstimates,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= wideBreakpoint;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        sliver: SliverToBoxAdapter(
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _InputsPanel(
                                        wallSqFtController: _wallSqFtController,
                                        pricePerSqFtController: _pricePerSqFtController,
                                        pricePerGallonController: _pricePerGallonController,
                                        coats: _coats,
                                        doors: _doors,
                                        windows: _windows,
                                        includeDoorsWindows: _includeDoorsWindows,
                                        colorLogs: _colorLogs,
                                        roomDimensions: _roomDimensions,
                                        blueprintFileName: _blueprintFileName,
                                        blueprintBase64: _blueprintBase64,
                                        onCoatsChanged: (value) =>
                                            setState(() => _coats = value),
                                        onDoorsChanged: (value) =>
                                            setState(() => _doors = value),
                                        onWindowsChanged: (value) =>
                                            setState(() => _windows = value),
                                        onIncludeDoorsWindowsChanged: (value) =>
                                            setState(() => _includeDoorsWindows = value),
                                        onAddColorLog: _addColorLog,
                                        onRemoveColorLog: _removeColorLog,
                                        onUpdateColorLog: _updateColorLog,
                                        onRoomsChanged: (rooms) =>
                                            setState(() => _roomDimensions
                                              ..clear()
                                              ..addAll(rooms)),
                                        onBlueprintChanged: (fileName, base64, _) =>
                                            setState(() {
                                              _blueprintFileName = fileName;
                                              _blueprintBase64 = base64;
                                            }),
                                        onApplyRoomTotal: _applyRoomTotal,
                                        formGeneration: _formGeneration,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _InvoicePanel(
                                        breakdown: breakdown,
                                        colorLogs: _visibleColorLogs,
                                        formatCurrency: _formatCurrency,
                                        formatNumber: _formatNumber,
                                        onTextEstimate: _textEstimate,
                                        onDownloadPdf: _downloadPdf,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _InputsPanel(
                                      wallSqFtController: _wallSqFtController,
                                      pricePerSqFtController: _pricePerSqFtController,
                                      pricePerGallonController: _pricePerGallonController,
                                      coats: _coats,
                                      doors: _doors,
                                      windows: _windows,
                                      includeDoorsWindows: _includeDoorsWindows,
                                      colorLogs: _colorLogs,
                                      roomDimensions: _roomDimensions,
                                      blueprintFileName: _blueprintFileName,
                                      blueprintBase64: _blueprintBase64,
                                      onCoatsChanged: (value) =>
                                          setState(() => _coats = value),
                                      onDoorsChanged: (value) =>
                                          setState(() => _doors = value),
                                      onWindowsChanged: (value) =>
                                          setState(() => _windows = value),
                                      onIncludeDoorsWindowsChanged: (value) =>
                                          setState(() => _includeDoorsWindows = value),
                                      onAddColorLog: _addColorLog,
                                      onRemoveColorLog: _removeColorLog,
                                      onUpdateColorLog: _updateColorLog,
                                      onRoomsChanged: (rooms) =>
                                          setState(() => _roomDimensions
                                            ..clear()
                                            ..addAll(rooms)),
                                      onBlueprintChanged: (fileName, base64, _) =>
                                          setState(() {
                                            _blueprintFileName = fileName;
                                            _blueprintBase64 = base64;
                                          }),
                                      onApplyRoomTotal: _applyRoomTotal,
                                      formGeneration: _formGeneration,
                                    ),
                                    const SizedBox(height: 24),
                                    _InvoicePanel(
                                      breakdown: breakdown,
                                      colorLogs: _visibleColorLogs,
                                      formatCurrency: _formatCurrency,
                                      formatNumber: _formatNumber,
                                      onTextEstimate: _textEstimate,
                                      onDownloadPdf: _downloadPdf,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Brand App Bar ────────────────────────────────────────────────────────────

class _BrandAppBar extends StatelessWidget {
  const _BrandAppBar({
    required this.onSave,
    required this.onOpenSaved,
  });

  final VoidCallback onSave;
  final VoidCallback onOpenSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        12,
        20,
      ),
      decoration: const BoxDecoration(
        color: PaintEstimateTheme.midnightNavy,
        boxShadow: [
          BoxShadow(
            color: Color(0x330D2534),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GWINN', style: PaintEstimateTheme.brandTitleStyle(size: 26)),
                const SizedBox(height: 4),
                Container(
                  width: 56,
                  height: 1.5,
                  color: PaintEstimateTheme.warmGold,
                ),
                const SizedBox(height: 6),
                Text(
                  'PAINTING SOLUTIONS',
                  style: PaintEstimateTheme.brandSubtitleStyle(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpenSaved,
            icon: const Icon(Icons.history, color: PaintEstimateTheme.warmGold),
            tooltip: 'Saved Estimates',
          ),
          IconButton(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_add_outlined, color: PaintEstimateTheme.warmGold),
            tooltip: 'Save Estimate',
          ),
        ],
      ),
    );
  }
}

// ── Inputs panel ─────────────────────────────────────────────────────────────

class _InputsPanel extends StatelessWidget {
  const _InputsPanel({
    required this.wallSqFtController,
    required this.pricePerSqFtController,
    required this.pricePerGallonController,
    required this.coats,
    required this.doors,
    required this.windows,
    required this.includeDoorsWindows,
    required this.colorLogs,
    required this.roomDimensions,
    required this.blueprintFileName,
    required this.blueprintBase64,
    required this.onCoatsChanged,
    required this.onDoorsChanged,
    required this.onWindowsChanged,
    required this.onIncludeDoorsWindowsChanged,
    required this.onAddColorLog,
    required this.onRemoveColorLog,
    required this.onUpdateColorLog,
    required this.onRoomsChanged,
    required this.onBlueprintChanged,
    required this.onApplyRoomTotal,
    required this.formGeneration,
  });

  final TextEditingController wallSqFtController;
  final TextEditingController pricePerSqFtController;
  final TextEditingController pricePerGallonController;
  final int coats;
  final int doors;
  final int windows;
  final bool includeDoorsWindows;
  final List<ColorLog> colorLogs;
  final List<RoomDimension> roomDimensions;
  final String? blueprintFileName;
  final String? blueprintBase64;
  final ValueChanged<int> onCoatsChanged;
  final ValueChanged<int> onDoorsChanged;
  final ValueChanged<int> onWindowsChanged;
  final ValueChanged<bool> onIncludeDoorsWindowsChanged;
  final VoidCallback onAddColorLog;
  final ValueChanged<String> onRemoveColorLog;
  final void Function(String id, ColorLog Function(ColorLog) updater) onUpdateColorLog;
  final ValueChanged<List<RoomDimension>> onRoomsChanged;
  final void Function(String? fileName, String? base64, bool isPdf) onBlueprintChanged;
  final ValueChanged<double> onApplyRoomTotal;
  final int formGeneration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumCard(
          title: 'Base Metrics',
          child: Column(
            children: [
              _MetricField(
                controller: wallSqFtController,
                label: 'Wall Sq Ft',
                hint: 'e.g. 1200',
                suffix: 'sq ft',
              ),
              const SizedBox(height: 14),
              _MetricField(
                controller: pricePerSqFtController,
                label: 'Labor Price per Sq Ft',
                hint: 'e.g. 2.50',
                prefix: '\$',
              ),
              const SizedBox(height: 14),
              _MetricField(
                controller: pricePerGallonController,
                label: 'Material Price per Gallon',
                hint: 'Default 45',
                prefix: '\$',
              ),
              const SizedBox(height: 14),
              _CoatsDropdown(value: coats, onChanged: onCoatsChanged),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _PremiumCard(
          title: 'Floor Plan Assistant',
          subtitle: 'Import a blueprint and auto-calculate wall sq ft from room dimensions.',
          child: FloorPlanAssistant(
            key: ValueKey(formGeneration),
            rooms: roomDimensions,
            onRoomsChanged: onRoomsChanged,
            onApplyTotal: onApplyRoomTotal,
            blueprintFileName: blueprintFileName,
            blueprintBase64: blueprintBase64,
            onBlueprintChanged: onBlueprintChanged,
          ),
        ),
        const SizedBox(height: 20),
        _PremiumCard(
          title: 'Deductions',
          subtitle: includeDoorsWindows
              ? 'Openings are subtracted and shown on the client invoice.'
              : 'Counters available for your notes — hidden from invoice when off.',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Include doors & windows',
                          style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          includeDoorsWindows
                              ? 'On — applies deductions and shows on estimate'
                              : 'Off — not sent on invoice / text / PDF',
                          style: PaintEstimateTheme.bodyStyle(
                            size: 12,
                            color: PaintEstimateTheme.charcoal.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: includeDoorsWindows,
                    activeThumbColor: PaintEstimateTheme.midnightNavy,
                    activeTrackColor: PaintEstimateTheme.warmGold,
                    onChanged: onIncludeDoorsWindowsChanged,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Opacity(
                opacity: includeDoorsWindows ? 1 : 0.55,
                child: Row(
                  children: [
                    Expanded(
                      child: _CounterField(
                        label: 'Doors',
                        value: doors,
                        onChanged: onDoorsChanged,
                        deductionNote: '−20 sq ft each',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CounterField(
                        label: 'Windows',
                        value: windows,
                        onChanged: onWindowsChanged,
                        deductionNote: '−15 sq ft each',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _PremiumCard(
          title: 'Color Selection',
          subtitle: 'Log room colors for the client invoice.',
          trailing: _AddLogButton(onPressed: onAddColorLog),
          child: Column(
            children: [
              for (var i = 0; i < colorLogs.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _ColorLogEditor(
                  log: colorLogs[i],
                  index: i,
                  canRemove: colorLogs.length > 1,
                  onChanged: (updater) => onUpdateColorLog(colorLogs[i].id, updater),
                  onRemove: () => onRemoveColorLog(colorLogs[i].id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Invoice panel ────────────────────────────────────────────────────────────

class _InvoicePanel extends StatelessWidget {
  const _InvoicePanel({
    required this.breakdown,
    required this.colorLogs,
    required this.formatCurrency,
    required this.formatNumber,
    required this.onTextEstimate,
    required this.onDownloadPdf,
  });

  final EstimateBreakdown breakdown;
  final List<ColorLog> colorLogs;
  final String Function(double) formatCurrency;
  final String Function(double, {int decimals}) formatNumber;
  final VoidCallback onTextEstimate;
  final VoidCallback onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PaintEstimateTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: PaintEstimateTheme.navyHeaderDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATE SUMMARY',
                        style: PaintEstimateTheme.titleStyle(
                          size: 16,
                          color: PaintEstimateTheme.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live preview · updates as you type',
                        style: PaintEstimateTheme.bodyStyle(
                          size: 12,
                          color: PaintEstimateTheme.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: PaintEstimateTheme.warmGold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'DRAFT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: PaintEstimateTheme.midnightNavy,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InvoiceSectionTitle('Area Calculation'),
                _InvoiceRow(
                  label: 'Total Wall Area',
                  value: '${formatNumber(breakdown.totalSqFt, decimals: 0)} sq ft',
                ),
                if (breakdown.includeDoorsWindows) ...[
                  _InvoiceRow(
                    label: 'Door Deductions (${breakdown.doors} × 20)',
                    value: '−${formatNumber(breakdown.doors * 20.0, decimals: 0)} sq ft',
                    muted: true,
                  ),
                  _InvoiceRow(
                    label: 'Window Deductions (${breakdown.windows} × 15)',
                    value: '−${formatNumber(breakdown.windows * 15.0, decimals: 0)} sq ft',
                    muted: true,
                  ),
                  const _InvoiceDivider(),
                ],
                _InvoiceRow(
                  label: 'Net Paintable Area',
                  value: '${formatNumber(breakdown.netSqFt, decimals: 0)} sq ft',
                  emphasized: true,
                ),

                const SizedBox(height: 20),
                _InvoiceSectionTitle('Material'),
                _InvoiceRow(
                  label: 'Coats Applied',
                  value: '${breakdown.coats}',
                ),
                _InvoiceRow(
                  label: 'Raw Gallons (Net × Coats ÷ 350)',
                  value: formatNumber(breakdown.rawGallons, decimals: 2),
                ),
                _InvoiceRow(
                  label: 'Gallons Required (rounded up)',
                  value: '${breakdown.totalGallons} gal',
                  emphasized: true,
                ),
                _InvoiceRow(
                  label: 'Material @ ${formatCurrency(breakdown.pricePerGallon)}/gal',
                  value: formatCurrency(breakdown.materialCost),
                ),

                const SizedBox(height: 20),
                _InvoiceSectionTitle('Labor'),
                _InvoiceRow(
                  label: 'Net Area × Labor Rate',
                  value: formatCurrency(breakdown.laborCost),
                ),

                if (colorLogs.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _InvoiceSectionTitle('Color Log'),
                  const SizedBox(height: 8),
                  ...colorLogs.map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ColorLogInvoiceItem(log: log),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const _InvoiceDivider(thick: true),
                _InvoiceRow(
                  label: 'TOTAL ESTIMATE',
                  value: formatCurrency(breakdown.totalEstimate),
                  isTotal: true,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTextEstimate,
                    icon: const Icon(Icons.sms_outlined, size: 18),
                    label: const Text('Text Estimate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDownloadPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Download PDF Proposal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PaintEstimateTheme.warmGold,
                      foregroundColor: PaintEstimateTheme.midnightNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PaintEstimateTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Disclaimer: Digital screen color approximations vary. '
              'Always verify final selections using physical manufacturer swatches '
              'under site-specific lighting before ordering paint.',
              style: PaintEstimateTheme.bodyStyle(
                size: 11,
                color: PaintEstimateTheme.charcoal.withValues(alpha: 0.78),
              ).copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable building blocks ─────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PaintEstimateTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: PaintEstimateTheme.white,
              border: Border(
                bottom: BorderSide(
                  color: PaintEstimateTheme.charcoal.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: PaintEstimateTheme.titleStyle(size: 16)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: PaintEstimateTheme.bodyStyle(
                            size: 12,
                            color: PaintEstimateTheme.charcoal.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.controller,
    required this.label,
    this.hint,
    this.prefix,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefix;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: PaintEstimateTheme.monoStyle(size: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        suffixStyle: PaintEstimateTheme.bodyStyle(size: 12),
      ),
    );
  }
}

class _CoatsDropdown extends StatelessWidget {
  const _CoatsDropdown({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Number of Coats',
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          style: PaintEstimateTheme.monoStyle(size: 15),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 Coat')),
            DropdownMenuItem(value: 2, child: Text('2 Coats')),
            DropdownMenuItem(value: 3, child: Text('3 Coats')),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.deductionNote,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String deductionNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: PaintEstimateTheme.charcoal.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(10),
            color: PaintEstimateTheme.white,
          ),
          child: Row(
            children: [
              _CounterButton(
                icon: Icons.remove,
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(
                        color: PaintEstimateTheme.charcoal.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Text(
                    '$value',
                    style: PaintEstimateTheme.monoStyle(size: 18),
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          deductionNote,
          style: PaintEstimateTheme.bodyStyle(
            size: 11,
            color: PaintEstimateTheme.charcoal.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null
                ? PaintEstimateTheme.midnightNavy
                : PaintEstimateTheme.charcoal.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _AddLogButton extends StatelessWidget {
  const _AddLogButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PaintEstimateTheme.warmGold,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: PaintEstimateTheme.midnightNavy),
              const SizedBox(width: 4),
              Text(
                'Add',
                style: PaintEstimateTheme.bodyStyle(
                  size: 12,
                  color: PaintEstimateTheme.midnightNavy,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorLogEditor extends StatefulWidget {
  const _ColorLogEditor({
    required this.log,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final ColorLog log;
  final int index;
  final bool canRemove;
  final ValueChanged<ColorLog Function(ColorLog)> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ColorLogEditor> createState() => _ColorLogEditorState();
}

class _ColorLogEditorState extends State<_ColorLogEditor> {
  late final TextEditingController _roomController;
  late final TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController(text: widget.log.roomName);
    _colorController = TextEditingController(text: widget.log.colorName);
  }

  @override
  void dispose() {
    _roomController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                'Log ${widget.index + 1}',
                style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700),
              ),
              const Spacer(),
              if (widget.canRemove)
                IconButton(
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close, size: 18),
                  color: PaintEstimateTheme.charcoal,
                  tooltip: 'Remove color log',
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _roomController,
            onChanged: (value) =>
                widget.onChanged((l) => l.copyWith(roomName: value)),
            style: PaintEstimateTheme.bodyStyle(),
            decoration: const InputDecoration(
              labelText: 'Room Name',
              hintText: 'Master Bedroom',
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Paint Brand',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PaintBrand>(
                value: widget.log.brand,
                isExpanded: true,
                style: PaintEstimateTheme.bodyStyle(),
                items: PaintBrand.values
                    .map(
                      (brand) => DropdownMenuItem(
                        value: brand,
                        child: Text(brand.label),
                      ),
                    )
                    .toList(),
                onChanged: (selected) {
                  if (selected != null) {
                    widget.onChanged((l) => l.copyWith(brand: selected));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _colorController,
            onChanged: (value) =>
                widget.onChanged((l) => l.copyWith(colorName: value)),
            style: PaintEstimateTheme.bodyStyle(),
            decoration: const InputDecoration(
              labelText: 'Color Name / Code',
              hintText: 'Alabaster SW 7008',
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorLogInvoiceItem extends StatelessWidget {
  const _ColorLogInvoiceItem({required this.log});

  final ColorLog log;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PaintEstimateTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: PaintEstimateTheme.warmGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.roomName.trim().isEmpty ? 'Unnamed Room' : log.roomName.trim(),
                  style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  log.colorName.trim().isEmpty ? '—' : log.colorName.trim(),
                  style: PaintEstimateTheme.monoStyle(size: 12),
                ),
              ],
            ),
          ),
          Text(
            log.brand.label,
            style: PaintEstimateTheme.bodyStyle(
              size: 11,
              color: PaintEstimateTheme.charcoal.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSectionTitle extends StatelessWidget {
  const _InvoiceSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: PaintEstimateTheme.warmGold,
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.label,
    required this.value,
    this.muted = false,
    this.emphasized = false,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool emphasized;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final labelStyle = PaintEstimateTheme.bodyStyle(
      size: isTotal ? 15 : 13,
      weight: isTotal || emphasized ? FontWeight.w700 : FontWeight.w500,
      color: muted
          ? PaintEstimateTheme.charcoal.withValues(alpha: 0.55)
          : PaintEstimateTheme.charcoal,
    );

    final valueStyle = PaintEstimateTheme.monoStyle(
      size: isTotal ? 20 : emphasized ? 14 : 13,
      weight: isTotal ? FontWeight.w700 : FontWeight.w600,
      color: isTotal ? PaintEstimateTheme.warmGold : PaintEstimateTheme.charcoal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Text(value, style: valueStyle, textAlign: TextAlign.right),
        ],
      ),
    );
  }
}

class _InvoiceDivider extends StatelessWidget {
  const _InvoiceDivider({this.thick = false});

  final bool thick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: thick ? 2 : 1,
        decoration: BoxDecoration(
          color: thick
              ? PaintEstimateTheme.warmGold.withValues(alpha: 0.5)
              : PaintEstimateTheme.charcoal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
