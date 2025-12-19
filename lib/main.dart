import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uts_flutter_1/pages/auth/login.dart';
import 'package:uts_flutter_1/pages/home/home_screen.dart';
import 'package:uts_flutter_1/pages/admin/admin_dashboard.dart';

import 'core/app_theme.dart';
import 'core/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qafyhrselgmfifllshbi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFhZnlocnNlbGdtZmlmbGxzaGJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMjcxNzUsImV4cCI6MjA3OTYwMzE3NX0.caFwniqhD9j4qtwKgMazcX0AcqK_SX0El2W9PwZCCBo',
    // Pastikan session dipersist dan token auto-refresh supaya refresh/hot-reload
    // tidak mengembalikan ke login.
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
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
      routes: AppRoutes.routes, // ⬅️ tambahkan named routes
      initialRoute: null, // null karena pakai home
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAdmin = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    // Keep UI in sync with auth changes (and hot reload reattach)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => _checkUserRole(),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session != null) {
      try {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();
        final role = profile?['role'] as String?;

        if (mounted) {
          setState(() {
            _isAdmin = role == 'admin';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    } else {
      // Redirect based on role
      return _isAdmin ? const AdminDashboardScreen() : const HomeScreen();
    }
  }
}
