import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Список категорий для каталога (название = значение для API).
const List<String> kCatalogCategories = [
  'Мечи',
  'Шлема',
  'Щиты',
  'Униформа РККА',
  'Доспехи',
  'Аксессуары',
];

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.grey[900],
          elevation: 0,
          title: const Text(
            'Каталог',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
          ),
          centerTitle: false,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Строка поиска (светло-зелёная)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.green[700], size: 22),
                    const SizedBox(width: 8),
                    Icon(Icons.search, color: Colors.green[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Поиск',
                      style: TextStyle(fontSize: 16, color: Colors.green[800]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Сетка категорий
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: kCatalogCategories.length,
              itemBuilder: (context, index) {
                final category = kCatalogCategories[index];
                return _CategoryCard(
                  title: category,
                  onTap: () => context.push('/catalog/category/${Uri.encodeComponent(category)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _CategoryCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    _iconForCategory(title),
                    size: 48,
                    color: Colors.green[700],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    if (category.contains('Меч')) return Icons.flash_on;
    if (category.contains('Шлем')) return Icons.security;
    if (category.contains('Щит')) return Icons.shield;
    if (category.contains('РККА') || category.contains('Униформа')) return Icons.checkroom;
    if (category.contains('Доспех')) return Icons.shield;
    if (category.contains('Аксессуар')) return Icons.diamond;
    return Icons.category;
  }
}
