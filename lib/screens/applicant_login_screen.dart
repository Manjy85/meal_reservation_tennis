import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_date_screen.dart';
import 'applicant_identification_screen.dart';
import 'restaurateur_login_screen.dart';

/// Port of MainActivity.java + MealReservationApplicantLoginActivity.kt
/// (both point at the same layout: meal_reservation_applicant_login.xml).
/// This is the app's home screen.
final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

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
    final password = _passwordController.text.trim();

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
    final valid = await MealReservationLocalStore.validateLogin(email, password);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!valid) {
      setState(() => _passwordError = 'Identifiants incorrects');
      return;
    }

    await MealReservationLocalStore.setCurrentAccountEmail(email);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ApplicantDateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: AppColors.amberHoney),
            tooltip: 'Acces mode restaurateur',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RestaurateurLoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Connectez-vous pour retrouver vos informations et continuer votre reservation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.amberHoney, fontSize: 15),
              ),
              const SizedBox(height: 18),
              const AppFieldLabel('Adresse e-mail'),
              AppTextField(
                controller: _emailController,
                hint: 'nom@domaine.fr',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 18),
              const AppFieldLabel('Mot de passe'),
              AppTextField(
                controller: _passwordController,
                hint: 'Votre mot de passe',
                obscure: true,
                errorText: _passwordError,
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: _submitting ? 'Connexion...' : 'Se connecter',
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                label: 'Creer un compte',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ApplicantIdentificationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
