import 'dart:math';
import 'package:flutter/material.dart';

enum CompanionExpression { neutral, encouraging, gentle, listening }

class CompanionWidget extends StatefulWidget {
  final CompanionExpression expression;
  final double size;

  const CompanionWidget({
    super.key,
    this.expression = CompanionExpression.neutral,
    this.size = 200.0,
  });

  @override
  State<CompanionWidget> createState() => _CompanionWidgetState();
}

class _CompanionWidgetState extends State<CompanionWidget> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _blinkController;
  late AnimationController _glowController;
  late AnimationController _mistController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _mistController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _blinkController.dispose();
    _glowController.dispose();
    _mistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatController,
          _blinkController,
          _glowController,
          _mistController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: _CompanionPainter(
              expression: widget.expression,
              floatValue: Curves.easeInOut.transform(_floatController.value),
              blinkValue: _blinkController.value,
              glowValue: Curves.easeInOut.transform(_glowController.value),
              mistValue: _mistController.value,
            ),
          );
        },
      ),
    );
  }
}

class _CompanionPainter extends CustomPainter {
  final CompanionExpression expression;
  final double floatValue;
  final double blinkValue;
  final double glowValue;
  final double mistValue;

  _CompanionPainter({
    required this.expression,
    required this.floatValue,
    required this.blinkValue,
    required this.glowValue,
    required this.mistValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Float offset
    final double floatOffset = (floatValue * 2 - 1) * 10.0;
    
    canvas.save();
    canvas.translate(0, floatOffset);

    // 1. Ambient Glow
    double glowIntensity = expression == CompanionExpression.listening ? 0.8 : 0.4;
    double glowRadius = (w * 0.45) + (glowValue * w * 0.05);
    final glowPaint = Paint()
      ..color = const Color(0xFFC7E1E7).withValues(alpha: glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.15);
    canvas.drawCircle(Offset(w / 2, h / 2), glowRadius, glowPaint);

    // 2. Mist particles
    _drawMistParticles(canvas, w, h);

    // 3. Cloud Body Silhouette
    final bodyPaint = Paint()..color = const Color(0xFF8FB9C4)..style = PaintingStyle.fill;
    final depthPaint = Paint()..color = const Color(0xFFC7E1E7).withValues(alpha: 0.55)..style = PaintingStyle.fill;
    final baseShadePaint = Paint()..color = const Color(0xFF6FA0AE).withValues(alpha: 0.35)..style = PaintingStyle.fill;

    Path cloudPath = _buildCloudPath(w, h);
    
    // Draw base shading first (slightly offset down)
    canvas.save();
    canvas.translate(0, h * 0.05);
    canvas.drawPath(cloudPath, baseShadePaint);
    canvas.restore();
    
    // Main body
    canvas.drawPath(cloudPath, bodyPaint);
    
    // Draw depth highlight (slightly offset up/left)
    canvas.save();
    canvas.translate(-w * 0.02, -h * 0.02);
    // Clip the highlight so it stays within the main cloud path bounds visually
    canvas.clipPath(cloudPath);
    canvas.drawPath(cloudPath, depthPaint);
    canvas.restore();

    // 4. Face
    _drawFace(canvas, w, h);

    canvas.restore();
  }

  void _drawMistParticles(Canvas canvas, double w, double h) {
    final particlePaint = Paint()
      ..color = const Color(0xFFC7E1E7).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      
    // 3 particles, staggered
    for (int i = 0; i < 3; i++) {
      double t = (mistValue + (i * 0.33)) % 1.0;
      double y = h * (0.8 - (t * 0.6));
      double x = w * 0.5 + sin((t + i) * pi * 4) * (w * 0.3);
      double opacity = sin(t * pi); // fade in and out
      
      particlePaint.color = const Color(0xFFC7E1E7).withValues(alpha: 0.4 * opacity);
      canvas.drawCircle(Offset(x, y), w * 0.04, particlePaint);
    }
  }

  Path _buildCloudPath(double w, double h) {
    final path = Path();
    
    // Central base ellipse (wide and flat-ish)
    final baseRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.65), 
      width: w * 0.85, 
      height: h * 0.45
    );
    path.addOval(baseRect);

    // Central large bump
    path.addOval(Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.45), 
      width: w * 0.55, 
      height: h * 0.55
    ));
    
    // Left medium bump
    path.addOval(Rect.fromCenter(
      center: Offset(w * 0.28, h * 0.55), 
      width: w * 0.35, 
      height: h * 0.35
    ));
    
    // Right medium bump
    path.addOval(Rect.fromCenter(
      center: Offset(w * 0.72, h * 0.55), 
      width: w * 0.35, 
      height: h * 0.35
    ));
    
    // Left small corner puff
    path.addOval(Rect.fromCenter(
      center: Offset(w * 0.15, h * 0.7), 
      width: w * 0.2, 
      height: h * 0.2
    ));
    
    // Right small corner puff
    path.addOval(Rect.fromCenter(
      center: Offset(w * 0.85, h * 0.7), 
      width: w * 0.2, 
      height: h * 0.2
    ));
    
    return path;
  }

  void _drawFace(Canvas canvas, double w, double h) {
    final cx = w / 2;
    final cy = h * 0.58; // Center of face
    
    // Blushes
    final blushPaint = Paint()..color = const Color(0xFFE6A48C).withValues(alpha: 0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - w * 0.18, cy + h * 0.06), width: w * 0.12, height: h * 0.06), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + w * 0.18, cy + h * 0.06), width: w * 0.12, height: h * 0.06), blushPaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1B2A41)..style = PaintingStyle.fill;
    final eyeHighlightPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    // Blink logic (quick close and reopen)
    bool isBlinking = blinkValue > 0.95; // blink at the end of the 4.5s cycle
    
    if (isBlinking) {
      // Draw closed eyes (horizontal lines)
      final closedEyePaint = Paint()
        ..color = const Color(0xFF1B2A41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - w * 0.15, cy - h * 0.02), Offset(cx - w * 0.07, cy - h * 0.02), closedEyePaint);
      canvas.drawLine(Offset(cx + w * 0.07, cy - h * 0.02), Offset(cx + w * 0.15, cy - h * 0.02), closedEyePaint);
    } else {
      if (expression == CompanionExpression.encouraging) {
        // Closed happy arcs
        final arcPaint = Paint()
          ..color = const Color(0xFF1B2A41)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
        Path leftArc = Path()..moveTo(cx - w * 0.15, cy)..quadraticBezierTo(cx - w * 0.11, cy - h * 0.04, cx - w * 0.07, cy);
        Path rightArc = Path()..moveTo(cx + w * 0.07, cy)..quadraticBezierTo(cx + w * 0.11, cy - h * 0.04, cx + w * 0.15, cy);
        canvas.drawPath(leftArc, arcPaint);
        canvas.drawPath(rightArc, arcPaint);
      } else {
        // Normal round eyes
        canvas.drawCircle(Offset(cx - w * 0.11, cy - h * 0.02), w * 0.035, eyePaint);
        canvas.drawCircle(Offset(cx + w * 0.11, cy - h * 0.02), w * 0.035, eyePaint);
        // Highlights
        canvas.drawCircle(Offset(cx - w * 0.12, cy - h * 0.03), w * 0.01, eyeHighlightPaint);
        canvas.drawCircle(Offset(cx + w * 0.10, cy - h * 0.03), w * 0.01, eyeHighlightPaint);
      }
    }

    // Brows for gentle
    if (expression == CompanionExpression.gentle && !isBlinking) {
      final browPaint = Paint()
        ..color = const Color(0xFF1B2A41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      Path leftBrow = Path()..moveTo(cx - w * 0.14, cy - h * 0.08)..quadraticBezierTo(cx - w * 0.11, cy - h * 0.09, cx - w * 0.08, cy - h * 0.07);
      Path rightBrow = Path()..moveTo(cx + w * 0.08, cy - h * 0.07)..quadraticBezierTo(cx + w * 0.11, cy - h * 0.09, cx + w * 0.14, cy - h * 0.08);
      canvas.drawPath(leftBrow, browPaint);
      canvas.drawPath(rightBrow, browPaint);
    }

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF1B2A41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
      
    Path mouthPath = Path();
    if (expression == CompanionExpression.encouraging) {
      // Curved up more
      mouthPath.moveTo(cx - w * 0.06, cy + h * 0.04);
      mouthPath.quadraticBezierTo(cx, cy + h * 0.09, cx + w * 0.06, cy + h * 0.04);
    } else {
      // Gentle curve (neutral, gentle, listening)
      mouthPath.moveTo(cx - w * 0.05, cy + h * 0.05);
      mouthPath.quadraticBezierTo(cx, cy + h * 0.07, cx + w * 0.05, cy + h * 0.05);
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _CompanionPainter oldDelegate) {
    return oldDelegate.expression != expression ||
           oldDelegate.floatValue != floatValue ||
           oldDelegate.blinkValue != blinkValue ||
           oldDelegate.glowValue != glowValue ||
           oldDelegate.mistValue != mistValue;
  }
}
