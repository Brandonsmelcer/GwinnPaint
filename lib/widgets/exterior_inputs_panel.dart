import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exterior_estimate_models.dart';
import '../theme/paint_estimate_theme.dart';

/// Exterior job inputs: surfaces, sq ft, paint/stain, and rates.
class ExteriorInputsPanel extends StatelessWidget {
  const ExteriorInputsPanel({
    super.key,
    required this.laborController,
    required this.linFtLaborController,
    required this.paintPriceController,
    required this.stainPriceController,
    required this.lines,
    required this.formGeneration,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onUpdateLine,
  });

  final TextEditingController laborController;
  final TextEditingController linFtLaborController;
  final TextEditingController paintPriceController;
  final TextEditingController stainPriceController;
  final List<ExteriorJobLine> lines;
  final int formGeneration;
  final VoidCallback onAddLine;
  final ValueChanged<String> onRemoveLine;
  final void Function(String id, ExteriorJobLine Function(ExteriorJobLine) updater)
      onUpdateLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          title: 'Rates',
          subtitle: 'Labor and material prices used for every exterior surface.',
          child: Column(
            children: [
              _NumberField(
                controller: laborController,
                label: 'Labor Price per Sq Ft',
                hint: 'e.g. 2.50',
                prefix: '\$',
              ),
              const SizedBox(height: 14),
              _NumberField(
                controller: linFtLaborController,
                label: 'Labor Price per Linear Ft',
                hint: 'e.g. 6.00',
                prefix: '\$',
              ),
              const SizedBox(height: 14),
              _NumberField(
                controller: paintPriceController,
                label: 'Paint Price per Gallon',
                hint: 'Default 45',
                prefix: '\$',
              ),
              const SizedBox(height: 14),
              _NumberField(
                controller: stainPriceController,
                label: 'Stain Price per Gallon',
                hint: 'Default 55',
                prefix: '\$',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Card(
          title: 'Exterior Surfaces',
          subtitle:
              'Name the job, enter sq ft or linear ft, then add railings if needed.',
          trailing: _AddButton(onPressed: onAddLine),
          child: Column(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                ExteriorLineEditor(
                  key: ValueKey('${lines[i].id}-$formGeneration'),
                  line: lines[i],
                  index: i,
                  canRemove: lines.length > 1,
                  onChanged: (updater) => onUpdateLine(lines[i].id, updater),
                  onRemove: () => onRemoveLine(lines[i].id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ExteriorLineEditor extends StatefulWidget {
  const ExteriorLineEditor({
    super.key,
    required this.line,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final ExteriorJobLine line;
  final int index;
  final bool canRemove;
  final ValueChanged<ExteriorJobLine Function(ExteriorJobLine)> onChanged;
  final VoidCallback onRemove;

  @override
  State<ExteriorLineEditor> createState() => _ExteriorLineEditorState();
}

class _ExteriorLineEditorState extends State<ExteriorLineEditor> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _sqFtController;
  late final TextEditingController _extraDescriptionController;
  late final TextEditingController _extraSqFtController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.line.description);
    _sqFtController = TextEditingController(text: widget.line.sqFt);
    _extraDescriptionController =
        TextEditingController(text: widget.line.extraDescription);
    _extraSqFtController = TextEditingController(text: widget.line.extraSqFt);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _sqFtController.dispose();
    _extraDescriptionController.dispose();
    _extraSqFtController.dispose();
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
                'Surface ${widget.index + 1}',
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
                  tooltip: 'Remove surface',
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('exterior-description'),
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) =>
                widget.onChanged((line) => line.copyWith(description: value)),
            style: PaintEstimateTheme.bodyStyle(),
            decoration: const InputDecoration(
              labelText: 'What is this estimate for?',
              hintText: 'Front deck, house siding, fence…',
            ),
          ),
          const SizedBox(height: 12),
          _MeasureRow(
            fieldKey: const Key('exterior-sqft'),
            toggleKeyPrefix: 'exterior-unit',
            controller: _sqFtController,
            unit: widget.line.unit,
            onUnitChanged: (unit) =>
                widget.onChanged((line) => line.copyWith(unit: unit)),
            onQuantityChanged: (value) =>
                widget.onChanged((line) => line.copyWith(sqFt: value)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('exterior-extra-description'),
            controller: _extraDescriptionController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) => widget.onChanged(
              (line) => line.copyWith(extraDescription: value),
            ),
            style: PaintEstimateTheme.bodyStyle(),
            decoration: const InputDecoration(
              labelText: 'Spindles, railings, extra',
              hintText: 'Spindles, railings, trim…',
            ),
          ),
          const SizedBox(height: 12),
          _MeasureRow(
            fieldKey: const Key('exterior-extra-sqft'),
            toggleKeyPrefix: 'exterior-extra-unit',
            controller: _extraSqFtController,
            unit: widget.line.extraUnit,
            onUnitChanged: (unit) =>
                widget.onChanged((line) => line.copyWith(extraUnit: unit)),
            onQuantityChanged: (value) =>
                widget.onChanged((line) => line.copyWith(extraSqFt: value)),
          ),
          const SizedBox(height: 12),
          Text(
            'Finish',
            style: PaintEstimateTheme.bodyStyle(weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          FinishToggle(
            value: widget.line.finish,
            onChanged: (finish) =>
                widget.onChanged((line) => line.copyWith(finish: finish)),
          ),
          const SizedBox(height: 6),
          Text(
            widget.line.finish.hint,
            style: PaintEstimateTheme.bodyStyle(
              size: 12,
              color: PaintEstimateTheme.charcoal.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Number of Coats',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: widget.line.coats,
                isExpanded: true,
                style: PaintEstimateTheme.monoStyle(size: 15),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Coat')),
                  DropdownMenuItem(value: 2, child: Text('2 Coats')),
                  DropdownMenuItem(value: 3, child: Text('3 Coats')),
                ],
                onChanged: (selected) {
                  if (selected != null) {
                    widget.onChanged((line) => line.copyWith(coats: selected));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MeasureToggle extends StatelessWidget {
  const MeasureToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.keyPrefix = 'exterior-unit',
  });

  final ExteriorMeasureUnit value;
  final ValueChanged<ExteriorMeasureUnit> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PaintEstimateTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaintEstimateTheme.charcoal.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          for (final unit in ExteriorMeasureUnit.values)
            Expanded(
              child: Material(
                color: value == unit
                    ? PaintEstimateTheme.warmGold
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: Key('$keyPrefix-${unit.name}'),
                  onTap: () => onChanged(unit),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      unit.label,
                      textAlign: TextAlign.center,
                      style: PaintEstimateTheme.bodyStyle(
                        size: 12,
                        weight: FontWeight.w700,
                        color: PaintEstimateTheme.midnightNavy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasureRow extends StatelessWidget {
  const _MeasureRow({
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    required this.onQuantityChanged,
    required this.fieldKey,
    required this.toggleKeyPrefix,
  });

  final TextEditingController controller;
  final ExteriorMeasureUnit unit;
  final ValueChanged<ExteriorMeasureUnit> onUnitChanged;
  final ValueChanged<String> onQuantityChanged;
  final Key fieldKey;
  final String toggleKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final isLinear = unit == ExteriorMeasureUnit.linearFeet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeasureToggle(
          value: unit,
          onChanged: onUnitChanged,
          keyPrefix: toggleKeyPrefix,
        ),
        const SizedBox(height: 10),
        _NumberField(
          fieldKey: fieldKey,
          controller: controller,
          label: isLinear ? 'Linear Footage' : 'Square Footage',
          hint: isLinear ? 'e.g. 40' : 'e.g. 400',
          suffix: unit.shortLabel,
          onChanged: onQuantityChanged,
        ),
      ],
    );
  }
}

class FinishToggle extends StatelessWidget {
  const FinishToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ExteriorFinish value;
  final ValueChanged<ExteriorFinish> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PaintEstimateTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PaintEstimateTheme.charcoal.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          for (final finish in ExteriorFinish.values)
            Expanded(
              child: Material(
                color: value == finish
                    ? PaintEstimateTheme.warmGold
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: Key('exterior-finish-${finish.name}'),
                  onTap: () => onChanged(finish),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      finish.label,
                      textAlign: TextAlign.center,
                      style: PaintEstimateTheme.bodyStyle(
                        weight: FontWeight.w700,
                        color: PaintEstimateTheme.midnightNavy,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

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
              const Icon(Icons.add, size: 16, color: PaintEstimateTheme.midnightNavy),
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: onChanged,
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
