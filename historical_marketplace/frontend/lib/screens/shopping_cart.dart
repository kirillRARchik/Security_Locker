import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CartItem {
  final String title;
  final int price;
  final String size;
  final String type;
  int quantity;

  CartItem({
    required this.title,
    required this.price,
    required this.size,
    required this.type,
    this.quantity = 1,
  });
}

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  List<CartItem> cartItems = [
    CartItem(title: 'Кузница / Шлем средневековый рыцарский', price: 12000, size: 'M', type: 'готовое изделие'),
    CartItem(title: 'Кузница / Шлем средневековый рыцарский', price: 12000, size: 'M', type: 'готовое изделие'),
  ];

  @override
  Widget build(BuildContext context) {
    int totalAmount = cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
    int totalCount = cartItems.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Text('Адресатово 24/2', style: TextStyle(color: Colors.black)),
            Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        itemCount: cartItems.length,
        itemBuilder: (context, idx) {
          final item = cartItems[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Картинка
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.image, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  // Описание
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.price} тг', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text(item.title, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('Размер ${item.size}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        Text('Тип: ${item.type}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (item.quantity > 1) item.quantity--;
                                });
                              },
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () {
                                setState(() {
                                  item.quantity++;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Купить'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Удалить
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        cartItems.removeAt(idx);
                      });
                    },
                  ),
                  Icon(Icons.more_vert, color: Colors.grey[600]),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: ElevatedButton(
          onPressed: () => context.push('/checkout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Купить все товары', style: TextStyle(fontSize: 18, color: Colors.white)),
              Text('$totalCount шт., $totalAmount тг', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}