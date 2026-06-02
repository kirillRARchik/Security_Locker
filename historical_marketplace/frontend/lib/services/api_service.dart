import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/order.dart';

class ApiService {
  // Получить все товары
  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getProductsUrl()));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Получить товар по ID
  static Future<Product> getProduct(int id) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getProductUrl(id)));
      
      if (response.statusCode == 200) {
        try {
          return Product.fromJson(json.decode(response.body));
        } catch (e) {
          throw Exception('Ошибка парсинга данных товара: $e');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Товар с ID $id не найден');
      } else {
        throw Exception('Ошибка загрузки товара: код ${response.statusCode}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      // Обработка различных типов сетевых ошибок
      if (errorStr.contains('failed to fetch') || 
          errorStr.contains('failed host lookup') || 
          errorStr.contains('connection refused') ||
          errorStr.contains('socketexception') ||
          errorStr.contains('network is unreachable') ||
          errorStr.contains('connection timed out')) {
        throw Exception('Не удалось подключиться к серверу.\n\n'
            'Возможные причины:\n'
            '• Бэкенд не запущен\n'
            '• Неправильный URL в настройках\n'
            '• Для эмулятора Android используйте: http://10.0.2.2:8080\n'
            '• Для физического устройства используйте IP вашего компьютера');
      }
      throw Exception('Ошибка при загрузке товара: $e');
    }
  }

  // Получить товары по категории
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getProductsByCategoryUrl(category)));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки категории: $e');
    }
  }

  /// Получить заказы текущего пользователя (для статуса доставки).
  static Future<List<OrderModel>> getMyOrders({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/orders/my'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map((json) => OrderModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Сначала войдите в аккаунт');
      } else {
        throw Exception('Ошибка загрузки заказов: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки заказов: $e');
    }
  }

  // Поиск товаров
  static Future<List<Product>> searchProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? customMade,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.searchProductsUrl()).replace(
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (category != null) 'category': category,
          if (minPrice != null) 'minPrice': minPrice.toString(),
          if (maxPrice != null) 'maxPrice': maxPrice.toString(),
          if (customMade != null) 'customMade': customMade.toString(),
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  // Авторизация (пример)
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  // Регистрация (пример)
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  /// Регистрация как продавец. Требует авторизации (JWT).
  /// По успеху пользователю выдаётся роль SELLER.
  static Future<Map<String, dynamic>> becomeSeller({
    required String token,
    required String country,
    required String companyType,
    required String activityField,
    required String companyEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/seller/become'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'country': country,
          'companyType': companyType,
          'activityField': activityField,
          'companyEmail': companyEmail,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        final body = json.decode(response.body);
        final msg = body is Map && body['error'] != null ? body['error'].toString() : 'Уже зарегистрированы как продавец';
        throw Exception(msg);
      } else if (response.statusCode == 401) {
        throw Exception('Сначала войдите в аккаунт');
      } else {
        throw Exception('Ошибка регистрации продавца: ${response.statusCode}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Ошибка при регистрации продавца: $e');
    }
  }

  /// Создание товара продавцом.
  static Future<Product> createProduct({
    required String token,
    required String name,
    required double price,
    required int quantity,
    required bool customMade,
    String? photoUrl,
    String? description,
    String? sizeMeasure,
    String? manufacturingMethod,
    String? category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'photoUrl': photoUrl,
          'name': name,
          'description': description,
          'price': price,
          'quantity': quantity,
          'customMade': customMade,
          'sizeMeasure': sizeMeasure,
          'manufacturingMethod': manufacturingMethod,
          'category': category,
          'authenticityCertificate': null,
          'period': null,
          'material': null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Сначала войдите в аккаунт');
      } else if (response.statusCode == 403) {
        throw Exception('Функция доступна только для продавцов');
      } else {
        throw Exception('Ошибка создания товара: ${response.statusCode}');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Ошибка при создании товара: $e');
    }
  }

  /// Загрузка фото товара. Возвращает URL, сохранённый на бэкенде.
  static Future<String> uploadProductPhoto({
    required String token,
    required List<int> bytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/upload-photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final data = json.decode(body);
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Сервер не вернул URL изображения');
      }
      return url;
    } else if (streamed.statusCode == 401) {
      throw Exception('Сначала войдите в аккаунт');
    } else if (streamed.statusCode == 403) {
      throw Exception('Функция доступна только для продавцов');
    } else {
      throw Exception('Ошибка загрузки фото: ${streamed.statusCode}');
    }
  }
}


