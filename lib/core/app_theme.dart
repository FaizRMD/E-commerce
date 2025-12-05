// lib/core/app_theme.dart

import 'package:flutter/material.dart';

/// Kumpulan tema global aplikasi.
///
/// Di sini kita atur:
/// - warna utama (primary color)
/// - bentuk button
/// - style teks dasar
///
/// Keuntungan:
/// - tampilan konsisten di semua halaman
/// - kalau mau ganti warna/tema cukup ubah di 1 tempat.
class AppTheme {
  /// Warna utama e-commerce (bisa kamu ganti sesuai branding).
  static const Color primaryColor = Colors.indigo;

  /// Light theme utama untuk aplikasi.
  static ThemeData get lightTheme {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.grey.shade50,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
    );
  }
}
