import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smriti/core/models/alert.dart';
import 'package:smriti/core/theme.dart';

class AlertTile extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback onReviewed;

  const AlertTile({super.key, required this.alert, required this.onReviewed});

  @override
  Widget build(BuildContext context) {
    final color = alert.reviewed ? Colors.black45 : AppTheme.danger;

    return Card(
      color: alert.reviewed ? null : AppTheme.danger.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(alert.reviewed ? Icons.flag_outlined : Icons.flag_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(alert.message, style: TextStyle(color: alert.reviewed ? Colors.black54 : null)),
                  const SizedBox(height: 8),
                  Text(
                    'A change from her own usual pattern, routed to her ASHA. Not a diagnosis.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat.yMMMd().add_jm().format(alert.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            if (!alert.reviewed)
              TextButton(onPressed: onReviewed, child: const Text('Mark reviewed'))
            else
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
