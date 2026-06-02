import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Адресатово 24/2', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w400)),
                Stack(
                  children: [
                    Icon(Icons.notifications_none, size: 30, color: Colors.grey[700]),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(Icons.circle, size: 13, color: Colors.greenAccent,)
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поиск
            InkWell(
              onTap: () => context.push('/search'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.green, size: 28),
                    SizedBox(width: 8),
                    Text('Поиск', style: TextStyle(fontSize: 18, color: Colors.green)),
                  ],
                ),
              ),
            ),
            // Баннеp/большое изображение
            Container(
              height: 145,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
            // Список карточек
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ProductCard(
                  productId: 1,
                  onTap: () => context.push('/product/1'),
                  onOrderTap: () => context.go('/cart'),
                ),
                _ProductCard(
                  productId: 2,
                  onTap: () => context.push('/product/2'),
                  onOrderTap: () => context.go('/cart'),
                ),
              ],
            ),
          ],
        ),
      ),
      // BottomNavigationBar теперь управляется MainNavigationScreen
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int? productId;
  final VoidCallback? onTap;
  final VoidCallback? onOrderTap;

  const _ProductCard({this.productId, this.onTap, this.onOrderTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Картинка товара
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Center(child: Icon(Icons.image, size: 70, color: Colors.grey[600])),
                Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.favorite_border, color: Colors.green, size: 28),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('12.000 тг', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Text('Кузница', style: TextStyle(fontSize: 13)),
                Text('Шлем рыцарский', style: TextStyle(fontSize: 13)),
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 15),
                    SizedBox(width: 4),
                    Text('4.5, 12 оценок', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 7),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onOrderTap ?? () {},
                    icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                    label: const Text('Заказать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
