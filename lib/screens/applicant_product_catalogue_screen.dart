import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_reservation_basket_screen.dart';

const _allTab = 'Tous';

class _CatalogueProduct {
  final String name;
  final double unitPrice;
  final String description;
  final String category;
  int qty;

  _CatalogueProduct({
    required this.name,
    required this.unitPrice,
    required this.description,
    required this.category,
    this.qty = 0,
  });
}

/// Port of MealReservationApplicantProductCatalogueActivity.kt. The catalog
/// is read from the products the restaurateur configured (Product,
/// enabled == true), grouped into family tabs like the restaurateur's
/// catalog management screen (plus a "Tous" tab showing everything).
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
    extends State<ApplicantProductCatalogueScreen> with TickerProviderStateMixin {
  List<_CatalogueProduct> _products = [];
  List<String> _tabs = [_allTab];
  TabController? _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final products = await MealReservationLocalStore.getProducts();
    if (!mounted) return;

    final enabled = products
        .where((p) => p.enabled)
        .map((p) => _CatalogueProduct(
              name: p.name,
              unitPrice: p.unitPrice,
              description: p.description,
              category: p.category.trim(),
            ))
        .toList();

    final distinctCategories = enabled
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final tabs = [_allTab, ...distinctCategories];

    _tabController?.dispose();
    _tabController = TabController(length: tabs.length, vsync: this);

    setState(() {
      _products = enabled;
      _tabs = tabs;
      _loading = false;
    });
  }

  List<_CatalogueProduct> _productsFor(String tab) {
    if (tab == _allTab) return _products;
    return _products.where((p) => p.category == tab).toList();
  }

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
    final ready = !_loading && _tabController != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue des produits'),
        bottom: ready && _products.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.amberHoney,
                labelColor: AppColors.amberHoney,
                unselectedLabelColor: Colors.white70,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              )
            : null,
      ),
      body: SafeArea(
        child: !ready
            ? const Center(child: CircularProgressIndicator(color: AppColors.amberHoney))
            : _products.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "Aucun produit disponible pour le moment.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  )
                : Column(
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
                          controller: _tabController,
                          children: _tabs
                              .map(
                                (tab) => _CatalogueProductList(
                                  products: _productsFor(tab),
                                  onMinus: (p) => setState(() {
                                    if (p.qty > 0) p.qty -= 1;
                                  }),
                                  onPlus: (p) => setState(() => p.qty += 1),
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

class _CatalogueProductList extends StatelessWidget {
  final List<_CatalogueProduct> products;
  final ValueChanged<_CatalogueProduct> onMinus;
  final ValueChanged<_CatalogueProduct> onPlus;

  const _CatalogueProductList({
    required this.products,
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
                Text(
                  p.description,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Prix unitaire: ${formatEur(p.unitPrice)}',
                style: const TextStyle(color: AppColors.amberHoney, fontSize: 14),
              ),
              const SizedBox(height: 10),
              AppQtyStepper(
                qty: p.qty,
                onMinus: () => onMinus(p),
                onPlus: () => onPlus(p),
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
    );
  }
}
