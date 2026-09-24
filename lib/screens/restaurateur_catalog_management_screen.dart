import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import 'restaurateur_product_form_screen.dart';

const _allTab = 'Tous';

/// "Mes articles", SumUp-style: family tabs (plus "Tous"), product list and a
/// floating "+" to add an item. Live Firestore stream, so the list and tabs
/// update as soon as a product is saved or deleted.
class RestaurateurCatalogManagementScreen extends StatefulWidget {
  const RestaurateurCatalogManagementScreen({super.key});

  @override
  State<RestaurateurCatalogManagementScreen> createState() => _RestaurateurCatalogManagementScreenState();
}

class _RestaurateurCatalogManagementScreenState extends State<RestaurateurCatalogManagementScreen> {
  late final Stream<List<Product>> _products = MealReservationStore.watchProducts();

  void _openForm({Product? product}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RestaurateurProductFormScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      onPressed: () => _openForm(),
      tooltip: 'Ajouter un article',
      child: const Icon(Icons.add_rounded, size: 30),
    );

    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mes articles')),
            floatingActionButton: fab,
            body: snapshot.hasError ? AppErrorView(snapshot.error) : appLoader,
          );
        }

        final products = snapshot.data!;
        final families = products
            .map((p) => p.category.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        final tabs = [_allTab, ...families];

        return DefaultTabController(
          // A new set of families rebuilds the controller with the right length.
          key: ValueKey(tabs.join('|')),
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mes articles'),
              bottom: TabBar(
                isScrollable: true,
                tabs: tabs.map((t) {
                  final n = t == _allTab ? products.length : products.where((p) => p.category.trim() == t).length;
                  return Tab(text: '$t  $n');
                }).toList(),
              ),
            ),
            floatingActionButton: fab,
            body: TabBarView(
              children: tabs
                  .map((tab) => _ProductList(
                        products: tab == _allTab
                            ? products
                            : products.where((p) => p.category.trim() == tab).toList(),
                        emptyAll: tab == _allTab,
                        onTapProduct: (p) => _openForm(product: p),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final bool emptyAll;
  final ValueChanged<Product> onTapProduct;

  const _ProductList({required this.products, required this.emptyAll, required this.onTapProduct});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: emptyAll ? 'Aucun article' : 'Aucun article dans cette famille',
        message: emptyAll ? 'Appuie sur + pour créer ton premier article.' : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return Opacity(
          opacity: p.enabled ? 1 : 0.55,
          child: AppCard(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => onTapProduct(p),
            child: Row(
              children: [
                CategoryAvatar(label: '${p.category} ${p.name}', size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        [if (p.category.isNotEmpty) p.category, if (!p.enabled) 'Masqué'].join(' · '),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(formatEur(p.unitPrice), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
