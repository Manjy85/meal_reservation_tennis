import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'restaurateur_dashboard_screen.dart';

const _adminUsername = 'admin';
const _adminPassword = 'admin';

/// Port of MealReservationRestaurateurLoginActivity.kt.
/// Note: the original layout shows "Tentatives restantes" / lockout copy,
/// but MealReservationRestaurateurLoginActivity.kt never actually wires any
/// attempt-counting or lockout logic - those labels are static/dead in the
/// original app too, so they're kept here as static text for fidelity.
class RestaurateurLoginScreen extends StatefulWidget {
  const RestaurateurLoginScreen({super.key});

  @override
  State<RestaurateurLoginScreen> createState() => _RestaurateurLoginScreenState();
}

class _RestaurateurLoginScreenState extends State<RestaurateurLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _passwordError = null);

    if (username == _adminUsername && password == _adminPassword) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RestaurateurDashboardScreen()),
      );
    } else {
      setState(() => _passwordError = 'Identifiants invalides');
    }
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
                'Acces reserve au personnel. Saisissez votre identifiant et votre mot de passe.',
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
                    const Text('Identifiant', style: TextStyle(color: AppColors.amberHoney, fontSize: 15)),
                    const SizedBox(height: 8),
                    AppTextField(controller: _usernameController, hint: 'admin_asso'),
                    const SizedBox(height: 14),
                    const Text('Mot de passe', style: TextStyle(color: AppColors.amberHoney, fontSize: 15)),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _passwordController,
                      hint: '********',
                      obscure: true,
                      errorText: _passwordError,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tentatives restantes: 3',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Apres 3 echecs, verrouillage temporaire de 30 secondes.',
                      style: TextStyle(color: AppColors.amberHoney, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(label: 'Se connecter', onPressed: _submit, height: 52),
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
