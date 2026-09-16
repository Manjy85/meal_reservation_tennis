import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// Port of MealReservationRestaurateurProductFormActivity.kt, now wired to
/// real persistence (create/edit/delete a Product).
class RestaurateurProductFormScreen extends StatefulWidget {
  final Product? product;

  const RestaurateurProductFormScreen({super.key, this.product});

  @override
  State<RestaurateurProductFormScreen> createState() => _RestaurateurProductFormScreenState();
}

class _RestaurateurProductFormScreenState extends State<RestaurateurProductFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late bool _enabled;

  String? _nameError;
  String? _priceError;
  bool _saving = false;
  List<String> _existingCategories = [];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.unitPrice.toStringAsFixed(2),
    );
    _categoryController = TextEditingController(text: product?.category ?? '');
    _enabled = product?.enabled ?? true;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final products = await MealReservationLocalStore.getProducts();
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
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);

    setState(() {
      _nameError = null;
      _priceError = null;
    });

    if (name.isEmpty) {
      setState(() => _nameError = 'Nom requis');
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _priceError = 'Prix invalide (ex: 9.90)');
      return;
    }

    setState(() => _saving = true);
    await MealReservationLocalStore.saveProduct(
      Product(
        id: widget.product?.id ?? '',
        name: name,
        description: _descriptionController.text.trim(),
        unitPrice: price,
        enabled: _enabled,
        category: _categoryController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final product = widget.product;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.prussianBlue,
        title: const Text('Supprimer le produit', style: TextStyle(color: Colors.white)),
        content: Text(
          'Supprimer "${product.name}" du catalogue ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.deleteRedStrong)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await MealReservationLocalStore.deleteProduct(product.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifier le produit' : 'Nouveau produit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? "Modification d'un article." : "Creation d'un article.",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _nameController,
                hint: 'Nom du produit',
                errorText: _nameError,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _descriptionController,
                hint: 'Description',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _priceController,
                hint: 'Prix (ex: 9.90)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                errorText: _priceError,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _categoryController,
                hint: 'Famille (ex: Boissons)',
              ),
              if (_existingCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _existingCategories
                      .map(
                        (category) => ActionChip(
                          label: Text(category),
                          backgroundColor: AppColors.cardOverlay,
                          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                          onPressed: () => setState(() => _categoryController.text = category),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text('Produit disponible', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
                ],
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: _saving ? 'Enregistrement...' : 'Enregistrer',
                height: 52,
                onPressed: _saving ? null : _save,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 10),
                AppPrimaryButton(
                  label: 'Supprimer le produit',
                  height: 52,
                  backgroundColor: AppColors.deleteRedStrong,
                  onPressed: _saving ? null : _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
