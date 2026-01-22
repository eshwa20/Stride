import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  bool _darkBackground = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Logo fade-in
    Timer(const Duration(milliseconds: 600), () {
      _controller.forward();
    });

    // Background switch
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _darkBackground = false);
    });

    // --- UPDATED NAVIGATION ---
    // Navigate to the Gatekeeper instead of directly to Onboarding
    Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      // Changing '/onboarding' to '/auth' enables the autologin check
      Navigator.pushReplacementNamed(context, '/auth');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        color: _darkBackground ? Colors.black : Colors.white,
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _darkBackground ? 1 : 0,
                    child: Image.asset(
                      'assets/logo/stride_light.png',
                      width: 270,
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _darkBackground ? 0 : 1,
                    child: Image.asset(
                      'assets/logo/stride_dark.png',
                      width: 270,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}