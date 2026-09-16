import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/order_list_item.dart';
import 'restaurateur_order_detail_screen.dart';

/// Port of MealReservationRestaurateurOrdersHistoryActivity.kt (orders with
/// status == "Remise"). No logout button here either, matching the original
/// layout which doesn't have one on this screen.
class RestaurateurOrdersHistoryScreen extends StatefulWidget {
  const RestaurateurOrdersHistoryScreen({super.key});

  @override
  State<RestaurateurOrdersHistoryScreen> createState() =>
      _RestaurateurOrdersHistoryScreenState();
}

class _RestaurateurOrdersHistoryScreenState extends State<RestaurateurOrdersHistoryScreen> {
  List<OrderHistoryEntry> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final all = await MealReservationLocalStore.getOrdersHistory();
    if (!mounted) return;
    setState(() {
      _orders = all.where((o) => o.status == 'Remise').toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amberHoney))
            : _orders.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune commande remise',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return OrderListItem(
                        order: order,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RestaurateurOrderDetailScreen(
                                reservationNumber: order.reservationNumber,
                              ),
                            ),
                          );
                          _loadOrders();
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
