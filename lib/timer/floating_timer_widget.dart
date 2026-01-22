import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FloatingTimerWidget extends StatefulWidget {
  final int remainingSeconds;
  final bool isRunning;
  final bool isBreak;
  final VoidCallback? onTap;

  const FloatingTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.isRunning,
    required this.isBreak,
    this.onTap,
  });

  @override
  State<FloatingTimerWidget> createState() => _FloatingTimerWidgetState();
}

class _FloatingTimerWidgetState extends State<FloatingTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isRunning) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isBreak
                      ? Colors.green.withOpacity(0.9)
                      : Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isRunning ? Icons.timer : Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(widget.remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (widget.isBreak) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BREAK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AlwaysOnTimerOverlay extends StatelessWidget {
  final int remainingSeconds;
  final bool isRunning;
  final bool isBreak;
  final VoidCallback? onTap;

  const AlwaysOnTimerOverlay({
    super.key,
    required this.remainingSeconds,
    required this.isRunning,
    required this.isBreak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay
        Container(
          color: Colors.black.withOpacity(0.1),
        ),

        // Floating timer widget
        FloatingTimerWidget(
          remainingSeconds: remainingSeconds,
          isRunning: isRunning,
          isBreak: isBreak,
          onTap: onTap,
        ),

        // Keep screen on
        const _KeepScreenOn(),
      ],
    );
  }
}

class _KeepScreenOn extends StatefulWidget {
  const _KeepScreenOn();

  @override
  State<_KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends State<_KeepScreenOn> {
  @override
  void initState() {
    super.initState();
    // Keep screen on during timer sessions
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // Restore normal screen behavior
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}