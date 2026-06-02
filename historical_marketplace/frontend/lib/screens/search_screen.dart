import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../services/api_service.dart';

const _placeholderImageUrl = 'https://steel-masters.ru/sites/default/files/styles/product_large/public/2019-11/ba4b3dffb9c1644606a0a55ee81bb674.jpg';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Product> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  bool _searchedOnce = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _runSearch(widget.initialQuery!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _searchedOnce = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searchedOnce = true;
    });
    try {
      final list = await ApiService.searchProducts(query: query);
      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
          _results = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Поиск товаров',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) _runSearch(v.trim());
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _controller.clear();
                _onQueryChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_searchedOnce) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Введите название товара или категорию',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _runSearch(_controller.text.trim()),
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено по запросу «${_controller.text}»',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return _SearchProductCard(
          product: product,
          onTap: () {
            if (product.id != null) context.push('/product/${product.id}');
          },
          onOrderTap: () => context.go('/cart'),
        );
      },
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onOrderTap;

  const _SearchProductCard({required this.product, this.onTap, this.onOrderTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.photoUrl ?? _placeholderImageUrl;
    final sellerName = product.seller?.businessArea ?? 'Кузница';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 70, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.favorite_border, color: Colors.green, size: 24),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.price.toInt()} тг',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(sellerName, style: const TextStyle(fontSize: 13)),
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 15),
                      const SizedBox(width: 4),
                      Text('4.5, 12 оценок', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onOrderTap ?? () {},
                      icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                      label: const Text('Заказать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
