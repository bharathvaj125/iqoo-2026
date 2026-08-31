import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../services/companion_controller.dart';
import 'legacy_companion_character.dart';

/// Kuzu 3D animated companion.
///
/// The bundled GLB contains separate 3D parts and named animation clips:
/// Idle, Blink, Talk, Wave, Happy, Thinking and Encourage.
///
/// On a platform where the 3D renderer cannot load, the previous Flutter
/// painter is used as a graceful fallback so the app still works.
class CompanionCharacter extends StatefulWidget {
  final CompanionController controller;
  final double size;

  const CompanionCharacter({
    super.key,
    required this.controller,
    this.size = 240,
  });

  @override
  State<CompanionCharacter> createState() => _CompanionCharacterState();
}

class _CompanionCharacterState extends State<CompanionCharacter> {
  late final Flutter3DController _modelController;
  String? _lastAnimation;
  Timer? _transientTimer;
  Timer? _blinkTimer;
  bool _useFallback = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _modelController = Flutter3DController();
    widget.controller.addListener(_syncCharacter);

    // flutter_3d_controller currently targets Android, iOS, macOS and web.
    // Keep the existing character for desktop targets it does not support.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      _useFallback = true;
    }
  }

  @override
  void didUpdateWidget(covariant CompanionCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncCharacter);
      widget.controller.addListener(_syncCharacter);
    }
  }

  void _syncCharacter() {
    if (!_modelLoaded || _useFallback) return;

    final desired = _desiredAnimation();
    if (desired == _lastAnimation) return;

    _lastAnimation = desired;
    _transientTimer?.cancel();

    if (desired == 'Talk') {
      _modelController.playAnimation(animationName: 'Talk');
      return;
    }

    if (desired == 'Wave') {
      _modelController.playAnimation(animationName: 'Wave', loopCount: 2);
      return;
    }

    if (desired == 'Happy') {
      _modelController.playAnimation(animationName: 'Happy', loopCount: 1);
      _transientTimer = Timer(const Duration(milliseconds: 1250), () {
        if (!mounted || !_modelLoaded || _useFallback) return;
        _lastAnimation = null;
        _modelController.playAnimation(animationName: 'Idle');
      });
      return;
    }

    if (desired == 'Encourage') {
      _modelController.playAnimation(animationName: 'Encourage', loopCount: 1);
      _transientTimer = Timer(const Duration(milliseconds: 1100), () {
        if (!mounted || !_modelLoaded || _useFallback) return;
        _lastAnimation = null;
        _modelController.playAnimation(animationName: 'Idle');
      });
      return;
    }

    // Thinking/Idle are intentionally looping states.
    _modelController.playAnimation(animationName: desired);
  }

  String _desiredAnimation() {
    final c = widget.controller;

    if (c.isSpeaking) return 'Talk';
    if (c.wave) return 'Wave';

    switch (c.expression) {
      case CompanionExpression.thinking:
        return 'Thinking';
      case CompanionExpression.excited:
      case CompanionExpression.celebrating:
      case CompanionExpression.happy:
        return 'Happy';
      case CompanionExpression.encouraging:
      case CompanionExpression.calm:
        return 'Encourage';
      case CompanionExpression.neutral:
        return 'Idle';
    }
  }

  void _onModelLoad(String modelAddress) async {
    if (!mounted) return;
    setState(() => _modelLoaded = true);

    try {
      final animations = await _modelController.getAvailableAnimations();
      debugPrint('Kuzu 3D animations: $animations');
    } catch (e) {
      debugPrint('Could not read Kuzu animation names: $e');
    }

    // Keep Kuzu framed as a friendly front-facing companion.
    //
    // This model is a single textured mesh (~1.9 units tall, centered near
    // the origin) rather than the old multi-part rig, so the target/radius
    // below are tuned to its bounding box instead of the previous rig's.
    // If Kuzu appears turned away from the camera on first run, that means
    // the exported mesh's forward axis is -Z instead of +Z for this
    // particular export -- flip `theta` from 0 to 180 below to fix it.
    try {
      _modelController.setCameraTarget(0, 0.5, 0);
      _modelController.setCameraOrbit(0, 82, 2.2);
    } catch (e) {
      debugPrint('Kuzu camera setup skipped: $e');
    }

    _lastAnimation = 'Idle';
    _modelController.playAnimation(animationName: 'Idle');
    _startBlinkLoop();
    _syncCharacter();
  }

  void _startBlinkLoop() {
    _blinkTimer?.cancel();

    Future<void> scheduleNext() async {
      final delay = Duration(milliseconds: 2200 + (DateTime.now().millisecond % 2400));
      await Future.delayed(delay);
      if (!mounted || !_modelLoaded || _useFallback) return;

      // Only interrupt the calm idle state with a short blink.
      if (!widget.controller.isSpeaking &&
          !widget.controller.wave &&
          widget.controller.expression == CompanionExpression.neutral) {
        _lastAnimation = 'Blink';
        _modelController.playAnimation(animationName: 'Blink', loopCount: 1);
        await Future.delayed(const Duration(milliseconds: 320));
        if (mounted && _modelLoaded && !_useFallback) {
          _lastAnimation = 'Idle';
          _modelController.playAnimation(animationName: 'Idle');
        }
      }

      scheduleNext();
    }

    scheduleNext();
  }

  void _onModelError(String error) {
    debugPrint('Kuzu 3D model failed to load: $error');
    if (!mounted) return;
    setState(() => _useFallback = true);
  }

  @override
  void dispose() {
    _transientTimer?.cancel();
    _blinkTimer?.cancel();
    widget.controller.removeListener(_syncCharacter);
    _modelController.stopAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return LegacyCompanionCharacter(
        controller: widget.controller,
        size: widget.size,
      );
    }

    final viewerSize = widget.size * 1.45;

    return SizedBox(
      width: viewerSize,
      height: viewerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: viewerSize * 0.86,
            height: viewerSize * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Flutter3DViewer(
            controller: _modelController,
            // Keep this as a Flutter asset path. On Web it is served from
            // the compiled assets directory after `flutter pub get`.
            src: 'assets/character/kuzu.glb',
            progressBarColor: Colors.transparent,
            enableTouch: false,
            activeGestureInterceptor: true,
            onLoad: _onModelLoad,
            onError: _onModelError,
            onProgress: (value) {
              debugPrint('Kuzu model loading: ${value.toStringAsFixed(2)}');
            },
          ),
          if (!_modelLoaded)
            const IgnorePointer(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
