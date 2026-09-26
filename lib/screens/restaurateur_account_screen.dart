import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/account_dialogs.dart';
import '../widgets/common.dart';
import 'restaurateur_login_screen.dart';

/// Restaurateur "Mon compte": the account email, password change and
/// logout. No profile or deletion here - admin accounts are created and
/// removed by hand in the Firebase console.
class RestaurateurAccountScreen extends StatelessWidget {
  const RestaurateurAccountScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final changed = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
    if (changed != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe modifié')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceHigh,
                  child: Icon(Icons.storefront_rounded, color: AppColors.amber),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Restaurateur', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      SelectableText(
                        MealReservationStore.currentEmail,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionTitle('Sécurité'),
          AppSecondaryButton(
            label: 'Changer mon mot de passe',
            icon: Icons.lock_reset_rounded,
            onPressed: () => _changePassword(context),
          ),
          const SizedBox(height: 24),
          const AppSectionTitle('Session'),
          AppSecondaryButton(
            label: 'Se déconnecter',
            icon: Icons.logout_rounded,
            onPressed: () => logoutRestaurateur(context),
          ),
        ],
      ),
    );
  }
}
