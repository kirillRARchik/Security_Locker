import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  OrderModel? _latestDeliveryOrder;
  bool _loadingDelivery = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryStatus();
  }

  Future<void> _loadDeliveryStatus() async {
    setState(() => _loadingDelivery = true);
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _latestDeliveryOrder = null;
        _loadingDelivery = false;
      });
      return;
    }

    try {
      final orders = await ApiService.getMyOrders(token: token);
      final filtered = orders.where((o) => o.status.toUpperCase() != 'CANCELLED').toList();
      if (!mounted) return;
      setState(() {
        _latestDeliveryOrder = filtered.isNotEmpty ? filtered.first : null;
        _loadingDelivery = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latestDeliveryOrder = null;
        _loadingDelivery = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => context.push('/login'),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage('https://api.dicebear.com/7.x/bottts/svg?seed=profile'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Войти',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, size: 28, color: Colors.grey),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, size: 28, color: Colors.grey),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          // Доставка статус — показываем только после покупки (если есть заказ)
          if (!_loadingDelivery && _latestDeliveryOrder != null)
            _DeliveryBanner(order: _latestDeliveryOrder!),

          // Основные секции
          _ProfileSection([
            _ProfileTile('Заказы', () {}),
            _ProfileTile('Возвраты', () {}),
            _ProfileTile('Купленные товары', () {}),
            _ProfileTile('Избранное', () {}),
          ]),

          _ProfileSection([
            _ProfileTile('Настройки', () {}),
            _ProfileTile('Способ оплаты', () {}),
            _ProfileTile('О приложении', () {}),
            _ProfileTile('Помощь', () {}),
          ]),

          _ProfileSection([
            _ProfileTile('Стать продавцом', () => context.push('/seller-registration')),
            _ProfileTile('Добавить товар', () => context.push('/add-product')),
          ]),
          const SizedBox(height: 24),
        ],
      ),
      // BottomNavigationBar управляется MainNavigationScreen
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  final OrderModel order;
  const _DeliveryBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status.toUpperCase();
    final isDelivered = status == 'DELIVERED';
    final inTransitStatuses = {'PENDING', 'PAID', 'PROCESSING', 'SHIPPED'};
    final isInTransit = inTransitStatuses.contains(status);

    final title = isDelivered
        ? 'Доставлено'
        : isInTransit
            ? 'В пути'
            : 'Статус заказа';

    final titleColor = isDelivered ? Colors.green : Colors.orange[700];

    final addressLine = order.address?.line1?.trim();
    final subtitle = (addressLine != null && addressLine.isNotEmpty)
        ? 'Почтовый пункт $addressLine'
        : 'Почтовый пункт';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
            fontSize: 19,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
        trailing: Container(
          width: 40,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final List<Widget> children;
  const _ProfileSection(this.children);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _ProfileTile(this.title, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400)),
      trailing: const Icon(Icons.chevron_right, color: Colors.green, size: 24),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      horizontalTitleGap: 2,
    );
  }
}
