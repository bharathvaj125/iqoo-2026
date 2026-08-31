import 'package:flutter/foundation.dart';
import '../../../widgets/companion_widget.dart';

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
