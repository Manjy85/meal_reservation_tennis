import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_date_screen.dart';

final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
final RegExp _phoneRegex = RegExp(r'^0\d{9}$');

/// Port of MealReservationApplicantIdentificationActivity.kt (signup).
class ApplicantIdentificationScreen extends StatefulWidget {
  const ApplicantIdentificationScreen({super.key});

  @override
  State<ApplicantIdentificationScreen> createState() =>
      _ApplicantIdentificationScreenState();
}

class _ApplicantIdentificationScreenState
    extends State<ApplicantIdentificationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  bool _submitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
    });

    if (firstName.isEmpty) {
      setState(() => _firstNameError = 'Prenom requis');
      return;
    }
    if (lastName.isEmpty) {
      setState(() => _lastNameError = 'Nom requis');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Adresse e-mail invalide');
      return;
    }
    if (!_phoneRegex.hasMatch(phone)) {
      setState(() => _phoneError = 'Numero invalide (10 chiffres, ex. 0612345678)');
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Mot de passe: 6 caracteres minimum');
      return;
    }

    setState(() => _submitting = true);
    await MealReservationLocalStore.saveAccount(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
    );
    await MealReservationLocalStore.setCurrentAccountEmail(email);
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compte enregistre')),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ApplicantDateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creation de compte client')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              child: Text(
                'Creez votre compte pour reserver vos repas d evenement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.amberHoney, fontSize: 16),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '* Champs obligatoires',
                      style: TextStyle(color: AppColors.amberHoney, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const AppFieldLabel('Prenom *'),
                    AppTextField(
                      controller: _firstNameController,
                      hint: 'Ex. Jean',
                      errorText: _firstNameError,
                    ),
                    const SizedBox(height: 20),
                    const AppFieldLabel('Nom *'),
                    AppTextField(
                      controller: _lastNameController,
                      hint: 'Ex. Dupont',
                      errorText: _lastNameError,
                    ),
                    const SizedBox(height: 20),
                    const AppFieldLabel('Adresse e-mail *'),
                    AppTextField(
                      controller: _emailController,
                      hint: 'nom@domaine.fr',
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),
                    const AppFieldLabel('Numero de telephone *'),
                    AppTextField(
                      controller: _phoneController,
                      hint: '10 chiffres (ex. 0612345678)',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      errorText: _phoneError,
                    ),
                    const SizedBox(height: 20),
                    const AppFieldLabel('Mot de passe *'),
                    AppTextField(
                      controller: _passwordController,
                      hint: '6 caracteres minimum',
                      obscure: true,
                      errorText: _passwordError,
                    ),
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      label: _submitting ? 'Enregistrement...' : 'Creer mon compte',
                      onPressed: _submitting ? null : _submit,
                      height: 60,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
