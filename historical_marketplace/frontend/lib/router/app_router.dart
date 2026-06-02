import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/shopping_cart.dart';
import '../screens/profile_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/category_products_screen.dart';
import '../screens/search_screen.dart';
import '../screens/seller_registration_screen.dart';
import '../screens/add_product_screen.dart';

/// Ключ корневого навигатора (для полноэкранных маршрутов: продукт, логин, чекаут)
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Маршруты приложения. Поддержка deep link и единая точка входа.
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (BuildContext context, GoRouterState state) {
      // При необходимости: проверка авторизации и редирект на /login
      // final isLoggedIn = ...; if (!isLoggedIn && state.matchedLocation == '/profile') return '/login';
      return null;
    },
    routes: [
      // Редирект с корня на главную
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
      // Полноэкранные маршруты (поверх всего, включая bottom nav)
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          if (idStr == null) {
            // Если ID отсутствует, показываем экран без productId (placeholder данные)
            return const ProductDetailScreen(productId: null);
          }
          final id = int.tryParse(idStr);
          if (id == null) {
            // Если ID не является числом, показываем экран с ошибкой
            return ProductDetailScreen(productId: null);
          }
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/seller-registration',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SellerRegistrationScreen(),
      ),
      GoRoute(
        path: '/add-product',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final q = state.uri.queryParameters['q'];
          return SearchScreen(initialQuery: q);
        },
      ),
      // Полноэкранный экран товаров по категории (открывается из каталога)
      GoRoute(
        path: '/catalog/category/:name',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['name'];
          final categoryName = name != null ? Uri.decodeComponent(name) : '';
          return CategoryProductsScreen(categoryName: categoryName.isNotEmpty ? categoryName : 'Каталог');
        },
      ),
      // Оболочка с нижней навигацией (вкладки)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainNavigationScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const CatalogScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ShoppingCartScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
