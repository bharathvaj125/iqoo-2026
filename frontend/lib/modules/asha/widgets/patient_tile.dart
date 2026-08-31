import 'package:flutter/material.dart';
import 'package:smriti/core/models/patient.dart';
import 'package:smriti/core/theme.dart';

class PatientTile extends StatelessWidget {
  final Patient patient;

  /// Passed in rather than read off the model: it's derived from session records, and a
  /// stored counter is one that eventually disagrees with the sessions it counts.
  final int missedSessionCount;
  final VoidCallback onTap;

  const PatientTile({
    super.key,
    required this.patient,
    required this.missedSessionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle();

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
          backgroundImage: patient.photoUrl != null ? NetworkImage(patient.photoUrl!) : null,
          child: patient.photoUrl == null
              ? Text(
                  patient.name.characters.first,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.accent),
                )
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                patient.name,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!patient.hasBaseline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'No baseline',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle.text,
            style: TextStyle(
              color: subtitle.emphasised ? AppTheme.danger : Colors.black54,
              fontWeight: subtitle.emphasised ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        isThreeLine: patient.trendFlag != null,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  ({String text, bool emphasised}) _subtitle() {
    if (patient.trendFlag != null) return (text: patient.trendFlag!, emphasised: true);
    if (missedSessionCount > 0) {
      return (
        text: '$missedSessionCount missed session${missedSessionCount == 1 ? '' : 's'}',
        emphasised: true,
      );
    }
    if (!patient.hasBaseline) return (text: 'Baseline not captured yet', emphasised: false);
    return (text: 'Tracking against her own baseline', emphasised: false);
  }
}
