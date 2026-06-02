# Руководство по интеграции Flutter + Java Backend

## 📋 Что было сделано:

### 1. **Настройка CORS в Java-бэкенде**
   - Добавлена конфигурация CORS в `WebConfig.java`
   - Разрешены запросы с Flutter-приложения

### 2. **Структура Flutter-приложения:**
   ```
   lib/
   ├── config/
   │   └── api_config.dart          # Конфигурация API (URL, endpoints)
   ├── models/
   │   └── product.dart             # Модель данных товара
   ├── services/
   │   └── api_service.dart          # Сервис для работы с API
   └── screens/
       └── home_screen.dart         # Экран с использованием API
   ```

### 3. **Добавлен HTTP-пакет**
   - В `pubspec.yaml` добавлен `http: ^1.2.0`

---

## 🚀 Как использовать:

### Шаг 1: Установите зависимости Flutter
```bash
cd frontend/historical_marketplace
flutter pub get
```

### Шаг 2: Запустите Java-бэкенд
```bash
cd backend/backend/marketplace
# Запустите Spring Boot приложение (например, через IDE или mvn spring-boot:run)
```

Убедитесь, что бэкенд работает на `http://localhost:8080`

### Шаг 3: Настройте URL в `api_config.dart`
В файле `lib/config/api_config.dart` выберите правильный URL:

- **Для веб-версии (Chrome):** `http://localhost:8080`
- **Для Android эмулятора:** `http://10.0.2.2:8080`
- **Для физического устройства:** `http://192.168.1.100:8080` (замените на IP вашего компьютера)

### Шаг 4: Используйте API в коде

#### Пример загрузки товаров:
```dart
import 'package:historical_marketplace/services/api_service.dart';
import 'package:historical_marketplace/models/product.dart';

// В StatefulWidget:
List<Product> products = [];

@override
void initState() {
  super.initState();
  loadProducts();
}

Future<void> loadProducts() async {
  try {
    products = await ApiService.getProducts();
    setState(() {});
  } catch (e) {
    print('Ошибка загрузки: $e');
  }
}
```

#### Пример поиска:
```dart
List<Product> results = await ApiService.searchProducts(
  query: 'шлем',
  category: 'оружие',
  minPrice: 1000,
  maxPrice: 50000,
);
```

---

## 🔧 Настройка для разных платформ:

### Android (эмулятор):
```dart
static const String baseUrl = 'http://10.0.2.2:8080';
```

### Android (физическое устройство):
1. Узнайте IP вашего компьютера:
   ```bash
   # Windows:
   ipconfig
   # Linux/Mac:
   ifconfig
   ```
2. Измените URL в `api_config.dart`:
   ```dart
   static const String baseUrl = 'http://ВАШ_IP:8080';
   ```

### iOS Simulator:
```dart
static const String baseUrl = 'http://localhost:8080';
```

### Web (Chrome):
```dart
static const String baseUrl = 'http://localhost:8080';
```

---

## 📝 Доступные API endpoints:

- `GET /api/products` - получить все товары
- `GET /api/products/{id}` - получить товар по ID
- `GET /api/products/search` - поиск товаров
- `POST /api/auth/login` - авторизация
- `POST /api/auth/register` - регистрация
- `GET /api/orders` - список заказов
- `GET /api/cart` - корзина

---

## ⚠️ Важные замечания:

1. **CORS настроен только для локальной разработки**. Для продакшена нужно настроить конкретные домены.

2. **Для мобильных устройств** убедитесь, что:
   - Бэкенд и устройство в одной сети
   - Брандмауэр не блокирует порт 8080

3. **Для авторизации** нужно сохранять JWT токен и добавлять его в заголовки запросов.

4. **Обработка ошибок:** Всегда обрабатывайте ошибки при работе с API (try-catch).

---

## 🐛 Решение проблем:

### Ошибка CORS:
- Проверьте, что CORS настроен в `WebConfig.java`
- Убедитесь, что URL в `api_config.dart` правильный

### Ошибка подключения:
- Проверьте, что бэкенд запущен
- Проверьте порт (должен быть 8080)
- Для мобильных устройств проверьте IP адрес

### Ошибка 401 (Unauthorized):
- Добавьте JWT токен в заголовки запросов
- Проверьте срок действия токена

---

## 📚 Дополнительные ресурсы:

- [Flutter HTTP пакет](https://pub.dev/packages/http)
- [Spring Boot CORS](https://spring.io/guides/gs/rest-service-cors/)
- [REST API Best Practices](https://restfulapi.net/)


