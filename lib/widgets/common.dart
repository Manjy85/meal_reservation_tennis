import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ---- Formatting -----------------------------------------------------------

String formatEur(double amount) => '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';

const _weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const _months = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const _monthsShort = [
  'JANV', 'FÉVR', 'MARS', 'AVR', 'MAI', 'JUIN',
  'JUIL', 'AOÛT', 'SEPT', 'OCT', 'NOV', 'DÉC',
];

/// Parses the app's stored date format (dd/MM/yyyy).
DateTime? parseFrDate(String value) {
  final parts = value.split('/');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null || m < 1 || m > 12) return null;
  return DateTime(y, m, d);
}

/// "Samedi 12 octobre" (falls back to the raw value if it can't be parsed).
String formatLongDate(String value) {
  final d = parseFrDate(value);
  if (d == null) return value;
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

// ---- Feedback -------------------------------------------------------------

/// Shown when a Firestore read fails (offline, or rejected by the security
/// rules - e.g. an admin account missing from the `admins` collection).
class AppErrorView extends StatelessWidget {
  final Object? error;
  const AppErrorView(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Impossible de charger les données',
      message: '$error',
    );
  }
}

const Widget appLoader = Center(
  child: Padding(
    padding: EdgeInsets.all(24),
    child: CircularProgressIndicator(),
  ),
);

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const AppEmptyState({super.key, required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.surfaceHigh, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- Buttons --------------------------------------------------------------

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onAmber),
          )
        : Text(label);
    return SizedBox(
      width: double.infinity,
      child: icon == null || loading
          ? FilledButton(onPressed: loading ? null : onPressed, child: child)
          : FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: child),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = color == null
        ? null
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color!.withValues(alpha: 0.5)),
          );
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
          : OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon), label: Text(label)),
    );
  }
}

// ---- Inputs ---------------------------------------------------------------

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final int maxLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        errorMaxLines: 2,
        counterText: '',
        alignLabelWithHint: widget.maxLines > 1,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _hidden ? 'Afficher' : 'Masquer',
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}

// ---- Layout ---------------------------------------------------------------

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Logo + title block at the top of the login / signup screens.
class AppBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;

  const AppBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.restaurant_rounded,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFC94D), AppColors.amber],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.onAmber, size: 32),
        ),
        const SizedBox(height: 24),
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4)),
      ],
    );
  }
}

/// Fixed action area at the bottom of a screen (checkout-style CTA).
class AppBottomBar extends StatelessWidget {
  final Widget child;
  const AppBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child),
      ),
    );
  }
}

// ---- Domain visuals -------------------------------------------------------

/// Calendar-style day badge ("12 / OCT") for a dd/MM/yyyy date.
class DateBadge extends StatelessWidget {
  final String date;
  final bool muted;

  const DateBadge(this.date, {super.key, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final d = parseFrDate(date);
    final accent = muted ? AppColors.textMuted : AppColors.amber;
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            d == null ? '--' : '${d.day}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
          Text(
            d == null ? '' : _monthsShort[d.month - 1],
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: accent),
          ),
        ],
      ),
    );
  }
}

/// Illustration for a product without a photo: an icon and tint guessed
/// from its family / name (drinks, burgers, desserts...).
class CategoryAvatar extends StatelessWidget {
  final String label;
  final double size;

  const CategoryAvatar({super.key, required this.label, this.size = 52});

  static const _rules = <(List<String>, IconData, Color)>[
    (['dessert', 'glace', 'gâteau', 'gateau', 'crêpe', 'crepe', 'tarte', 'sucré'], Icons.icecream_rounded, Color(0xFFF472B6)),
    (['café', 'cafe', 'thé', 'chocolat'], Icons.local_cafe_rounded, Color(0xFFD4A373)),
    (['boisson', 'soda', 'eau', 'jus', 'bière', 'biere', 'vin', 'cocktail', 'drink'], Icons.local_drink_rounded, Color(0xFF60A5FA)),
    (['burger'], Icons.lunch_dining_rounded, AppColors.amber),
    (['pizza'], Icons.local_pizza_rounded, Color(0xFFFB923C)),
    (['frite', 'snack', 'accompagnement', 'chips'], Icons.fastfood_rounded, Color(0xFFFACC15)),
    (['salade', 'végé', 'vege', 'veggie', 'légume', 'legume'], Icons.eco_rounded, AppColors.success),
    (['sandwich', 'bagel', 'pain', 'wrap', 'panini', 'viennoiserie'], Icons.bakery_dining_rounded, Color(0xFFE9C46A)),
    (['plat', 'menu', 'repas'], Icons.dinner_dining_rounded, Color(0xFFA78BFA)),
  ];

  @override
  Widget build(BuildContext context) {
    final text = label.toLowerCase();
    var icon = Icons.restaurant_rounded;
    var color = AppColors.info;
    for (final (keywords, ruleIcon, ruleColor) in _rules) {
      if (keywords.any(text.contains)) {
        icon = ruleIcon;
        color = ruleColor;
        break;
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class OrderStatusStyle {
  final String label;
  final Color color;
  final IconData icon;
  const OrderStatusStyle(this.label, this.color, this.icon);
}

/// Display label / color / icon for a stored order status.
OrderStatusStyle orderStatusStyle(String status) {
  switch (status) {
    case 'En preparation':
      return const OrderStatusStyle('En préparation', AppColors.info, Icons.soup_kitchen_rounded);
    case 'Prete':
      return const OrderStatusStyle('Prête', AppColors.success, Icons.check_circle_rounded);
    case 'Remise':
      return const OrderStatusStyle('Remise', AppColors.neutral, Icons.task_alt_rounded);
    default:
      return const OrderStatusStyle('En attente', AppColors.amber, Icons.schedule_rounded);
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = orderStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 5),
          Text(style.label, style: TextStyle(color: style.color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Delivery-app style tracker: Reçue -> En préparation -> Prête -> Remise.
class OrderProgress extends StatelessWidget {
  final String status;
  final List<String> statuses;

  const OrderProgress({super.key, required this.status, required this.statuses});

  static const _stepLabels = ['Reçue', 'Préparation', 'Prête', 'Remise'];

  @override
  Widget build(BuildContext context) {
    final current = statuses.indexOf(status).clamp(0, statuses.length - 1);
    final color = orderStatusStyle(status).color;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < statuses.length; i++) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= current ? color : AppColors.surfaceHigh,
                  border: Border.all(color: i <= current ? color : AppColors.outline, width: 2),
                ),
              ),
              if (i < statuses.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i < current ? color : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _stepLabels.length && i < statuses.length; i++)
              Text(
                _stepLabels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                  color: i <= current ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---- Quantity -------------------------------------------------------------

/// Round amber "+" used to add a product the first time.
class AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.amber,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.add_rounded, color: AppColors.onAmber),
        ),
      ),
    );
  }
}

/// Pill-shaped "- 2 +" stepper.
class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const QtyStepper({super.key, required this.qty, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepIcon(
            icon: qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
            onTap: onMinus,
            tooltip: qty <= 1 ? 'Retirer' : 'Moins',
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          _StepIcon(icon: Icons.add_rounded, onTap: onPlus, tooltip: 'Plus', highlighted: true),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool highlighted;

  const _StepIcon({required this.icon, required this.onTap, required this.tooltip, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: highlighted ? AppColors.amber : AppColors.textSecondary),
        ),
      ),
    );
  }
}
