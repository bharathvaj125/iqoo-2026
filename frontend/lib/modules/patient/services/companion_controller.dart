import 'package:flutter/foundation.dart';
import '../../../widgets/companion_widget.dart';

// Re-exported: CompanionExpression used to be defined directly in this file,
// so every screen/service that does `import 'companion_controller.dart'`
// still expects to find it here after the enum moved to CompanionWidget's
// file. Without this export, companion_brain.dart and daily_living_card.dart
// (which only import this file, not companion_widget.dart directly) fail to
// compile — Dart imports aren't transitive.
export '../../../widgets/companion_widget.dart' show CompanionExpression;

/// Central state for the companion character. A single instance is
/// shared app-wide (see [Companion] singleton) so any screen —
/// Home, the Game screen, the dedicated chat screen — can make the
/// character react, and any visible [CompanionWidget] will
/// repaint immediately via ChangeNotifier.
class CompanionController extends ChangeNotifier {
  CompanionExpression expression = CompanionExpression.neutral;

  void setExpression(CompanionExpression exp, {bool triggerWave = false, bool triggerArmsUp = false}) {
    expression = exp;
    notifyListeners();
  }
}
