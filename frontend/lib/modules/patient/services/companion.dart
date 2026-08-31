import 'companion_controller.dart';
import 'companion_brain.dart';
import 'tts_service.dart';

/// App-wide access point so any screen (Home, Game, Reminders) can
/// make the companion react and speak without threading a controller
/// through every widget. The [controller] is a ChangeNotifier — any
/// visible CompanionCharacter widget listening to it repaints live.
class Companion {
  Companion._internal();
  static final Companion instance = Companion._internal();

  final CompanionController controller = CompanionController();

  Future<void> say(String situationKey) async {
    final reply = CompanionBrain.forSituation(situationKey);
    controller.setExpression(reply.expression);
    await TtsService.instance.speak(reply.text, controller);
  }

  Future<void> sayFreeText(String text) async {
    final reply = CompanionBrain.forFreeText(text);
    controller.setExpression(reply.expression);
    await TtsService.instance.speak(reply.text, controller);
  }

  Future<void> sayCustom(String text, CompanionExpression expression) async {
    controller.setExpression(expression);
    await TtsService.instance.speak(text, controller);
  }
}
