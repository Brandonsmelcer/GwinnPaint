import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/saved_estimate_record.dart';
import '../services/estimate_storage_service.dart';
import '../theme/paint_estimate_theme.dart';

/// Historical list of saved client estimates stored locally via Hive.
class SavedEstimatesScreen extends StatefulWidget {
  const SavedEstimatesScreen({super.key});

  @override
  State<SavedEstimatesScreen> createState() => _SavedEstimatesScreenState();
}

class _SavedEstimatesScreenState extends State<SavedEstimatesScreen> {
  List<SavedEstimateRecord> _estimates = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() => _estimates = EstimateStorageService.getAll());
  }

  Future<void> _confirmDelete(SavedEstimateRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Estimate?', style: PaintEstimateTheme.titleStyle()),
        content: Text(
          'Remove the estimate for ${record.clientName}? This cannot be undone.',
          style: PaintEstimateTheme.bodyStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: PaintEstimateTheme.bodyStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await EstimateStorageService.delete(record.id);
    _refresh();
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  String _formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaintEstimateTheme.background,
      body: Column(
        children: [
          _SavedEstimatesAppBar(onBack: () => Navigator.pop(context)),
          Expanded(
            child: _estimates.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: _estimates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = _estimates[index];
                      return _EstimateListTile(
                        record: record,
                        formattedDate: _formatDate(record.savedAt),
                        formattedTotal: _formatCurrency(record.totalEstimate),
                        onTap: () => Navigator.pop(context, record),
                        onDelete: () => _confirmDelete(record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SavedEstimatesAppBar extends StatelessWidget {
  const _SavedEstimatesAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        20,
        16,
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
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: PaintEstimateTheme.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Estimates',
                  style: PaintEstimateTheme.titleStyle(
                    size: 20,
                    color: PaintEstimateTheme.white,
                  ),
                ),
                Text(
                  'Tap an estimate to reload it',
                  style: PaintEstimateTheme.bodyStyle(
                    size: 12,
                    color: PaintEstimateTheme.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: PaintEstimateTheme.charcoal.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved estimates yet',
              style: PaintEstimateTheme.titleStyle(size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the save button on the calculator to store a client estimate here.',
              textAlign: TextAlign.center,
              style: PaintEstimateTheme.bodyStyle(
                color: PaintEstimateTheme.charcoal.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateListTile extends StatelessWidget {
  const _EstimateListTile({
    required this.record,
    required this.formattedDate,
    required this.formattedTotal,
    required this.onTap,
    required this.onDelete,
  });

  final SavedEstimateRecord record;
  final String formattedDate;
  final String formattedTotal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PaintEstimateTheme.cardRadius),
        child: Container(
          decoration: PaintEstimateTheme.cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PaintEstimateTheme.midnightNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  record.clientName.isNotEmpty
                      ? record.clientName[0].toUpperCase()
                      : '?',
                  style: PaintEstimateTheme.titleStyle(
                    size: 18,
                    color: PaintEstimateTheme.warmGold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.clientName.isEmpty ? 'Unnamed Client' : record.clientName,
                      style: PaintEstimateTheme.titleStyle(size: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: PaintEstimateTheme.bodyStyle(
                        size: 12,
                        color: PaintEstimateTheme.charcoal.withValues(alpha: 0.6),
                      ),
                    ),
                    if (record.wallSqFt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${record.wallSqFt} sq ft · ${record.coats} coat${record.coats == 1 ? '' : 's'}',
                        style: PaintEstimateTheme.monoStyle(size: 11),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedTotal,
                    style: PaintEstimateTheme.monoStyle(
                      size: 16,
                      color: PaintEstimateTheme.warmGold,
                      weight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: PaintEstimateTheme.charcoal.withValues(alpha: 0.45),
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
