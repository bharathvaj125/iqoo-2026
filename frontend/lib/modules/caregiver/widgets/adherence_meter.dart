import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';

class AdherenceMeter extends StatelessWidget {
  final double rate;

  const AdherenceMeter({super.key, required this.rate});

  Color get _color {
    if (rate >= 0.8) return AppTheme.primary;
    if (rate >= 0.5) return AppTheme.accent;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: _color.withValues(alpha: 0.15),
              color: _color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${(rate * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w700, color: _color)),
      ],
    );
  }
}
