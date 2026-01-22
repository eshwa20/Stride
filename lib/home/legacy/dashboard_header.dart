import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../controllers/theme_controller.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            CircleAvatar(radius: 22),
            SizedBox(width: 12),
            Text("Hello, Rihan",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        GestureDetector(
          onTap: () {
            theme.toggleTheme();
            theme.isDark ? _lottieController.forward() : _lottieController.reverse();
          },
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset(
              'assets/animations/toogle.json',
              controller: _lottieController,
              repeat: false,
            ),
          ),
        ),
      ],
    );
  }
}
