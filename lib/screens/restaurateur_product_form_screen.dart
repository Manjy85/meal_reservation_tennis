import 'package:flutter/material.dart';

import '../data/store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Create / edit / delete a product, with a live preview of how it will look
/// on the client menu.
class RestaurateurProductFormScreen extends StatefulWidget {
  final Product? product;

  const RestaurateurProductFormScreen({super.key, this.product});

  @override
  State<RestaurateurProductFormScreen> createState() => _RestaurateurProductFormScreenState();
}

class _RestaurateurProductFormScreenState extends State<RestaurateurProductFormScreen> {
  late final TextEditingController _nameController = TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.product?.description ?? '');
  late final TextEditingController _priceController = TextEditingController(
    text: widget.product == null ? '' : widget.product!.unitPrice.toStringAsFixed(2).replaceAll('.', ','),
  );
  late final TextEditingController _categoryController = TextEditingController(text: widget.product?.category ?? '');
  late bool _enabled = widget.product?.enabled ?? true;

  String? _nameError;
  String? _priceError;
  bool _saving = false;
  List<String> _existingCategories = [];

  bool get _isEditing => widget.product != null;

  double? get _price => double.tryParse(_priceController.text.trim().replaceAll(',', '.'));

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final List<Product> products;
    try {
      products = await MealReservationStore.getProducts();
    } catch (_) {
      return; // suggestions are optional
    }
    final categories = products
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;
    setState(() => _existingCategories = categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = _price;

    setState(() {
      _nameError = name.isEmpty ? 'Nom requis' : null;
      _priceError = price == null || price <= 0 ? 'Prix invalide (ex : 9,90)' : null;
    });
    if (_nameError != null || _priceError != null) return;

    setState(() => _saving = true);
    try {
      await MealReservationStore.saveProduct(
        Product(
          id: widget.product?.id ?? '',
          name: name,
          description: _descriptionController.text.trim(),
          unitPrice: price!,
          enabled: _enabled,
          category: _categoryController.text.trim(),
        ),
      );
    } catch (e) {
      _showError('Échec de l’enregistrement : $e');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete() async {
    final product = widget.product;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('Supprimer cet article ?'),
        content: Text('« ${product.name} » sera retiré de la carte. Les commandes déjà passées ne sont pas modifiées.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await MealReservationStore.deleteProduct(product.id);
    } catch (e) {
      _showError('Échec de la suppression : $e');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l’article' : 'Nouvel article'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              tooltip: 'Supprimer',
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([_nameController, _descriptionController, _priceController, _categoryController]),
            builder: (context, _) => _Preview(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              price: _price,
              category: _categoryController.text.trim(),
              enabled: _enabled,
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionTitle('Informations'),
          AppTextField(
            controller: _nameController,
            label: 'Nom de l’article',
            hint: 'ex : Burger du chef',
            textInputAction: TextInputAction.next,
            errorText: _nameError,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _descriptionController,
            label: 'Description (optionnelle)',
            hint: 'Ingrédients, allergènes…',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _priceController,
            label: 'Prix (€)',
            hint: '9,90',
            icon: Icons.euro_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _priceError,
          ),
          const SizedBox(height: 24),
          const AppSectionTitle('Famille'),
          AppTextField(
            controller: _categoryController,
            label: 'Famille',
            hint: 'ex : Boissons',
            icon: Icons.category_outlined,
          ),
          if (_existingCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _existingCategories
                  .map((category) => ChoiceChip(
                        label: Text(category),
                        selected: _categoryController.text.trim() == category,
                        onSelected: (_) => setState(() => _categoryController.text = category),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: SwitchListTile(
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Visible sur la carte', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _enabled ? 'Les clients peuvent le commander' : 'Masqué pour les clients',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        child: AppPrimaryButton(
          label: _isEditing ? 'Enregistrer les modifications' : 'Ajouter à la carte',
          loading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}

/// How the product will appear in the client catalogue.
class _Preview extends StatelessWidget {
  final String name;
  final String description;
  final double? price;
  final String category;
  final bool enabled;

  const _Preview({
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'APERÇU CLIENT',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AppCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryAvatar(label: '$category $name', size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'Nom de l’article' : name, style: Theme.of(context).textTheme.titleMedium),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        price == null ? '– €' : formatEur(price!),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                AddButton(onPressed: () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
