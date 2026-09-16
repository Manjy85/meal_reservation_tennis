import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'applicant_login_screen.dart';
import 'restaurateur_product_form_screen.dart';

const _allTab = 'Tous';

/// Port of MealReservationRestaurateurCatalogManagementActivity.kt,
/// redesigned SumUp-style: "Mes articles" with a "+" to add an item, and
/// the products grouped into family tabs (plus a "Tous" tab).
class RestaurateurCatalogManagementScreen extends StatefulWidget {
  const RestaurateurCatalogManagementScreen({super.key});

  @override
  State<RestaurateurCatalogManagementScreen> createState() =>
      _RestaurateurCatalogManagementScreenState();
}

class _RestaurateurCatalogManagementScreenState
    extends State<RestaurateurCatalogManagementScreen> with TickerProviderStateMixin {
  List<Product> _products = [];
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

    final distinctCategories = products
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final tabs = [_allTab, ...distinctCategories];

    final previousIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: previousIndex < tabs.length ? previousIndex : 0,
    );

    setState(() {
      _products = products;
      _tabs = tabs;
      _loading = false;
    });
  }

  List<Product> _productsFor(String tab) {
    if (tab == _allTab) return _products;
    return _products.where((p) => p.category.trim() == tab).toList();
  }

  Future<void> _openForm({Product? product}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RestaurateurProductFormScreen(product: product),
      ),
    );
    if (changed == true) _loadProducts();
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicantLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = !_loading && _tabController != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes articles'),
        bottom: ready
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.amberHoney,
                labelColor: AppColors.amberHoney,
                unselectedLabelColor: Colors.white70,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.amberHoney),
            tooltip: 'Ajouter un article',
            onPressed: () => _openForm(),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: AppColors.amberHoney),
            tooltip: 'Se deconnecter',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: !ready
            ? const Center(child: CircularProgressIndicator(color: AppColors.amberHoney))
            : TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) => _ProductList(
                      products: _productsFor(tab),
                      emptyMessage: tab == _allTab
                          ? 'Aucun article. Appuie sur + pour en ajouter un.'
                          : 'Aucun article dans cette famille.',
                      onTapProduct: (p) => _openForm(product: p),
                    )).toList(),
              ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final String emptyMessage;
  final ValueChanged<Product> onTapProduct;

  const _ProductList({
    required this.products,
    required this.emptyMessage,
    required this.onTapProduct,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return InkWell(
          onTap: () => onTapProduct(product),
          child: AppSectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.amberHoney,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        formatEur(product.unitPrice),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!product.enabled)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Inactif', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
