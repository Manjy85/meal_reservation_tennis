import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_reservation_basket_screen.dart';

const _allTab = 'Tous';

/// Port of MealReservationApplicantProductCatalogueActivity.kt. Shows the
/// enabled products configured by the restaurateur (live Firestore
/// stream), grouped into family tabs plus a "Tous" tab. Quantities are kept
/// per product id, so they survive tab switches and catalogue updates.
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

class _ApplicantProductCatalogueScreenState extends State<ApplicantProductCatalogueScreen> {
  late final Stream<List<Product>> _products = MealReservationStore.watchProducts();
  final Map<String, int> _qty = {};

  int _qtyOf(Product p) => _qty[p.id] ?? 0;

  double _totalOf(List<Product> products) =>
      products.fold(0.0, (sum, p) => sum + _qtyOf(p) * p.unitPrice);

  void _viewBasket(List<Product> products) {
    final selected = products.where((p) => _qtyOf(p) > 0).toList();
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
              .map((p) => BasketItemData(name: p.name, unitPrice: p.unitPrice, qty: _qtyOf(p)))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Catalogue des produits')),
            body: snapshot.hasError ? AppErrorView(snapshot.error) : appLoader,
          );
        }

        final products = snapshot.data!.where((p) => p.enabled).toList();
        if (products.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Catalogue des produits')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun produit disponible pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          );
        }

        final categories = products
            .map((p) => p.category.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final tabs = [_allTab, ...categories];
        final total = _totalOf(products);

        return DefaultTabController(
          // A new set of families (added/removed by the admin) rebuilds the controller.
          key: ValueKey(tabs.join('|')),
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Catalogue des produits'),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: AppColors.amberHoney,
                labelColor: AppColors.amberHoney,
                unselectedLabelColor: Colors.white70,
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
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
                    child: TabBarView(
                      children: tabs
                          .map(
                            (tab) => _CatalogueProductList(
                              products: tab == _allTab
                                  ? products
                                  : products.where((p) => p.category.trim() == tab).toList(),
                              qtyOf: _qtyOf,
                              onMinus: (p) => setState(() {
                                if (_qtyOf(p) > 0) _qty[p.id] = _qtyOf(p) - 1;
                              }),
                              onPlus: (p) => setState(() => _qty[p.id] = _qtyOf(p) + 1),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  AppFooterBar(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Total general: ${formatEur(total)}',
                          style: const TextStyle(
                            color: AppColors.amberHoney,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppPrimaryButton(
                          label: 'Voir mon panier',
                          onPressed: total > 0 ? () => _viewBasket(products) : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CatalogueProductList extends StatelessWidget {
  final List<Product> products;
  final int Function(Product) qtyOf;
  final ValueChanged<Product> onMinus;
  final ValueChanged<Product> onPlus;

  const _CatalogueProductList({
    required this.products,
    required this.qtyOf,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun produit dans cette famille.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final qty = qtyOf(p);
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
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(p.description, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
              const SizedBox(height: 6),
              Text(
                'Prix unitaire: ${formatEur(p.unitPrice)}',
                style: const TextStyle(color: AppColors.amberHoney, fontSize: 14),
              ),
              const SizedBox(height: 10),
              AppQtyStepper(qty: qty, onMinus: () => onMinus(p), onPlus: () => onPlus(p)),
              const SizedBox(height: 8),
              Text(
                'Sous-total: ${formatEur(qty * p.unitPrice)}',
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
    );
  }
}
