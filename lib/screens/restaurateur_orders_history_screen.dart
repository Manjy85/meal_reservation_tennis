import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/common.dart';
import '../widgets/order_list_item.dart';
import 'restaurateur_order_detail_screen.dart';

/// Port of MealReservationRestaurateurOrdersHistoryActivity.kt: orders whose
/// status is "Remise", as a live Firestore stream. No logout button here,
/// matching the original layout.
class RestaurateurOrdersHistoryScreen extends StatefulWidget {
  const RestaurateurOrdersHistoryScreen({super.key});

  @override
  State<RestaurateurOrdersHistoryScreen> createState() =>
      _RestaurateurOrdersHistoryScreenState();
}

class _RestaurateurOrdersHistoryScreenState extends State<RestaurateurOrdersHistoryScreen> {
  late final Stream<List<OrderHistoryEntry>> _orders = MealReservationStore.watchAllOrders();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: StreamBuilder<List<OrderHistoryEntry>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) return AppErrorView(snapshot.error);
            if (!snapshot.hasData) return appLoader;
            final orders = snapshot.data!.where((o) => o.status == 'Remise').toList();
            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune commande remise',
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
