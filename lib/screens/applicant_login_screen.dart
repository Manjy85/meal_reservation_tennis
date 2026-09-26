import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/account_dialogs.dart';
import '../widgets/common.dart';
import 'applicant_home_screen.dart';
import 'applicant_identification_screen.dart';

final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

/// Client app start screen (when no session is active).
class ApplicantLoginScreen extends StatefulWidget {
  const ApplicantLoginScreen({super.key});

  @override
  State<ApplicantLoginScreen> createState() => _ApplicantLoginScreenState();
}

class _ApplicantLoginScreenState extends State<ApplicantLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() => _emailError = 'Email requis');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Email invalide');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Mot de passe requis');
      return;
    }

    setState(() => _submitting = true);
    try {
      await MealReservationStore.signIn(email, password);
    } on StoreAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _passwordError = e.message;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantHomeScreen()),
      (route) => false,
    );
  }

  Future<void> _forgotPassword() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => ResetPasswordDialog(initialEmail: _emailController.text.trim()),
    );
    if (sent != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Si un compte existe pour cette adresse, un e-mail de réinitialisation vient d’être envoyé.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppBrandHeader(
                      title: 'Bon retour !',
                      subtitle: 'Connecte-toi pour réserver ton repas et suivre tes commandes.',
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      controller: _emailController,
                      label: 'Adresse e-mail',
                      hint: 'nom@domaine.fr',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      errorText: _passwordError,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppPrimaryButton(
                      label: 'Se connecter',
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Pas encore de compte ?'),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ApplicantIdentificationScreen()),
                          ),
                          child: const Text('Créer un compte'),
                        ),
                      ],
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
