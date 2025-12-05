import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:google_fonts/google_fonts.dart';

import 'login_form.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _logoScale;

  rive.SMITrigger? _smileTrigger;
  rive.SMITrigger? _closeEyesTrigger;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _logoScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onRiveInit(rive.Artboard artboard) {
    final controller = rive.StateMachineController.fromArtboard(
      artboard,
      'LoginMachine', // SESUAIKAN dengan file Rive
    );

    if (controller != null) {
      artboard.addController(controller);

      _smileTrigger = controller.findInput<bool>('Smile') as rive.SMITrigger?;
      _closeEyesTrigger =
          controller.findInput<bool>('CloseEyes') as rive.SMITrigger?;

      _smileTrigger?.fire();
    }
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginForm()),
    );
  }

  void _goSignUp() {
    _closeEyesTrigger?.fire();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryBrown = Color(0xFF8B5E3C);
    const softBrown = Color(0xFFF4E5D8);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFFDF8F3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryBrown.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -30,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: softBrown.withOpacity(0.6),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),

                            ScaleTransition(
                              scale: _logoScale,
                              child: SizedBox(
                                height: 230,
                                child: rive.RiveAnimation.asset(
                                  'assets/animation/headless_bear.riv',
                                  onInit: _onRiveInit,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            Text(
                              'Hello 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F2933),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'Welcome to your cashier app.\nManage your daily tasks and transactions\nmore easily.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF9AA5B1),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _goLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBrown,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _goSignUp,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: primaryBrown,
                                    width: 1.6,
                                  ),
                                  foregroundColor: primaryBrown,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
