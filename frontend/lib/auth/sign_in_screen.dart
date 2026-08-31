import 'package:flutter/material.dart';
import 'package:smriti/core/auth_controller.dart';
import 'package:smriti/core/theme.dart';

/// The real entry point for the ASHA and Caregiver modules: one email field,
/// no password. Find-or-create happens server-side (see backend
/// app/api/routes/auth.py) — this screen doesn't know or care whether the
/// address is new or returning.
///
/// A brand-new account has no role yet, so this screen also walks straight
/// into the one-time role-selection step in that case, without a separate
/// navigation — [AuthGate] (lib/auth/auth_gate.dart) is what decides whether
/// this screen or the role step is what's currently showing, by watching
/// [AuthController]'s state; this widget only needs to call [AuthController]
/// and report errors.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await AuthController.instance.login(_emailController.text.trim());
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
    // On success, AuthController's own state change is what moves the app
    // forward — AuthGate is listening and will swap this screen out.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Smriti', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text(
                      'For ASHA workers and caregivers',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                    const SizedBox(height: 40),
                    const Text('Email address', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !_submitting,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'you@example.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Enter your email address';
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "No password needed — we'll recognise your email next time too.",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time step for a brand-new account, shown by [AuthGate] instead of
/// [SignInScreen] once login succeeds with no role attached yet.
class RoleSelectStep extends StatefulWidget {
  const RoleSelectStep({super.key});

  @override
  State<RoleSelectStep> createState() => _RoleSelectStepState();
}

class _RoleSelectStepState extends State<RoleSelectStep> {
  bool _submitting = false;
  String? _error;

  Future<void> _choose(AshaCaregiverRole role) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await AuthController.instance.setRole(role);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('One last thing', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    "What's your role? This only needs to be set once.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      onPressed: _submitting ? null : () => _choose(AshaCaregiverRole.asha),
                      icon: const Icon(Icons.groups_rounded),
                      label: const Text('ASHA worker'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
                      onPressed: _submitting ? null : () => _choose(AshaCaregiverRole.caregiver),
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('Caregiver'),
                    ),
                  ),
                  if (_submitting) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
