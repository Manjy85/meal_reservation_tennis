import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';
import 'restaurateur_product_form_screen.dart';

/// Port of MealReservationRestaurateurCatalogManagementActivity.kt.
/// The original activity only wires "Ajouter un produit" and logout - the
/// search field, category spinner, "show inactive" switch and the products
/// RecyclerView are present in the layout but never connected to any data
/// (no adapter is ever set), so this screen keeps them purely decorative,
/// matching the real app's behaviour.
class RestaurateurCatalogManagementScreen extends StatelessWidget {
  const RestaurateurCatalogManagementScreen({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: AppColors.amberHoney),
            tooltip: 'Se deconnecter',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionCard(
                padding: const EdgeInsets.all(12),
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TextField(
                      enabled: false,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit',
                        hintStyle: TextStyle(color: AppColors.hintWhite),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.amberHoney),
                        ),
                        disabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.amberHoney),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: AppDecorativeDropdown(label: 'Toutes les categories'),
                        ),
                        const SizedBox(width: 10),
                        const Text('Afficher inactifs', style: TextStyle(color: Colors.white, fontSize: 13)),
                        Switch(value: false, onChanged: null),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppPrimaryButton(
                      label: 'Ajouter un produit',
                      height: 48,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RestaurateurProductFormScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Expanded(
                child: Center(
                  child: Text(
                    'Aucun produit',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
