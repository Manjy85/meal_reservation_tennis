import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/common.dart';
import 'applicant_home_screen.dart';

final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
final RegExp _phoneRegex = RegExp(r'^0\d{9}$');

/// Client signup (Firebase account + profile in users/{uid}).
class ApplicantIdentificationScreen extends StatefulWidget {
  const ApplicantIdentificationScreen({super.key});

  @override
  State<ApplicantIdentificationScreen> createState() => _ApplicantIdentificationScreenState();
}

class _ApplicantIdentificationScreenState extends State<ApplicantIdentificationScreen> {
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
    final password = _passwordController.text;

    setState(() {
      _firstNameError = firstName.isEmpty ? 'Prénom requis' : null;
      _lastNameError = lastName.isEmpty ? 'Nom requis' : null;
      _emailError = _emailRegex.hasMatch(email) ? null : 'Adresse e-mail invalide';
      _phoneError = _phoneRegex.hasMatch(phone) ? null : '10 chiffres, ex. 0612345678';
      _passwordError = password.length < 6 ? '6 caractères minimum' : null;
    });
    if ([_firstNameError, _lastNameError, _emailError, _phoneError, _passwordError].any((e) => e != null)) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await MealReservationStore.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
    } on StoreAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (e.message.startsWith('Mot de passe')) {
          _passwordError = e.message;
        } else {
          _emailError = e.message;
        }
      });
      return;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bienvenue $firstName, ton compte est créé !')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppBrandHeader(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Créer un compte',
                      subtitle: 'Quelques infos pour réserver tes repas lors des événements du club.',
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _firstNameController,
                            label: 'Prénom',
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            errorText: _firstNameError,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _lastNameController,
                            label: 'Nom',
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.familyName],
                            errorText: _lastNameError,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                      controller: _phoneController,
                      label: 'Téléphone',
                      hint: '0612345678',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      maxLength: 10,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      errorText: _phoneError,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      hint: '6 caractères minimum',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _submit(),
                      errorText: _passwordError,
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(
                      label: 'Créer mon compte',
                      loading: _submitting,
                      onPressed: _submit,
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
