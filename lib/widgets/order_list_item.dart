import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// Order card for the restaurateur lists: who, when, what, how much, and -
/// when [onAdvance] is given - a one-tap button to move the order to its
/// next status (kitchen-display style).
class OrderListItem extends StatelessWidget {
  final OrderHistoryEntry order;
  final VoidCallback onTap;
  final VoidCallback? onAdvance;

  const OrderListItem({super.key, required this.order, required this.onTap, this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final index = orderStatuses.indexOf(order.status);
    final next = index >= 0 && index < orderStatuses.length - 1 ? orderStatuses[index + 1] : null;
    final nextStyle = next == null ? null : orderStatusStyle(next);
    final items = order.products.where((p) => p.qty > 0).map((p) => '${p.qty}× ${p.name}').join(', ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.clientName.isEmpty ? order.email : order.clientName,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.reservationNumber} · ${formatLongDate(order.date)} · ${order.service}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(items, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.35)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatEur(order.total),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              if (onAdvance != null && nextStyle != null)
                FilledButton.icon(
                  onPressed: onAdvance,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: nextStyle.color,
                    foregroundColor: AppColors.background,
                  ),
                  icon: Icon(nextStyle.icon, size: 18),
                  label: Text(nextStyle.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
