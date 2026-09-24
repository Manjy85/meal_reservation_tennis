import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/order_list_item.dart';
import 'restaurateur_login_screen.dart';
import 'restaurateur_order_detail_screen.dart';
import 'restaurateur_orders_history_screen.dart';

/// Port of MealReservationRestaurateurOrdersListActivity.kt: orders whose
/// status isn't "Remise", as a live Firestore stream - an order placed from
/// the client app appears here immediately.
class RestaurateurOrdersListScreen extends StatefulWidget {
  const RestaurateurOrdersListScreen({super.key});

  @override
  State<RestaurateurOrdersListScreen> createState() => _RestaurateurOrdersListScreenState();
}

class _RestaurateurOrdersListScreenState extends State<RestaurateurOrdersListScreen> {
  late final Stream<List<OrderHistoryEntry>> _orders = MealReservationStore.watchAllOrders();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RestaurateurOrdersHistoryScreen()),
            ),
            child: const Text('Historique', style: TextStyle(color: AppColors.amberHoney)),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: AppColors.amberHoney),
            tooltip: 'Se deconnecter',
            onPressed: () => logoutRestaurateur(context),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<OrderHistoryEntry>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) return AppErrorView(snapshot.error);
            if (!snapshot.hasData) return appLoader;
            final orders = snapshot.data!.where((o) => o.status != 'Remise').toList();
            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune commande enregistree',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderListItem(
                  order: order,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RestaurateurOrderDetailScreen(
                        reservationNumber: order.reservationNumber,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
