import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_home_screen.dart';
import 'applicant_reservation_basket_screen.dart';

/// Places the order in Firestore (which assigns the reservation number) and
/// shows it as a ticket. Once placed, "back" goes home instead of returning
/// to the basket, so the same order can't be submitted twice.
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
  State<ApplicantConfirmationScreen> createState() => _ApplicantConfirmationScreenState();
}

class _ApplicantConfirmationScreenState extends State<ApplicantConfirmationScreen> {
  late final List<BasketItemData> _items = widget.items.where((i) => i.qty > 0).toList();
  late final Future<String> _order = _place();
  bool _failed = false;

  double get _total => _items.fold(0.0, (acc, i) => acc + i.qty * i.unitPrice);

  Future<String> _place() async {
    try {
      return await MealReservationStore.placeOrder(
        date: widget.selectedDate,
        service: widget.selectedService,
        products: _items.map((i) => OrderProduct(name: i.name, qty: i.qty, unitPrice: i.unitPrice)).toList(),
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      rethrow;
    }
  }

  void _goHome({int tab = 0}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ApplicantHomeScreen(initialTab: tab)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _order,
      builder: (context, snapshot) {
        final done = snapshot.hasData;
        return PopScope(
          canPop: _failed,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && done) _goHome();
          },
          child: Scaffold(
            appBar: AppBar(automaticallyImplyLeading: _failed),
            body: _failed
                ? _ErrorBody(error: snapshot.error, onBack: () => Navigator.of(context).pop())
                : !done
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Envoi de ta commande…', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : _SuccessBody(
                        reservationNumber: snapshot.data!,
                        date: widget.selectedDate,
                        service: widget.selectedService,
                        items: _items,
                        total: _total,
                      ),
            bottomNavigationBar: done
                ? AppBottomBar(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppPrimaryButton(
                          label: 'Suivre ma commande',
                          icon: Icons.receipt_long_rounded,
                          onPressed: () => _goHome(tab: 1),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _goHome, child: const Text('Retour à l’accueil')),
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final String reservationNumber;
  final String date;
  final String service;
  final List<BasketItemData> items;
  final double total;

  const _SuccessBody({
    required this.reservationNumber,
    required this.date,
    required this.service,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Commande confirmée !',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Présente ce numéro au comptoir pour récupérer ton repas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: AppColors.amber.withValues(alpha: 0.12),
                child: Column(
                  children: [
                    const Text(
                      'N° DE RÉSERVATION',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      reservationNumber,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        DateBadge(date),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatLongDate(date), style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text('Service du ${service.toLowerCase()}',
                                  style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    ...items.map(
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Text('${i.qty}×',
                                style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(i.name)),
                            Text(formatEur(i.qty * i.unitPrice)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        ),
                        Text(
                          formatEur(total),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Paiement sur place',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final Object? error;
  final VoidCallback onBack;

  const _ErrorBody({required this.error, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'La commande n’a pas pu être envoyée',
              message: '$error',
            ),
            AppPrimaryButton(label: 'Retour au panier', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}
