import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_confirmation_screen.dart';

class BasketItemData {
  final String name;
  final double unitPrice;
  final String category;
  int qty;

  BasketItemData({required this.name, required this.unitPrice, required this.qty, this.category = ''});

  BasketItemData copy() => BasketItemData(name: name, unitPrice: unitPrice, qty: qty, category: category);
}

/// Checkout-style basket: editable lines, order summary, and a sticky
/// "Valider la commande" button showing the total.
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
  State<ApplicantReservationBasketScreen> createState() => _ApplicantReservationBasketScreenState();
}

class _ApplicantReservationBasketScreenState extends State<ApplicantReservationBasketScreen> {
  late final List<BasketItemData> _items = widget.initialItems.map((i) => i.copy()).toList();

  double get _total => _items.fold(0.0, (acc, i) => acc + i.qty * i.unitPrice);
  int get _count => _items.fold(0, (n, i) => n + i.qty);

  void _validate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicantConfirmationScreen(
          selectedDate: widget.selectedDate,
          selectedService: widget.selectedService,
          items: _items.map((i) => i.copy()).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSoir = widget.selectedService == 'Soir';
    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Ton panier est vide',
                    message: 'Ajoute des produits depuis la carte.',
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour à la carte'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      DateBadge(widget.selectedDate),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatLongDate(widget.selectedDate), style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isSoir ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                  size: 16,
                                  color: AppColors.amber,
                                ),
                                const SizedBox(width: 6),
                                Text('Service du ${widget.selectedService.toLowerCase()}',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AppSectionTitle('Articles ($_count)'),
                ..._items.map((item) => _BasketLine(
                      item: item,
                      onMinus: () => setState(() {
                        if (item.qty > 1) {
                          item.qty -= 1;
                        } else {
                          _items.remove(item);
                        }
                      }),
                      onPlus: () => setState(() => item.qty += 1),
                    )),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Sous-total', value: formatEur(_total)),
                      const SizedBox(height: 8),
                      const _SummaryRow(label: 'Paiement', value: 'Sur place'),
                      const Divider(height: 24),
                      _SummaryRow(label: 'Total', value: formatEur(_total), strong: true),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : AppBottomBar(
              child: AppPrimaryButton(
                label: 'Valider la commande · ${formatEur(_total)}',
                onPressed: _validate,
              ),
            ),
    );
  }
}

class _BasketLine extends StatelessWidget {
  final BasketItemData item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _BasketLine({required this.item, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CategoryAvatar(label: '${item.category} ${item.name}', size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  formatEur(item.qty * item.unitPrice),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          QtyStepper(qty: item.qty, onMinus: onMinus, onPlus: onPlus),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _SummaryRow({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)
        : const TextStyle(color: AppColors.textSecondary);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: strong ? style.copyWith(color: AppColors.amber) : style),
      ],
    );
  }
}
