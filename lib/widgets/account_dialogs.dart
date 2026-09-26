import 'package:flutter/material.dart';

import '../data/store.dart';
import 'common.dart';

// Password dialogs shared by the client and admin apps.

final RegExp _resetEmailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

/// Current password + new one twice. Pops `true` once changed.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _currentError;
  String? _newError;
  String? _confirmError;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;
    setState(() {
      _currentError = current.isEmpty ? 'Mot de passe actuel requis' : null;
      _newError = next.length < 6
          ? '6 caractères minimum'
          : next == current
              ? 'Choisis un mot de passe différent de l’actuel'
              : null;
      _confirmError = _confirmController.text == next ? null : 'Les mots de passe ne correspondent pas';
    });
    if ([_currentError, _newError, _confirmError].any((e) => e != null)) return;

    setState(() => _saving = true);
    try {
      await MealReservationStore.changePassword(current, next);
    } on StoreAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.message.startsWith('Mot de passe actuel')) {
          _currentError = e.message;
        } else {
          _newError = e.message;
        }
      });
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer mon mot de passe'),
      content: SingleChildScrollView(
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _currentController,
                label: 'Mot de passe actuel',
                icon: Icons.lock_outline_rounded,
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                errorText: _currentError,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _newController,
                label: 'Nouveau mot de passe',
                hint: '6 caractères minimum',
                icon: Icons.lock_reset_rounded,
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                errorText: _newError,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmController,
                label: 'Confirmer le nouveau mot de passe',
                icon: Icons.lock_reset_rounded,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                errorText: _confirmError,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    );
  }
}

/// Asks for the address and sends Firebase's reset link. Pops `true` once sent.
class ResetPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const ResetPasswordDialog({super.key, required this.initialEmail});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  late final _emailController = TextEditingController(text: widget.initialEmail);
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (!_resetEmailRegex.hasMatch(email)) {
      setState(() => _error = 'Email invalide');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      await MealReservationStore.sendPasswordReset(email);
    } on StoreAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mot de passe oublié'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Indique ton adresse e-mail, on t’envoie un lien pour choisir un nouveau mot de passe.'),
          const SizedBox(height: 16),
          AppTextField(
            controller: _emailController,
            label: 'Adresse e-mail',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _send(),
            errorText: _error,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'Envoi…' : 'Envoyer le lien'),
        ),
      ],
    );
  }
}
