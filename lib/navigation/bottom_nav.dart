import 'package:flutter/material.dart';

class StrideBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StrideBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors
    final Color barColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final Color activeCircleColor = const Color(0xFF6C63FF); // Primary Purple
    final Color iconColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color dividerColor = isDark ? Colors.white10 : Colors.grey.shade200;

    final List<IconData> icons = [
      Icons.apps_rounded,
      Icons.access_time_rounded,
      Icons.calendar_today_rounded,
      Icons.bar_chart_rounded,
      Icons.person_rounded,
    ];

    return Container(
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              icons.length,
              (index) => GestureDetector(
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(
                    horizontal: currentIndex == index ? 20 : 12,
                    vertical: currentIndex == index ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? activeCircleColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      currentIndex == index ? 16 : 12,
                    ),
                    border: currentIndex == index
                        ? Border.all(
                            color: activeCircleColor.withOpacity(0.3),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Icon(
                    icons[index],
                    color: currentIndex == index
                        ? activeCircleColor
                        : iconColor,
                    size: currentIndex == index ? 26 : 24,
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
