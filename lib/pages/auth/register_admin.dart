import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_routes.dart';

class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureAdminCode = true;
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  // Kode admin rahasia (dalam production, simpan di server/environment variable)
  static const String _secretAdminCode = "ADMIN2024SECRET";

  // input dari Rive
  rive.SMIInput<bool>? _isChecking;
  rive.SMIInput<bool>? _isHandsUp;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // RIVE INIT
  // ------------------------------------------------------------
  void _onRiveInit(rive.Artboard artboard) {
    final controller = rive.StateMachineController.fromArtboard(
      artboard,
      'Login Machine',
    );

    if (controller == null) return;

    artboard.addController(controller);

    _isChecking = controller.findInput<bool>('isChecking');
    _isHandsUp = controller.findInput<bool>('isHandsUp');
  }

  // ------------------------------------------------------------
  // REGISTER ADMIN KE SUPABASE + SIMPAN KE profiles
  // ------------------------------------------------------------
  Future<void> _onRegisterAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final adminCode = _adminCodeController.text.trim();

    // Validasi kode admin
    if (adminCode != _secretAdminCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode admin tidak valid!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. daftar ke Supabase Auth
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'admin', // metadata user sebagai admin
        },
      );

      final user = res.user;

      if (user != null) {
        // 2. upsert ke tabel profiles dengan role admin
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'email': email,
          'role': 'admin', // set role sebagai admin
        });

        if (!mounted) return;

        // reset animasi & form
        _isChecking?.change(false);
        _isHandsUp?.change(false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi admin berhasil! Silakan login.'),
            backgroundColor: Colors.green,
          ),
        );

        // 3. pindah ke halaman login
        AppRoutes.pushReplacement(context, AppRoutes.login);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // ------------------------------------------------------------
              // RIVE ANIMATION
              // ------------------------------------------------------------
              SizedBox(
                height: 200,
                child: rive.RiveAnimation.asset(
                  'assets/animation/headless_bear.riv',
                  stateMachines: const ['Login Machine'],
                  onInit: _onRiveInit,
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------------------
              // JUDUL
              // ------------------------------------------------------------
              Text(
                'Daftar Admin',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Buat akun admin baru untuk mengelola e-commerce',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ------------------------------------------------------------
              // FORM
              // ------------------------------------------------------------
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nama Lengkap
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        hintText: 'Masukkan nama lengkap admin',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                      onTap: () {
                        _isChecking?.change(true);
                      },
                      onEditingComplete: () {
                        _isChecking?.change(false);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Admin',
                        hintText: 'admin@example.com',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!val.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                      onTap: () {
                        _isChecking?.change(true);
                      },
                      onEditingComplete: () {
                        _isChecking?.change(false);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (val.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                      onTap: () {
                        _isHandsUp?.change(true);
                      },
                      onEditingComplete: () {
                        _isHandsUp?.change(false);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Kode Admin
                    TextFormField(
                      controller: _adminCodeController,
                      obscureText: _obscureAdminCode,
                      decoration: InputDecoration(
                        labelText: 'Kode Admin',
                        hintText: 'Masukkan kode rahasia admin',
                        prefixIcon: const Icon(Icons.admin_panel_settings),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureAdminCode
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureAdminCode = !_obscureAdminCode;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Kode admin tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Tombol Daftar
                    FilledButton(
                      onPressed: _isLoading ? null : _onRegisterAdmin,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Daftar Admin',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Link ke Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            AppRoutes.pushReplacement(context, AppRoutes.login);
                          },
                          child: Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info Kode Admin
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[800]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hubungi administrator untuk mendapatkan kode admin',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
