import 'package:flutter/material.dart';

import '../models/exterior_estimate_models.dart';
import '../theme/paint_estimate_theme.dart';

/// Interior / Exterior job switcher for the calculator.
class JobKindToggle extends StatelessWidget {
  const JobKindToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EstimateJobKind value;
  final ValueChanged<EstimateJobKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PaintEstimateTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: PaintEstimateTheme.midnightNavy.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          for (final kind in EstimateJobKind.values)
            Expanded(
              child: _ToggleTab(
                label: kind.label,
                icon: kind == EstimateJobKind.interior
                    ? Icons.home_outlined
                    : Icons.deck_outlined,
                selected: value == kind,
                onTap: () => onChanged(kind),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PaintEstimateTheme.midnightNavy : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? PaintEstimateTheme.warmGold
                    : PaintEstimateTheme.charcoal.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: PaintEstimateTheme.bodyStyle(
                  weight: FontWeight.w700,
                  color: selected
                      ? PaintEstimateTheme.white
                      : PaintEstimateTheme.charcoal.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
