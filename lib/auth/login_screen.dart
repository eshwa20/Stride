import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../common/app_loader.dart';
import 'auth_service.dart';
import 'signup_screen.dart';

// 1. REMOVED SelectionScreen
// 2. We use Named Routes now, so we don't strictly need to import IdentityScreen here
// if your main.dart is set up correctly.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(Future userFuture) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = await userFuture;
      if (!mounted) return;

      if (user != null) {
        // 3. THE SPECTRE MOVE: Go to Identity Protocol
        // We use pushNamedAndRemoveUntil to wipe the back button history.
        // They cannot go back to Login once inside.
        Navigator.pushNamedAndRemoveUntil(
            context,
            '/identity',
                (route) => false
        );
      }
    } catch (e) {
      _showError(e.toString());
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              /// 🔥 CONTINUOUS LOTTIE
              Center(
                child: Lottie.asset(
                  'assets/animations/login_animation.json',
                  height: 300,
                  repeat: true,
                  animate: true,
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Enter your details to continue your quest.',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 25),

              _inputField(
                controller: emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 18),

              _inputField(
                controller: passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),

              const SizedBox(height: 20),

              /// LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => _handleAuth(
                    AuthService.signInWithEmailAndPassword(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    ),
                  ),
                  child: _isLoading
                      ? const AppLoader(message: "Authenticating…")
                      : const Text(
                    'Enter Stride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// OR
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Or sign in with'),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20),

              /// 🌐 SOCIAL LOGIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialIcon(
                    asset: 'assets/icons/google.svg',
                    gap: 30,
                    onTap: () => _handleAuth(
                      AuthService.signInWithGoogle(),
                    ),
                  ),
                  _SocialIcon(
                    asset: 'assets/icons/facebook.svg',
                    gap: 30,
                    onTap: () => _handleAuth(
                      AuthService.signInWithFacebook(),
                    ),
                  ),
                  _SocialIcon(
                    asset: 'assets/icons/github.svg',
                    onTap: () => _handleAuth(
                      AuthService.signInWithGitHub(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// SIGN UP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('New to Stride? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Create account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }
}

/// 🔹 SOCIAL ICON WIDGET
class _SocialIcon extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final double gap;

  const _SocialIcon({
    super.key,
    required this.asset,
    required this.onTap,
    this.gap = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: SvgPicture.asset(
                asset,
                width: 28,
                height: 28,
              ),
            ),
          ),
        ),
        SizedBox(width: gap),
      ],
    );
  }
}