import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/home_screen.dart';
import 'register.dart';

/// Halaman form login.
/// - Pakai Supabase untuk login.
/// - Bear ikut animasi: lihat input / tutup mata.
/// - Link ke halaman register.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  rive.SMIInput<bool>? _isChecking;
  rive.SMIInput<bool>? _isHandsUp;
  rive.SMITrigger? _trigSuccess;
  rive.SMITrigger? _trigFail;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRiveInit(rive.Artboard artboard) {
    final controller = rive.StateMachineController.fromArtboard(
      artboard,
      'Login Machine', // SESUAIKAN dengan nama state machine di file Rive
    );

    if (controller == null) return;

    artboard.addController(controller);

    _isChecking = controller.findInput<bool>('isChecking');
    _isHandsUp = controller.findInput<bool>('isHandsUp');
    _trigSuccess =
        controller.findInput<bool>('trigSuccess') as rive.SMITrigger?;
    _trigFail = controller.findInput<bool>('trigFail') as rive.SMITrigger?;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    _isHandsUp?.change(false);
    _isChecking?.change(true);

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        _trigSuccess?.fire();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _trigFail?.fire();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login gagal, coba lagi')));
      }
    } on AuthException catch (e) {
      _trigFail?.fire();
      if (!mounted) return;

      // Di sini pesan "Email not confirmed" juga akan muncul
      // kalau di Supabase masih mewajibkan email konfirmasi.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      _trigFail?.fire();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi nanti')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChecking?.change(false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBrown = Color(0xFF8B5E3C);
    const bgTop = Color(0xFFFAF5F0);
    const bgBottom = Color(0xFFF0EBE5);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [bgTop, bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bear Rive
                      SizedBox(
                            height: 180,
                            child: rive.RiveAnimation.asset(
                              'assets/animation/headless_bear.riv',
                              onInit: _onRiveInit,
                              fit: BoxFit.contain,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin:const Offset(0.9, 0.9), curve: Curves.easeOutBack),

                      const SizedBox(height: 16),

                      Text(
                            'Welcome Back !',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2933),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 100.ms)
                          .moveY(begin: 10, curve: Curves.easeOut),

                      const SizedBox(height: 6),

                      Text(
                            'Masuk untuk melihat barang barang terbaru dari kami.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF9AA5B1),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 150.ms)
                          .moveY(begin: 8),

                      const SizedBox(height: 20),

                      Card(
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 20,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Email
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: "Email",
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                        prefixIcon: const Icon(Icons.person),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: (_) {
                                        _isHandsUp?.change(false);
                                        _isChecking?.change(true);
                                      },
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Email tidak boleh kosong';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Format email tidak valid';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Password
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: "Password",
                                        labelStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                        prefixIcon: const Icon(Icons.lock),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onChanged: (_) {
                                        _isChecking?.change(false);
                                        _isHandsUp?.change(true);
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password tidak boleh kosong';
                                        }
                                        if (value.length < 6) {
                                          return 'Password minimal 6 karakter';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    // Tombol login
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _onSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryBrown,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                "Masuk",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Link ke register
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Belum punya akun?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Daftar',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: primaryBrown,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOut),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
