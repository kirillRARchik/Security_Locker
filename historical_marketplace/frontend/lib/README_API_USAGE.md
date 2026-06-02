# Пример использования API в Flutter

## Быстрый старт

### 1. Обновите HomeScreen для загрузки реальных данных:

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedProducts = await ApiService.getProducts();
      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки товаров: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              ElevatedButton(
                onPressed: loadProducts,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    // Ваш существующий UI с использованием products
    return Scaffold(
      // ... ваш код
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(product: product);
        },
      ),
    );
  }
}
```

### 2. Пример поиска товаров:

```dart
Future<void> searchProducts(String query) async {
  try {
    final results = await ApiService.searchProducts(
      query: query,
      category: 'оружие',
      minPrice: 1000,
      maxPrice: 50000,
    );
    
    setState(() {
      products = results;
    });
  } catch (e) {
    print('Ошибка поиска: $e');
  }
}
```

### 3. Пример авторизации:

```dart
Future<void> login(String email, String password) async {
  try {
    final response = await ApiService.login(email, password);
    final token = response['token'];
    
    // Сохраните токен (например, в SharedPreferences)
    // await storage.write(key: 'token', value: token);
    
    // Используйте токен в последующих запросах
    print('Успешная авторизация!');
  } catch (e) {
    print('Ошибка авторизации: $e');
  }
}
```

---

## Структура файлов:

```
lib/
├── config/
│   └── api_config.dart          # Настройки API (URL, endpoints)
├── models/
│   └── product.dart             # Модель Product
├── services/
│   └── api_service.dart          # Сервис для работы с API
└── screens/
    └── home_screen.dart          # Экран с использованием API
```

---

## Важно:

1. **Убедитесь, что бэкенд запущен** на порту 8080
2. **Проверьте URL** в `api_config.dart` для вашей платформы
3. **Обрабатывайте ошибки** - всегда используйте try-catch
4. **Показывайте индикатор загрузки** при работе с API

---

## Следующие шаги:

1. Добавьте модели для других сущностей (Order, User, Review и т.д.)
2. Расширьте ApiService новыми методами
3. Добавьте кэширование данных (например, с помощью `shared_preferences`)
4. Реализуйте обработку JWT токенов для авторизованных запросов


