class ApiConfig {
  // Базовый URL вашего Java-бэкенда
  // 
  // ВАЖНО: Выберите правильный URL в зависимости от того, где запущено приложение:
  //
  // 1. Для веб-браузера (Chrome, Edge и т.д.):
  //    static const String baseUrl = 'http://localhost:8080';
  //
  // 2. Для эмулятора Android:
  //    static const String baseUrl = 'http://10.0.2.2:8080';
  //    (10.0.2.2 - это специальный адрес эмулятора, указывающий на localhost хоста)
  //
  // 3. Для физического Android/iOS устройства:
  //    Узнайте IP адрес вашего компьютера в локальной сети:
  //    - Windows: ipconfig (ищите IPv4 адрес, например 192.168.1.100)
  //    - Mac/Linux: ifconfig или ip addr
  //    static const String baseUrl = 'http://192.168.1.100:8080';
  //
  // 4. Убедитесь, что бэкенд запущен и доступен по выбранному адресу!
  
  // Для локальной разработки (веб):
  static const String baseUrl = 'http://localhost:8080';
  
  // Раскомментируйте одну из строк ниже для мобильных устройств:
  // static const String baseUrl = 'http://10.0.2.2:8080';  // Android эмулятор
  // static const String baseUrl = 'http://192.168.1.100:8080';  // Физическое устройство (замените на ваш IP)
  
  // API endpoints
  static const String products = '/api/products';
  static const String login = '/api/login';
  static const String auth = '/api/auth';
  static const String orders = '/api/orders';
  static const String cart = '/api/cart';
  static const String reviews = '/api/reviews';
  
  // Полный URL для эндпоинта
  static String getProductsUrl() => '$baseUrl/api/products';
  static String getProductUrl(int id) => '$baseUrl/api/products/$id';
  static String getProductsByCategoryUrl(String category) => '$baseUrl$products/category/${Uri.encodeComponent(category)}';
  static String searchProductsUrl() => '$baseUrl$products/search';
  static String getAuthUrl(String endpoint) => '$baseUrl$auth/$endpoint';
  static String getOrdersUrl() => '$baseUrl$orders';
  static String getCartUrl() => '$baseUrl$cart';
  static String getReviewsUrl(int productId) => '$baseUrl$reviews/product/$productId';
}


