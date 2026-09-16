import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_confirmation_screen.dart';

class BasketItemData {
  final String name;
  final double unitPrice;
  int qty;

  BasketItemData({required this.name, required this.unitPrice, required this.qty});
}

/// Port of MealReservationApplicantReservationBasketActivity.kt
class ApplicantReservationBasketScreen extends StatefulWidget {
  final String selectedDate;
  final String selectedService;
  final List<BasketItemData> initialItems;

  const ApplicantReservationBasketScreen({
    super.key,
    required this.selectedDate,
    required this.selectedService,
    required this.initialItems,
  });

  @override
  State<ApplicantReservationBasketScreen> createState() =>
      _ApplicantReservationBasketScreenState();
}

class _ApplicantReservationBasketScreenState
    extends State<ApplicantReservationBasketScreen> {
  late List<BasketItemData> _basketItems;

  @override
  void initState() {
    super.initState();
    _basketItems = widget.initialItems.map((i) {
      return BasketItemData(name: i.name, unitPrice: i.unitPrice, qty: i.qty);
    }).toList();
  }

  double get _total =>
      _basketItems.fold(0.0, (sum, i) => sum + i.qty * i.unitPrice);

  void _validate() {
    if (_basketItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ton panier est vide')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicantConfirmationScreen(
          selectedDate: widget.selectedDate,
          selectedService: widget.selectedService,
          items: _basketItems
              .map((i) => BasketItemData(name: i.name, unitPrice: i.unitPrice, qty: i.qty))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _basketItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Panier et recapitulatif')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AppSectionCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date choisie: ${widget.selectedDate.isEmpty ? '-' : widget.selectedDate}',
                      style: const TextStyle(
                        color: AppColors.amberHoney,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Service: ${widget.selectedService.isEmpty ? '-' : widget.selectedService}',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: !hasItems
                  ? const Center(
                      child: Text(
                        'Aucun produit selectionne',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      itemCount: _basketItems.length,
                      itemBuilder: (context, index) {
                        final item = _basketItems[index];
                        return AppSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: AppColors.amberHoney,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Prix unitaire: ${formatEur(item.unitPrice)}',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  AppQtyStepper(
                                    qty: item.qty,
                                    onMinus: () => setState(() {
                                      if (item.qty > 1) {
                                        item.qty -= 1;
                                      } else {
                                        _basketItems.remove(item);
                                      }
                                    }),
                                    onPlus: () => setState(() => item.qty += 1),
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () => setState(() => _basketItems.remove(item)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.deleteRed,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sous-total: ${formatEur(item.qty * item.unitPrice)}',
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
                    label: 'Valider la commande',
                    onPressed: hasItems ? _validate : null,
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
