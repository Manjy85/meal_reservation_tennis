import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Port of MealReservationRestaurateurProductFormActivity.kt.
/// In the original, Save and Delete just call finish() - no field is read
/// or persisted (the form is UI-only), so this screen mirrors that: filling
/// the fields has no effect, both buttons simply pop the screen.
class RestaurateurProductFormScreen extends StatelessWidget {
  const RestaurateurProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Creation ou modification d'un article.",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const AppTextFieldPlaceholder(hint: 'Nom du produit'),
              const SizedBox(height: 12),
              const AppTextFieldPlaceholder(hint: 'Description', maxLines: 4),
              const SizedBox(height: 12),
              const AppTextFieldPlaceholder(hint: 'Prix (ex: 9.90)'),
              const SizedBox(height: 12),
              const AppDecorativeDropdown(label: 'Categorie'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text('Produit disponible', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  Switch(value: true, onChanged: null),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Photo (optionnelle)', style: TextStyle(color: AppColors.amberHoney, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 170,
                decoration: BoxDecoration(
                  color: AppColors.cardOverlay,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined, color: Colors.white54, size: 40),
                ),
              ),
              const SizedBox(height: 8),
              AppPrimaryButton(label: 'Choisir une photo', height: 48, onPressed: () {}),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Enregistrer',
                height: 52,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              AppPrimaryButton(
                label: 'Supprimer le produit',
                height: 52,
                backgroundColor: AppColors.deleteRedStrong,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTextFieldPlaceholder extends StatelessWidget {
  final String hint;
  final int maxLines;

  const AppTextFieldPlaceholder({super.key, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.hintWhite),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.amberHoney),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.amberHoney, width: 2),
        ),
      ),
    );
  }
}
