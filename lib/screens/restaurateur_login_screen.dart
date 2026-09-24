import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/common.dart';
import 'restaurateur_dashboard_screen.dart';

/// Shared "Se déconnecter" action for every restaurateur screen.
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
      error = 'Erreur de connexion : $e';
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
                      icon: Icons.storefront_rounded,
                      badge: 'ESPACE RESTAURATEUR',
                      title: 'Connexion',
                      subtitle: 'Gère ta carte, tes dates de service et les commandes en temps réel.',
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      controller: _emailController,
                      label: 'Adresse e-mail',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
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
                      errorText: _error,
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(label: 'Se connecter', loading: _submitting, onPressed: _submit),
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
