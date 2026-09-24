import 'package:flutter/material.dart';

import '../data/store.dart';
import '../widgets/common.dart';
import '../widgets/order_list_item.dart';
import 'restaurateur_order_detail_screen.dart';

/// Orders already handed over (status "Remise"), most recent first, live.
class RestaurateurOrdersHistoryScreen extends StatefulWidget {
  const RestaurateurOrdersHistoryScreen({super.key});

  @override
  State<RestaurateurOrdersHistoryScreen> createState() => _RestaurateurOrdersHistoryScreenState();
}

class _RestaurateurOrdersHistoryScreenState extends State<RestaurateurOrdersHistoryScreen> {
  late final Stream<List<OrderHistoryEntry>> _orders = MealReservationStore.watchAllOrders();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: StreamBuilder<List<OrderHistoryEntry>>(
        stream: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorView(snapshot.error);
          if (!snapshot.hasData) return appLoader;
          final orders = snapshot.data!.where((o) => o.status == 'Remise').toList().reversed.toList();
          if (orders.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'Aucune commande remise',
              message: 'Les commandes passées au statut « Remise » sont archivées ici.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: orders.length,
            itemBuilder: (context, i) => OrderListItem(
              order: orders[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RestaurateurOrderDetailScreen(reservationNumber: orders[i].reservationNumber),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
