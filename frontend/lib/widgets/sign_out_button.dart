import 'package:flutter/material.dart';
import 'package:smriti/auth/auth_gate.dart';
import 'package:smriti/core/auth_controller.dart';

/// Drop into any ASHA/Caregiver top-level panel's AppBar actions. Confirms
/// before signing out, then hands control back to [AuthGate] (which is
/// listening to [AuthController] and will swap back to the sign-in screen) —
/// pops every route on top of it first so a signed-out session can't be
/// reached again via the back button.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthController.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: 'Sign out',
      onPressed: () => _confirmAndSignOut(context),
    );
  }
}
