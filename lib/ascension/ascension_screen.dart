import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AscensionScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const AscensionScreen({super.key, this.onComplete});

  @override
  State<AscensionScreen> createState() => _AscensionScreenState();
}

class _AscensionScreenState extends State<AscensionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _scale;
  late Animation<double> _tapTextOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _tapTextOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // ✅ Prevent early taps
    if (_controller.value < 0.75) return;

    HapticFeedback.lightImpact();

    // ✅ Call onComplete if provided, else navigate directly
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Stack(
          children: [
            /// ───────── ASCENSION CONTENT ─────────
            Positioned(
              top: size.height * 0.38,
              left: 0,
              right: 0,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: Image.asset(
                        'assets/ascension/ascension_title.png',
                        width: 280,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _subtitleOpacity,
                      child: Image.asset(
                        'assets/ascension/ascension_subtitle.png',
                        width: 240,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// ───────── TAP HINT ─────────
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _tapTextOpacity,
                child: const Text(
                  'Tap — The journey awaits',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontSize: 13,
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
