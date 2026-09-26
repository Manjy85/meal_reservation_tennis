import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/account_dialogs.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';

final RegExp _phoneRegex = RegExp(r'^0\d{9}$');

/// "Mon compte": the client's profile (name and phone editable, email shown),
/// password change, logout and account deletion.
class ApplicantAccountScreen extends StatefulWidget {
  const ApplicantAccountScreen({super.key});

  @override
  State<ApplicantAccountScreen> createState() => _ApplicantAccountScreenState();
}

class _ApplicantAccountScreenState extends State<ApplicantAccountScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _email = MealReservationStore.currentEmail;
  bool _emailVerified = MealReservationStore.isEmailVerified;
  String? _loadError;
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  bool _loading = true;
  bool _saving = false;
  bool _verificationSent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await MealReservationStore.reloadUser();
      _emailVerified = MealReservationStore.isEmailVerified;
      final account = await MealReservationStore.getCurrentAccount();
      if (account != null) {
        _firstNameController.text = account.firstName;
        _lastNameController.text = account.lastName;
        _phoneController.text = account.phone;
        if (account.email.isNotEmpty) _email = account.email;
      }
    } catch (e) {
      _loadError = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    setState(() {
      _firstNameError = firstName.isEmpty ? 'Prénom requis' : null;
      _lastNameError = lastName.isEmpty ? 'Nom requis' : null;
      _phoneError = _phoneRegex.hasMatch(phone) ? null : '10 chiffres, ex. 0612345678';
    });
    if ([_firstNameError, _lastNameError, _phoneError].any((e) => e != null)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MealReservationStore.updateProfile(firstName: firstName, lastName: lastName, phone: phone);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Échec de l’enregistrement : $e')));
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    FocusScope.of(context).unfocus();
    messenger.showSnackBar(const SnackBar(content: Text('Informations enregistrées')));
  }

  Future<void> _resendVerification() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MealReservationStore.resendEmailVerification();
    } on StoreAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _verificationSent = true);
    messenger.showSnackBar(SnackBar(content: Text('E-mail de vérification envoyé à $_email')));
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
    if (changed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe modifié')));
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await MealReservationStore.signOut();
    if (mounted) _backToLogin();
  }

  Future<void> _deleteAccount() async {
    final deleted = await showDialog<bool>(context: context, builder: (_) => const _DeleteAccountDialog());
    if (deleted != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    _backToLogin();
    messenger.showSnackBar(
      const SnackBar(content: Text('Ton compte et tes données personnelles ont été supprimés.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: _loading
          ? appLoader
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surfaceHigh,
                        child: Icon(Icons.person_rounded, color: AppColors.amber),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Adresse e-mail',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 2),
                            SelectableText(_email, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _emailVerified ? Icons.verified_rounded : Icons.error_outline_rounded,
                                  size: 16,
                                  color: _emailVerified ? AppColors.success : AppColors.amber,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _emailVerified ? 'Vérifiée' : 'Non vérifiée',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_emailVerified)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _verificationSent ? null : _resendVerification,
                      child: Text(_verificationSent ? 'E-mail envoyé' : 'Renvoyer l’e-mail de vérification'),
                    ),
                  ),
                const SizedBox(height: 8),
                const AppSectionTitle('Mes informations'),
                if (_loadError != null) ...[
                  Text(
                    'Impossible de charger ton profil : $_loadError',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  errorText: _firstNameError,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  errorText: _lastNameError,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  hint: '0612345678',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  maxLength: 10,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  onSubmitted: (_) => _save(),
                  errorText: _phoneError,
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(label: 'Enregistrer', loading: _saving, onPressed: _save),
                const SizedBox(height: 24),
                const AppSectionTitle('Sécurité'),
                AppSecondaryButton(
                  label: 'Changer mon mot de passe',
                  icon: Icons.lock_reset_rounded,
                  onPressed: _changePassword,
                ),
                const SizedBox(height: 24),
                const AppSectionTitle('Session'),
                AppSecondaryButton(
                  label: 'Se déconnecter',
                  icon: Icons.logout_rounded,
                  onPressed: _logout,
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Supprimer mon compte',
                  icon: Icons.delete_forever_rounded,
                  color: AppColors.danger,
                  onPressed: _deleteAccount,
                ),
              ],
            ),
    );
  }
}

/// Confirms with the password, then deletes the account. Pops `true` once done.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  String? _error;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Mot de passe requis');
      return;
    }
    setState(() {
      _error = null;
      _deleting = true;
    });
    try {
      await MealReservationStore.deleteAccount(password);
    } on StoreAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = e.message;
      });
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supprimer mon compte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ton compte, ton nom, ton e-mail et ton téléphone seront définitivement supprimés. '
            'Tes anciennes commandes restent chez le restaurateur, mais sans aucune donnée personnelle.\n\n'
            'Confirme avec ton mot de passe.',
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _delete(),
            errorText: _error,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _deleting ? null : _delete,
          child: Text(_deleting ? 'Suppression…' : 'Supprimer définitivement'),
        ),
      ],
    );
  }
}
