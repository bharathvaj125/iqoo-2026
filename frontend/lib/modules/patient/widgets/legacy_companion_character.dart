import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/companion_controller.dart';

/// Renders and animates the companion character:
///   idle sway/breathing -> blinking -> head tilt -> expression ->
///   waving -> mouth-state lip sync while speaking.
///
/// All of it reacts live to a shared [CompanionController], so the
/// same character on different screens always reflects the same
/// emotional state.
class LegacyCompanionCharacter extends StatefulWidget {
  final CompanionController controller;
  final double size;
  const LegacyCompanionCharacter(
      {super.key, required this.controller, this.size = 240});

  @override
  State<LegacyCompanionCharacter> createState() => _CompanionCharacterState();
}

class _CompanionCharacterState extends State<LegacyCompanionCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _idle; // breathing / gentle sway
  late final Animation<double> _sway;
  late final AnimationController _waveAnim;
  bool _eyesClosed = false;
  Timer? _blinkTimer;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _sway = Tween<double>(begin: -0.04, end: 0.04)
        .animate(CurvedAnimation(parent: _idle, curve: Curves.easeInOut));

    _waveAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350))
      ..repeat(reverse: true);

    widget.controller.addListener(_onControllerChanged);
    _scheduleBlink();
  }

  void _onControllerChanged() => setState(() {});

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 2400 + _rand.nextInt(2600)), () async {
      if (!mounted) return;
      setState(() => _eyesClosed = true);
      await Future.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() => _eyesClosed = false);
      _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    _waveAnim.dispose();
    _blinkTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _waveAnim, widget.controller]),
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size * 1.15,
          child: CustomPaint(
            painter: _CompanionPainter(
              sway: _sway.value + widget.controller.headTilt,
              expression: widget.controller.expression,
              mouth: widget.controller.mouth,
              eyesClosed: _eyesClosed,
              wave: widget.controller.wave,
              waveTick: _waveAnim.value,
              armsUp: widget.controller.armsUp,
            ),
          ),
        );
      },
    );
  }
}

class _CompanionPainter extends CustomPainter {
  final double sway;
  final CompanionExpression expression;
  final MouthState mouth;
  final bool eyesClosed;
  final bool wave;
  final double waveTick;
  final bool armsUp;

  _CompanionPainter({
    required this.sway,
    required this.expression,
    required this.mouth,
    required this.eyesClosed,
    required this.wave,
    required this.waveTick,
    required this.armsUp,
  });

  static const Color skin = Color(0xFFDDA36B);
  static const Color skinShade = Color(0xFFC28A55);
  static const Color hair = Color(0xFF241712);
  static const Color shirt = Color(0xFFE8813A);
  static const Color shirtShade = Color(0xFFCF6E2C);
  static const Color scarfRed = Color(0xFFB5251F);
  static const Color scarfWhite = Color(0xFFFDF6EC);
  static const Color blush = Color(0xFFFF9E80);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    // Whole character sways gently from a pivot near the hips.
    canvas.translate(w / 2, h * 0.88);
    canvas.rotate(sway);
    canvas.translate(-w / 2, -h * 0.88);

    final headCenter = Offset(w / 2, h * 0.30);
    final headRadius = w * 0.26;
    final bodyTop = headCenter.dy + headRadius * 0.8;
    final bodyCenter = Offset(w / 2, bodyTop + h * 0.19);

    final skinPaint = Paint()..color = skin;
    final hairPaint = Paint()..color = hair;
    final shirtPaint = Paint()..color = shirt;
    final whitePaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = const Color(0xFF2A2A2A);
    final blushPaint = Paint()..color = blush.withOpacity(0.4);

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 4), width: w * 0.5, height: 12),
      Paint()..color = Colors.black.withOpacity(0.08),
    );

    // ---- Arms ----
    void drawArm(bool left) {
      canvas.save();
      final shoulder = Offset(
          bodyCenter.dx + (left ? -w * 0.22 : w * 0.22), bodyCenter.dy - h * 0.03);
      canvas.translate(shoulder.dx, shoulder.dy);

      double angle;
      if (armsUp) {
        angle = left ? -2.3 : (2.3 - pi);
      } else if (wave && !left) {
        // right arm waves side to side
        angle = -0.9 - (waveTick * 0.5);
      } else {
        angle = left ? 0.35 : -0.35;
      }
      canvas.rotate(angle);
      final armRect = Rect.fromLTWH(-7, 0, 14, 44);
      canvas.drawRRect(
          RRect.fromRectAndRadius(armRect, const Radius.circular(9)), skinPaint);
      // sleeve cap
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(-9, -4, 18, 18), const Radius.circular(9)),
          shirtPaint);
      canvas.restore();
    }

    drawArm(true);
    drawArm(false);

    // ---- Body ----
    final bodyRect =
        Rect.fromCenter(center: bodyCenter, width: w * 0.48, height: h * 0.32);
    canvas.drawRRect(
      RRect.fromRectAndCorners(bodyRect,
          topLeft: const Radius.circular(28),
          topRight: const Radius.circular(28),
          bottomLeft: const Radius.circular(38),
          bottomRight: const Radius.circular(38)),
      shirtPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(bodyRect.left, bodyRect.bottom - 12, bodyRect.width, 12),
      Paint()..color = shirtShade,
    );

    // ---- Gamosa-style scarf ----
    final scarfRect = Rect.fromCenter(
        center: Offset(bodyCenter.dx, bodyTop + 4), width: w * 0.5, height: 15);
    canvas.drawRRect(
        RRect.fromRectAndRadius(scarfRect, const Radius.circular(7)),
        Paint()..color = scarfWhite);
    for (int i = 0; i < 5; i++) {
      final stripeX = scarfRect.left + i * (scarfRect.width / 5);
      canvas.drawRect(
          Rect.fromLTWH(stripeX, scarfRect.top, scarfRect.width / 10, scarfRect.height),
          Paint()..color = scarfRed);
    }
    final tailPath = Path()
      ..moveTo(bodyCenter.dx - 9, scarfRect.bottom)
      ..lineTo(bodyCenter.dx + 5, scarfRect.bottom)
      ..lineTo(bodyCenter.dx - 2, scarfRect.bottom + 24)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = scarfRed);

    // ---- Head ----
    canvas.drawCircle(headCenter, headRadius, skinPaint);
    // subtle cheek shading for a rounder, semi-realistic look
    canvas.drawCircle(
        Offset(headCenter.dx, headCenter.dy + headRadius * 0.15),
        headRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.transparent, skinShade.withOpacity(0.25)],
            stops: const [0.7, 1.0],
          ).createShader(Rect.fromCircle(
              center: headCenter, radius: headRadius)));

    // Hair
    final hairPath = Path()
      ..moveTo(headCenter.dx - headRadius, headCenter.dy - headRadius * 0.05)
      ..arcTo(Rect.fromCircle(center: headCenter, radius: headRadius), 3.3, 2.7, false)
      ..lineTo(headCenter.dx + headRadius, headCenter.dy - headRadius * 0.05)
      ..quadraticBezierTo(headCenter.dx, headCenter.dy - headRadius * 0.8,
          headCenter.dx - headRadius, headCenter.dy - headRadius * 0.05)
      ..close();
    canvas.drawPath(hairPath, hairPaint);
    canvas.drawCircle(
        Offset(headCenter.dx - headRadius * 0.88, headCenter.dy),
        headRadius * 0.15, hairPaint);
    canvas.drawCircle(
        Offset(headCenter.dx + headRadius * 0.88, headCenter.dy),
        headRadius * 0.15, hairPaint);

    // Ears
    canvas.drawCircle(Offset(headCenter.dx - headRadius * 0.98, headCenter.dy + 6),
        headRadius * 0.16, skinPaint);
    canvas.drawCircle(Offset(headCenter.dx + headRadius * 0.98, headCenter.dy + 6),
        headRadius * 0.16, skinPaint);

    // ---- Eyebrows (expression-dependent) ----
    final browPaint = Paint()
      ..color = hair
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final browY = headCenter.dy - headRadius * 0.22;
    final browDx = headRadius * 0.42;

    double browLTilt = 0, browRTilt = 0, browLift = 0;
    switch (expression) {
      case CompanionExpression.thinking:
        browLTilt = -0.35;
        browRTilt = 0.05;
        browLift = -3;
        break;
      case CompanionExpression.excited:
      case CompanionExpression.happy:
      case CompanionExpression.celebrating:
        browLift = -4;
        break;
      case CompanionExpression.calm:
        browLift = 2;
        break;
      case CompanionExpression.encouraging:
      case CompanionExpression.neutral:
        break;
    }

    void drawBrow(double dx, double tilt) {
      canvas.save();
      final origin = Offset(headCenter.dx + dx, browY + browLift);
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(tilt);
      canvas.drawLine(const Offset(-9, 0), const Offset(9, 0), browPaint);
      canvas.restore();
    }

    drawBrow(-browDx, browLTilt);
    drawBrow(browDx, browRTilt);

    // ---- Eyes ----
    final eyeY = headCenter.dy + headRadius * 0.02;
    final eyeDx = headRadius * 0.42;
    final eyeRadius = headRadius * 0.2;
    final leftEye = Offset(headCenter.dx - eyeDx, eyeY);
    final rightEye = Offset(headCenter.dx + eyeDx, eyeY);

    void drawEye(Offset c) {
      if (eyesClosed) {
        final p = Paint()
          ..color = hair
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(c.dx - eyeRadius * 0.8, c.dy), Offset(c.dx + eyeRadius * 0.8, c.dy), p);
        return;
      }
      final openAmount = expression == CompanionExpression.calm ? 0.7 : 1.0;
      canvas.drawOval(
          Rect.fromCenter(
              center: c, width: eyeRadius * 2, height: eyeRadius * 2 * openAmount),
          whitePaint);
      canvas.drawCircle(c.translate(1, 1.5), eyeRadius * 0.58, darkPaint);
      canvas.drawCircle(c.translate(3.5, -2.5), eyeRadius * 0.16, whitePaint);
    }

    drawEye(leftEye);
    drawEye(rightEye);

    // ---- Blush ----
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(headCenter.dx - headRadius * 0.58, headCenter.dy + headRadius * 0.38),
            width: headRadius * 0.46,
            height: headRadius * 0.26),
        blushPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(headCenter.dx + headRadius * 0.58, headCenter.dy + headRadius * 0.38),
            width: headRadius * 0.46,
            height: headRadius * 0.26),
        blushPaint);

    // ---- Nose (tiny) ----
    canvas.drawCircle(
        Offset(headCenter.dx, headCenter.dy + headRadius * 0.22),
        2.4,
        Paint()..color = skinShade);

    // ---- Mouth (expression base shape + mouth-state override while speaking) ----
    final mouthCenter = Offset(headCenter.dx, headCenter.dy + headRadius * 0.5);
    _drawMouth(canvas, mouthCenter, headRadius);

    // ---- Celebration sparkles ----
    if (expression == CompanionExpression.celebrating) {
      final sparklePaint = Paint()..color = const Color(0xFFFFC107);
      for (final offset in [
        Offset(-headRadius * 1.3, -headRadius * 0.4),
        Offset(headRadius * 1.3, -headRadius * 0.6),
        Offset(0, -headRadius * 1.5),
      ]) {
        _drawStar(canvas, headCenter + offset, 7, sparklePaint);
      }
    }

    canvas.restore();
  }

  void _drawMouth(Canvas canvas, Offset center, double headRadius) {
    final mouthPaint = Paint()..color = const Color(0xFF7A3B2E);
    final linePaint = Paint()
      ..color = skinShade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    // While speaking, mouth-state drives the shape (simple lip sync).
    if (mouth != MouthState.closed) {
      double heightFactor;
      switch (mouth) {
        case MouthState.openSmall:
          heightFactor = 0.14;
          break;
        case MouthState.openMedium:
          heightFactor = 0.22;
          break;
        case MouthState.openLarge:
          heightFactor = 0.32;
          break;
        case MouthState.closed:
          heightFactor = 0;
          break;
      }
      final rect = Rect.fromCenter(
          center: center,
          width: headRadius * 0.4,
          height: headRadius * heightFactor);
      canvas.drawOval(rect, mouthPaint);
      // inner shading for a little depth
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(center.dx, center.dy + rect.height * 0.15),
              width: rect.width * 0.6,
              height: rect.height * 0.5),
          Paint()..color = const Color(0xFF4A211A));
      return;
    }

    // Not speaking: expression-driven smile curve.
    switch (expression) {
      case CompanionExpression.excited:
      case CompanionExpression.celebrating:
        final path = Path()
          ..moveTo(center.dx - headRadius * 0.24, center.dy - 2)
          ..quadraticBezierTo(center.dx, center.dy + headRadius * 0.32,
              center.dx + headRadius * 0.24, center.dy - 2)
          ..close();
        canvas.drawPath(path, mouthPaint);
        break;
      case CompanionExpression.happy:
        final path = Path()
          ..moveTo(center.dx - headRadius * 0.22, center.dy)
          ..quadraticBezierTo(
              center.dx, center.dy + headRadius * 0.22, center.dx + headRadius * 0.22, center.dy);
        canvas.drawPath(path, linePaint);
        break;
      case CompanionExpression.thinking:
        final path = Path()
          ..moveTo(center.dx - headRadius * 0.14, center.dy + 3)
          ..quadraticBezierTo(center.dx + headRadius * 0.05, center.dy - 3,
              center.dx + headRadius * 0.18, center.dy);
        canvas.drawPath(path, linePaint);
        break;
      case CompanionExpression.encouraging:
        final path = Path()
          ..moveTo(center.dx - headRadius * 0.18, center.dy + 2)
          ..quadraticBezierTo(
              center.dx, center.dy + headRadius * 0.14, center.dx + headRadius * 0.18, center.dy + 2);
        canvas.drawPath(path, linePaint);
        break;
      case CompanionExpression.calm:
        final path = Path()
          ..moveTo(center.dx - headRadius * 0.15, center.dy)
          ..quadraticBezierTo(
              center.dx, center.dy + headRadius * 0.1, center.dx + headRadius * 0.15, center.dy);
        canvas.drawPath(path, linePaint);
        break;
      case CompanionExpression.neutral:
        canvas.drawLine(Offset(center.dx - headRadius * 0.14, center.dy),
            Offset(center.dx + headRadius * 0.14, center.dy), linePaint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (pi / 2) * i;
      final outer = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      final innerAngle = angle + pi / 4;
      final inner = Offset(center.dx + (radius * 0.4) * cos(innerAngle),
          center.dy + (radius * 0.4) * sin(innerAngle));
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CompanionPainter oldDelegate) {
    return oldDelegate.sway != sway ||
        oldDelegate.expression != expression ||
        oldDelegate.mouth != mouth ||
        oldDelegate.eyesClosed != eyesClosed ||
        oldDelegate.wave != wave ||
        oldDelegate.waveTick != waveTick ||
        oldDelegate.armsUp != armsUp;
  }
}
