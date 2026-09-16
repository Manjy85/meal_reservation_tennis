import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';
import 'restaurateur_catalog_management_screen.dart';
import 'restaurateur_orders_list_screen.dart';
import 'restaurateur_schedule_management_screen.dart';

/// Port of MealReservationRestaurateurDashboardActivity.kt
class RestaurateurDashboardScreen extends StatelessWidget {
  const RestaurateurDashboardScreen({super.key});

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
        title: const Text('Panneau restaurateur'),
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Acces rapide a la gestion du catalogue, des horaires d'evenements et des commandes.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.amberHoney, fontSize: 14),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Gestion du catalogue',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RestaurateurCatalogManagementScreen()),
                ),
              ),
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: 'Dates et plages horaires',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RestaurateurScheduleManagementScreen()),
                ),
              ),
              const SizedBox(height: 14),
              AppPrimaryButton(
                label: 'Consultation des commandes',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RestaurateurOrdersListScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
