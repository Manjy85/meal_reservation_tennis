import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'restaurateur_dashboard_screen.dart';

/// Shared "Se deconnecter" action for every restaurateur screen.
Future<void> logoutRestaurateur(BuildContext context) async {
  await MealReservationStore.signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RestaurateurLoginScreen()),
    (route) => false,
  );
}

/// Restaurateur login: a Firebase account (email/password) that must also
/// be listed in the Firestore `admins` collection. A regular client
/// account is rejected here even with the right password. Firebase Auth
/// throttles repeated failures itself (too-many-requests).
class RestaurateurLoginScreen extends StatefulWidget {
  const RestaurateurLoginScreen({super.key});

  @override
  State<RestaurateurLoginScreen> createState() => _RestaurateurLoginScreenState();
}

class _RestaurateurLoginScreenState extends State<RestaurateurLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
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
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email et mot de passe requis');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    String? error;
    try {
      await MealReservationStore.signIn(email, password);
      if (!await MealReservationStore.isCurrentUserAdmin()) {
        await MealReservationStore.signOut();
        error = "Ce compte n'a pas les droits restaurateur";
      }
    } on StoreAuthException catch (e) {
      error = e.message;
    } catch (e) {
      await MealReservationStore.signOut();
      error = 'Erreur de connexion: $e';
    }

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RestaurateurDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode restaurateur')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Acces reserve au personnel. Connectez-vous avec votre compte restaurateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.amberHoney, fontSize: 14),
              ),
              const SizedBox(height: 24),
              AppSectionCard(
                padding: const EdgeInsets.all(16),
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Adresse e-mail', style: TextStyle(color: AppColors.amberHoney, fontSize: 15)),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _emailController,
                      hint: 'nom@domaine.fr',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    const Text('Mot de passe', style: TextStyle(color: AppColors.amberHoney, fontSize: 15)),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _passwordController,
                      hint: '********',
                      obscure: true,
                      errorText: _error,
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      label: _submitting ? 'Connexion...' : 'Se connecter',
                      onPressed: _submitting ? null : _submit,
                      height: 52,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
