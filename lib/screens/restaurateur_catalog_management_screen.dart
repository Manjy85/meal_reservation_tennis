import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'restaurateur_login_screen.dart';
import 'restaurateur_product_form_screen.dart';

const _allTab = 'Tous';

/// Port of MealReservationRestaurateurCatalogManagementActivity.kt,
/// SumUp-style: "Mes articles" with a "+" to add an item and the products
/// grouped into family tabs (plus "Tous"). Live Firestore stream, so the
/// list and tabs update as soon as a product is saved or deleted.
class RestaurateurCatalogManagementScreen extends StatefulWidget {
  const RestaurateurCatalogManagementScreen({super.key});

  @override
  State<RestaurateurCatalogManagementScreen> createState() =>
      _RestaurateurCatalogManagementScreenState();
}

class _RestaurateurCatalogManagementScreenState
    extends State<RestaurateurCatalogManagementScreen> {
  late final Stream<List<Product>> _products = MealReservationStore.watchProducts();

  void _openForm({Product? product}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RestaurateurProductFormScreen(product: product)),
    );
  }

  List<Widget> _actions() => [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.amberHoney),
          tooltip: 'Ajouter un article',
          onPressed: () => _openForm(),
        ),
        IconButton(
          icon: const Icon(Icons.power_settings_new, color: AppColors.amberHoney),
          tooltip: 'Se deconnecter',
          onPressed: () => logoutRestaurateur(context),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mes articles'), actions: _actions()),
            body: snapshot.hasError ? AppErrorView(snapshot.error) : appLoader,
          );
        }

        final products = snapshot.data!;
        final categories = products
            .map((p) => p.category.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final tabs = [_allTab, ...categories];

        return DefaultTabController(
          // A new set of families rebuilds the controller with the right length.
          key: ValueKey(tabs.join('|')),
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mes articles'),
              actions: _actions(),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: AppColors.amberHoney,
                labelColor: AppColors.amberHoney,
                unselectedLabelColor: Colors.white70,
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            body: SafeArea(
              child: TabBarView(
                children: tabs
                    .map((tab) => _ProductList(
                          products: tab == _allTab
                              ? products
                              : products.where((p) => p.category.trim() == tab).toList(),
                          emptyMessage: tab == _allTab
                              ? 'Aucun article. Appuie sur + pour en ajouter un.'
                              : 'Aucun article dans cette famille.',
                          onTapProduct: (p) => _openForm(product: p),
                        ))
                    .toList(),
              ),
            ),
          ),
        );
      },
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
