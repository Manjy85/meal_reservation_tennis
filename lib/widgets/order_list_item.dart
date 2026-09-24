import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// Port of OrdersAdapter.kt / item_meal_reservation_restaurateur_order.xml
class OrderListItem extends StatelessWidget {
  final OrderHistoryEntry order;
  final VoidCallback onTap;

  const OrderListItem({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardOverlay,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.reservationNumber,
              style: const TextStyle(
                color: AppColors.amberHoney,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.date.isEmpty ? '-' : order.date} | ${order.service.isEmpty ? '-' : order.service}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              order.status,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              formatEur(order.total),
              style: const TextStyle(
                color: AppColors.amberHoney,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
