import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'catalog_screen.dart';

/// Экран добавления товара продавцом.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool? _customMade;
  String? _category;

  final List<String> _sizeOptions = [];
  final List<String> _manufacturingOptions = [];

  bool _loading = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;
  XFile? _pickedFile;

  static const _categories = kCatalogCategories;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() {
        _pickedFile = picked;
        _uploadingPhoto = true;
      });

      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        _showSnack('Сначала войдите в аккаунт');
        if (mounted) context.push('/login');
        return;
      }

      final bytes = await picked.readAsBytes();
      final url = await ApiService.uploadProductPhoto(
        token: token,
        bytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _showSnack(e.toString().replaceFirst('Exception: ', 'Ошибка загрузки фото: '));
    }
  }

  Future<void> _addSizeOption() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить размер'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Например: Размер M'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _sizeOptions.add(result));
    }
  }

  Future<void> _addManufacturingOption() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить вариант изготовления'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Например: Нержавейка (2 мм); Полировка'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _manufacturingOptions.add(result));
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.replaceAll(',', '.').trim();
    final quantityStr = _quantityController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showSnack('Укажите название товара');
      return;
    }
    if (priceStr.isEmpty) {
      _showSnack('Укажите цену товара');
      return;
    }
    final price = double.tryParse(priceStr);
    if (price == null || price <= 0) {
      _showSnack('Некорректная цена');
      return;
    }
    if (quantityStr.isEmpty) {
      _showSnack('Укажите количество товаров');
      return;
    }
    final quantity = int.tryParse(quantityStr);
    if (quantity == null || quantity <= 0) {
      _showSnack('Некорректное количество');
      return;
    }
    if (_customMade == null) {
      _showSnack('Выберите, изготавливается ли товар на заказ');
      return;
    }
    if (_category == null || _category!.isEmpty) {
      _showSnack('Выберите категорию товара');
      return;
    }

    setState(() => _loading = true);
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        _showSnack('Сначала войдите в аккаунт');
        if (mounted) context.push('/login');
        return;
      }

      await ApiService.createProduct(
        token: token,
        name: name,
        price: price,
        quantity: quantity,
        customMade: _customMade!,
        photoUrl: _photoUrl,
        description: description.isNotEmpty ? description : null,
        sizeMeasure: _sizeOptions.isNotEmpty ? _sizeOptions.join('; ') : null,
        manufacturingMethod: _manufacturingOptions.isNotEmpty ? _manufacturingOptions.join('; ') : null,
        category: _category,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар добавлен'), backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => context.pop(),
        ),
        title: const Text('Добавление товара', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _uploadingPhoto
                      ? const CircularProgressIndicator()
                      : (_photoUrl != null && _photoUrl!.isNotEmpty)
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _photoUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 40, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text(
                                  'Загрузите изображение товара',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildField(_nameController, 'Название товара'),
            const SizedBox(height: 10),
            _buildField(
              _priceController,
              'Цена товара',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              suffix: const Text('₸', style: TextStyle(color: Colors.green)),
            ),
            const SizedBox(height: 10),
            _buildField(
              _quantityController,
              'Количество товаров',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _buildCustomMadeDropdown(),
            const SizedBox(height: 10),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildSizesSection(),
            const SizedBox(height: 16),
            _buildManufacturingSection(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Добавить товар'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.green[200]),
        filled: true,
        fillColor: Colors.green[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[100]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[100]!),
        ),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(child: suffix),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Описание товара',
        hintStyle: TextStyle(color: Colors.green[200]),
        filled: true,
        fillColor: Colors.green[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[100]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[100]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildCustomMadeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: _customMade,
          hint: Text('Изготовление по заказу?', style: TextStyle(color: Colors.green[700])),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
          items: const [
            DropdownMenuItem(value: true, child: Text('Да')),
            DropdownMenuItem(value: false, child: Text('Нет')),
          ],
          onChanged: (value) => setState(() => _customMade = value),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          hint: Text('Категория товара', style: TextStyle(color: Colors.green[700])),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
          items: _categories
              .map((c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _category = value),
        ),
      ),
    );
  }

  Widget _buildChips(List<String> values, VoidCallback onAdd) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Chip(
            label: Text(v),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => values.remove(v)),
          ),
        ActionChip(
          label: const Icon(Icons.add, size: 18),
          onPressed: onAdd,
        ),
      ],
    );
  }

  Widget _buildSizesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 6),
                Text('Размерная мерка'),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Таблица размеров'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildChips(_sizeOptions, _addSizeOption),
      ],
    );
  }

  Widget _buildManufacturingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 6),
            Text('Выбор изготовления'),
          ],
        ),
        const SizedBox(height: 8),
        _buildChips(_manufacturingOptions, _addManufacturingOption),
      ],
    );
  }
}

