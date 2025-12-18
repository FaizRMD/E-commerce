// lib/core/app_routes.dart

import 'package:flutter/material.dart';
import 'package:uts_flutter_1/pages/auth/login.dart';
import 'package:uts_flutter_1/pages/auth/login_form.dart';
import 'package:uts_flutter_1/pages/auth/register.dart';
import 'package:uts_flutter_1/pages/auth/register_admin.dart';
import 'package:uts_flutter_1/pages/home/home_screen.dart';
import 'package:uts_flutter_1/pages/cart/cart_screen.dart';
import 'package:uts_flutter_1/pages/promo/promo_page.dart';
import 'package:uts_flutter_1/pages/admin/admin_dashboard.dart';

/// Kelas untuk mengelola semua route aplikasi.
///
/// Keuntungan menggunakan named routes:
/// - Navigasi lebih rapi dan mudah di-maintain
/// - Mudah untuk deep linking di masa depan
/// - Avoid typo karena menggunakan konstanta
class AppRoutes {
  // Nama-nama route
  static const String login = '/login';
  static const String loginForm = '/login-form';
  static const String register = '/register';
  static const String registerAdmin = '/register-admin';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String promo = '/promo';
  static const String adminDashboard = '/admin-dashboard';

  /// Map semua route dengan widget-nya
  /// Note: CheckoutScreen dan OrderSuccessScreen tidak ada di sini
  /// karena memerlukan parameter wajib, gunakan Navigator.push langsung
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    loginForm: (context) => const LoginForm(),
    register: (context) => const RegisterScreen(),
    registerAdmin: (context) => const RegisterAdminScreen(),
    home: (context) => const HomeScreen(),
    cart: (context) => const CartScreen(),
    promo: (context) => const PromoPage(),
    adminDashboard: (context) => const AdminDashboardScreen(),
  };

  /// Helper method untuk navigasi dengan named route
  static Future<T?> push<T>(BuildContext context, String routeName) {
    return Navigator.pushNamed<T>(context, routeName);
  }

  /// Helper method untuk navigasi replacement
  static Future<T?> pushReplacement<T extends Object?>(
    BuildContext context,
    String routeName,
  ) {
    return Navigator.pushReplacementNamed<T, T>(context, routeName);
  }

  /// Helper method untuk navigasi dan hapus semua route sebelumnya
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    String routeName,
  ) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
    );
  }

  /// Helper method untuk kembali ke halaman sebelumnya
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }
}
