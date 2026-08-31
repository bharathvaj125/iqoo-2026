import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/widgets/companion_widget.dart';

/// A slim, static companion strip for the ASHA and Caregiver module homes —
/// visual brand consistency with the Patient module, which the companion
/// actually leads. Deliberately static: `CompanionExpression.neutral`, no
/// reactive wiring to app state (that's Patient-module-specific, see
/// CompanionWidget's own doc comment). Sits above each module's tab content,
/// not inside it, so it persists across tab switches without duplicating
/// itself in every panel screen.
class ModuleCompanionHeader extends StatelessWidget {
  final String label;

  const ModuleCompanionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const CompanionWidget(size: 40, expression: CompanionExpression.neutral),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
