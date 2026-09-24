import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_home_screen.dart';
import 'applicant_reservation_basket_screen.dart';

/// Port of MealReservationApplicantNumActivity.kt (order confirmation /
/// recap screen). On load: creates the order in Firestore (which assigns
/// the reservation number), then shows the recap.
class ApplicantConfirmationScreen extends StatefulWidget {
  final String selectedDate;
  final String selectedService;
  final List<BasketItemData> items;

  const ApplicantConfirmationScreen({
    super.key,
    required this.selectedDate,
    required this.selectedService,
    required this.items,
  });

  @override
  State<ApplicantConfirmationScreen> createState() =>
      _ApplicantConfirmationScreenState();
}

class _ApplicantConfirmationScreenState
    extends State<ApplicantConfirmationScreen> {
  late Future<_ConfirmationData> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildAndSave();
  }

  Future<_ConfirmationData> _buildAndSave() async {
    final recapItems = widget.items.where((i) => i.qty > 0).toList();
    final total = recapItems.fold(0.0, (sum, i) => sum + i.qty * i.unitPrice);

    final reservationNumber = await MealReservationStore.placeOrder(
      date: widget.selectedDate,
      service: widget.selectedService,
      products: recapItems
          .map((i) => OrderProduct(name: i.name, qty: i.qty, unitPrice: i.unitPrice))
          .toList(),
    );
    final account = await MealReservationStore.getCurrentAccount();

    return _ConfirmationData(
      reservationNumber: reservationNumber,
      account: account,
      recapItems: recapItems,
      total: total,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation de commande')),
      body: SafeArea(
        child: FutureBuilder<_ConfirmationData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "La commande n'a pas pu etre enregistree.\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: 'Retour au panier',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) return appLoader;
            final data = snapshot.data!;
            final account = data.account;
            final identityText = account != null
                ? 'Identite: ${account.firstName} ${account.lastName} - ${account.email} - ${account.phone}'
                : 'Identite: compte non trouve';

            final productsSummary = data.recapItems.isEmpty
                ? 'Produits:\n- Aucun produit'
                : 'Produits:\n${data.recapItems.map((i) => '- ${i.name} x${i.qty} = ${formatEur(i.qty * i.unitPrice)}').join('\n')}';

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Numero de reservation',
                                style: TextStyle(color: AppColors.amberHoney, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.reservationNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recapitulatif complet',
                                style: TextStyle(
                                  color: AppColors.amberHoney,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(identityText, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${widget.selectedDate.isEmpty ? '-' : widget.selectedDate}',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Service: ${widget.selectedService.isEmpty ? '-' : widget.selectedService}',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(productsSummary, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(
                                'Total TTC: ${formatEur(data.total)}',
                                style: const TextStyle(
                                  color: AppColors.amberHoney,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppFooterBar(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Commande enregistree dans la base locale.',
                        style: TextStyle(color: AppColors.amberHoney, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      AppPrimaryButton(
                        label: 'Terminer',
                        height: 52,
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const ApplicantHomeScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfirmationData {
  final String reservationNumber;
  final Account? account;
  final List<BasketItemData> recapItems;
  final double total;

  _ConfirmationData({
    required this.reservationNumber,
    required this.account,
    required this.recapItems,
    required this.total,
  });
}
