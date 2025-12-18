# App Routes Documentation

## Penggunaan Named Routes

Aplikasi ini menggunakan sistem named routes yang lebih rapi dan mudah di-maintain.

### File Route Configuration
- **`lib/core/app_routes.dart`** - Berisi semua definisi route dan helper methods

### Daftar Route yang Tersedia

```dart
AppRoutes.login           // '/login'
AppRoutes.loginForm       // '/login-form'
AppRoutes.register        // '/register'
AppRoutes.registerAdmin   // '/register-admin'
AppRoutes.home            // '/home'
AppRoutes.cart            // '/cart'
AppRoutes.checkout        // '/checkout'
AppRoutes.orderSuccess    // '/order-success'
AppRoutes.promo           // '/promo'
```

### Cara Menggunakan

#### 1. Navigasi ke halaman baru (push)
```dart
// Cara lama (JANGAN gunakan lagi)
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const LoginScreen()),
);

// Cara baru (GUNAKAN ini)
AppRoutes.push(context, AppRoutes.login);
```

#### 2. Navigasi dengan replace (pushReplacement)
```dart
// Cara lama
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const HomeScreen()),
);

// Cara baru
AppRoutes.pushReplacement(context, AppRoutes.home);
```

#### 3. Navigasi dan hapus semua route sebelumnya
```dart
// Berguna untuk logout atau setelah selesai onboarding
AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
```

#### 4. Kembali ke halaman sebelumnya
```dart
// Cara lama
Navigator.pop(context);

// Cara baru
AppRoutes.pop(context);

// Dengan return value
AppRoutes.pop(context, someResult);
```

### Contoh Implementasi

#### Halaman Register Admin
```dart
// Di dalam button handler
onPressed: () {
  AppRoutes.pushReplacement(context, AppRoutes.login);
}
```

#### Halaman Register
Tombol untuk ke halaman register admin:
```dart
OutlinedButton.icon(
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterAdminScreen()),
    );
  },
  icon: const Icon(Icons.admin_panel_settings),
  label: const Text('Daftar sebagai Admin'),
)
```

### Keuntungan Menggunakan Named Routes

1. **Lebih Rapi**: Tidak perlu import banyak file screen
2. **Type Safe**: Typo pada nama route akan langsung terdeteksi
3. **Centralized**: Semua route ada di satu tempat
4. **Easy Maintenance**: Mudah untuk update atau refactor
5. **Deep Linking Ready**: Siap untuk implementasi deep linking di masa depan

### Tips

- Selalu gunakan `AppRoutes.xxx` untuk navigasi
- Jangan hardcode string route name
- Untuk navigasi dengan parameter kompleks, gunakan cara lama dengan `MaterialPageRoute` dan passing argument
- Update `app_routes.dart` setiap kali menambah halaman baru
