import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// pastikan import ini sesuai path kamu
import 'package:uts_flutter_1/pages/auth/login.dart';
import 'package:uts_flutter_1/pages/home/home_screen.dart';

import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qafyhrselgmfifllshbi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFhZnlocnNlbGdtZmlmbGxzaGJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMjcxNzUsImV4cCI6MjA3OTYwMzE3NX0.caFwniqhD9j4qtwKgMazcX0AcqK_SX0El2W9PwZCCBo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Online',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // ⬅️ pakai AuthGate
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      // ⬅️ DI SINI LoginScreen dipakai,
      // jadi import login.dart dianggap "used"
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
}
