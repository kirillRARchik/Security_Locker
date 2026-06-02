import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int selectedPayment = 0; // 0 - банк, 1 - новая карта

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => context.pop(),
        ),
        title: const Text('Оформление заказа', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _block(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green[400]),
                    const SizedBox(width: 6),
                    const Text('Адрес получения', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Почтовый пункт\nАдресатово 24/2', style: TextStyle(color: Colors.black87)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Изменить адрес', style: TextStyle(color: Colors.green)),
                  ),
                ),
              ],
            ),
          ),

          _block(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Доставим 25 ноября', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('3 товара · 4 кг', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(3, (i) => _thumb()).toList(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
            child: const Text('Способ оплаты', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          Row(
            children: [
              Expanded(
                child: _paymentOption(
                  selected: selectedPayment == 0,
                  icon: Icons.account_balance,
                  title: 'Банк',
                  subtitle: '**9999  VISA',
                  onTap: () => setState(() => selectedPayment = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _paymentOption(
                  selected: selectedPayment == 1,
                  icon: Icons.credit_card,
                  title: 'Новая карта',
                  subtitle: '',
                  onTap: () => setState(() => selectedPayment = 1),
                ),
              ),
            ],
          ),

          _block(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ваш заказ', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Text('Товары', style: TextStyle(color: Colors.black54)),
                      SizedBox(height: 4),
                      Text('Доставка', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 22),
                    Text('36 000 тг'),
                    SizedBox(height: 4),
                    Text('Без доплат', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),

          _block(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Итого', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('36 000 тг', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 80), // нижний отступ под кнопку
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Оплатить заказ', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _block({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _thumb() {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.red[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text('12 000 тг', style: TextStyle(color: Colors.white, fontSize: 10)),
      ),
    );
  }

  Widget _paymentOption({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.green : Colors.grey.shade300, width: 1.4),
          boxShadow: selected
              ? [BoxShadow(color: Colors.green.withAlpha(20), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.green : Colors.grey[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}