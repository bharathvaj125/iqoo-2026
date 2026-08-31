import 'package:flutter/material.dart';
import 'package:smriti/auth/sign_in_screen.dart';
import 'package:smriti/core/auth_controller.dart';
import 'package:smriti/modules/asha/asha_home.dart';
import 'package:smriti/modules/caregiver/caregiver_home.dart';

/// The real ASHA/Caregiver entry point: restores a persisted session on
/// launch, then renders whichever screen matches [AuthController]'s state —
/// sign-in, the one-time role step, or straight into the right module home.
///
/// The Patient module never goes through this gate at all — it's reached
/// directly from the role picker with its existing no-login flow, per the
/// architecture (see main.dart).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    AuthController.instance.restore();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthController.instance,
      builder: (context, state, _) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.signedOut:
            return const SignInScreen();
          case AuthStatus.awaitingRole:
            return const RoleSelectStep();
          case AuthStatus.signedIn:
            return switch (state.role!) {
              AshaCaregiverRole.asha => const AshaHome(),
              AshaCaregiverRole.caregiver => const CaregiverHome(),
            };
        }
      },
    );
  }
}
