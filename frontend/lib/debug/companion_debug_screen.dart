import 'package:flutter/material.dart';
import 'package:smriti/widgets/companion_widget.dart';
import 'package:smriti/core/theme.dart';

class CompanionDebugScreen extends StatefulWidget {
  const CompanionDebugScreen({super.key});

  @override
  State<CompanionDebugScreen> createState() => _CompanionDebugScreenState();
}

class _CompanionDebugScreenState extends State<CompanionDebugScreen> {
  CompanionExpression _expression = CompanionExpression.neutral;

  void _cycleExpression() {
    setState(() {
      int nextIndex = (_expression.index + 1) % CompanionExpression.values.length;
      _expression = CompanionExpression.values[nextIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Companion Debug'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _cycleExpression,
              child: CompanionWidget(
                expression: _expression,
                size: 250,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Current State: ${_expression.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap the character to cycle states',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
