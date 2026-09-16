import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_reservation_basket_screen.dart';

class _CatalogueProduct {
  final String name;
  final double unitPrice;
  final String description;
  int qty;

  _CatalogueProduct({
    required this.name,
    required this.unitPrice,
    required this.description,
    this.qty = 0,
  });
}

/// Port of MealReservationApplicantProductCatalogueActivity.kt
class ApplicantProductCatalogueScreen extends StatefulWidget {
  final String selectedDate;
  final String selectedService;

  const ApplicantProductCatalogueScreen({
    super.key,
    required this.selectedDate,
    required this.selectedService,
  });

  @override
  State<ApplicantProductCatalogueScreen> createState() =>
      _ApplicantProductCatalogueScreenState();
}

class _ApplicantProductCatalogueScreenState
    extends State<ApplicantProductCatalogueScreen> {
  final List<_CatalogueProduct> _products = [
    _CatalogueProduct(
      name: 'Burger Simple',
      unitPrice: 8.0,
      description: '1 steak hache, salade, tomate, sauce, pain',
    ),
    _CatalogueProduct(
      name: 'Burger Double',
      unitPrice: 10.0,
      description: '2 steaks haches, double fromage, sauce speciale, pain',
    ),
    _CatalogueProduct(
      name: 'Bagel',
      unitPrice: 7.5,
      description: 'Pain bagel, poulet grille, crudites, sauce yaourt',
    ),
    _CatalogueProduct(
      name: 'Frites',
      unitPrice: 2.0,
      description: 'Portion de frites maison (accompagnement)',
    ),
    _CatalogueProduct(
      name: 'Boissons',
      unitPrice: 1.5,
      description: "Eau minerale, soda (cola, limonade, jus d'orange)",
    ),
  ];

  double get _total =>
      _products.fold(0.0, (sum, p) => sum + p.qty * p.unitPrice);

  void _viewBasket() {
    final selected = _products.where((p) => p.qty > 0).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins 1 produit pour voir le panier')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicantReservationBasketScreen(
          selectedDate: widget.selectedDate,
          selectedService: widget.selectedService,
          initialItems: selected
              .map((p) => BasketItemData(name: p.name, unitPrice: p.unitPrice, qty: p.qty))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue des produits')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Choisissez les quantites souhaitees. Le sous-total de chaque article et le total du panier se mettent a jour en temps reel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.amberHoney, fontSize: 14),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            color: AppColors.amberHoney,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.description,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Prix unitaire: ${formatEur(p.unitPrice)}',
                          style: const TextStyle(color: AppColors.amberHoney, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        AppQtyStepper(
                          qty: p.qty,
                          onMinus: () => setState(() {
                            if (p.qty > 0) p.qty -= 1;
                          }),
                          onPlus: () => setState(() => p.qty += 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sous-total: ${formatEur(p.qty * p.unitPrice)}',
                          style: const TextStyle(
                            color: AppColors.amberHoney,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            AppFooterBar(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Total general: ${formatEur(_total)}',
                    style: const TextStyle(
                      color: AppColors.amberHoney,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Voir mon panier',
                    onPressed: _total > 0 ? _viewBasket : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
