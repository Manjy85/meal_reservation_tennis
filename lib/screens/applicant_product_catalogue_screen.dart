import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_reservation_basket_screen.dart';

const _allFamilies = 'Tous';

/// The menu for the chosen date/service: enabled products from the
/// restaurateur's catalogue (live stream), filtered by family chips, with a
/// floating cart bar once something is added. Quantities are kept per
/// product id so they survive filtering and catalogue updates.
class ApplicantProductCatalogueScreen extends StatefulWidget {
  final String selectedDate;
  final String selectedService;

  const ApplicantProductCatalogueScreen({
    super.key,
    required this.selectedDate,
    required this.selectedService,
  });

  @override
  State<ApplicantProductCatalogueScreen> createState() => _ApplicantProductCatalogueScreenState();
}

class _ApplicantProductCatalogueScreenState extends State<ApplicantProductCatalogueScreen> {
  late final Stream<List<Product>> _products = MealReservationStore.watchProducts();
  final Map<String, int> _qty = {};
  String _family = _allFamilies;

  int _qtyOf(Product p) => _qty[p.id] ?? 0;

  void _add(Product p) => setState(() => _qty[p.id] = _qtyOf(p) + 1);

  void _remove(Product p) => setState(() {
        final q = _qtyOf(p) - 1;
        if (q <= 0) {
          _qty.remove(p.id);
        } else {
          _qty[p.id] = q;
        }
      });

  void _openBasket(List<Product> products) {
    final selected = products.where((p) => _qtyOf(p) > 0).toList();
    if (selected.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApplicantReservationBasketScreen(
          selectedDate: widget.selectedDate,
          selectedService: widget.selectedService,
          initialItems: selected
              .map((p) => BasketItemData(name: p.name, unitPrice: p.unitPrice, qty: _qtyOf(p), category: p.category))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La carte'),
            Text(
              '${formatLongDate(widget.selectedDate)} · ${widget.selectedService}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _products,
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorView(snapshot.error);
          if (!snapshot.hasData) return appLoader;

          final products = snapshot.data!.where((p) => p.enabled).toList();
          if (products.isEmpty) {
            return const AppEmptyState(
              icon: Icons.no_meals_rounded,
              title: 'La carte est vide',
              message: 'Aucun produit n’est disponible pour le moment.',
            );
          }

          final families = products
              .map((p) => p.category.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final family = families.contains(_family) ? _family : _allFamilies;
          final visible = family == _allFamilies
              ? products
              : products.where((p) => p.category.trim() == family).toList();

          final count = products.fold(0, (n, p) => n + _qtyOf(p));
          final total = products.fold(0.0, (acc, p) => acc + _qtyOf(p) * p.unitPrice);

          return Stack(
            children: [
              Column(
                children: [
                  if (families.isNotEmpty)
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        children: [_allFamilies, ...families]
                            .map((f) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(f),
                                    selected: f == family,
                                    onSelected: (_) => setState(() => _family = f),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, count > 0 ? 110 : 24),
                      itemCount: visible.length,
                      itemBuilder: (context, i) => _ProductTile(
                        product: visible[i],
                        qty: _qtyOf(visible[i]),
                        onAdd: () => _add(visible[i]),
                        onRemove: () => _remove(visible[i]),
                      ),
                    ),
                  ),
                ],
              ),
              if (count > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: _CartBar(count: count, total: total, onTap: () => _openBasket(products)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductTile({required this.product, required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: qty > 0 ? AppColors.surfaceHigh : null,
      onTap: qty == 0 ? onAdd : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryAvatar(label: '${product.category} ${product.name}', size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatEur(product.unitPrice),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    if (qty == 0)
                      AddButton(onPressed: onAdd)
                    else
                      QtyStepper(qty: qty, onMinus: onRemove, onPlus: onAdd),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;

  const _CartBar({required this.count, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.amber,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      shadowColor: AppColors.amber.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.onAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: AppColors.onAmber, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Voir le panier',
                  style: TextStyle(color: AppColors.onAmber, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Text(
                formatEur(total),
                style: const TextStyle(color: AppColors.onAmber, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
