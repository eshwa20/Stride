import 'package:flutter/material.dart';
import '../../../../theme/theme_manager.dart';
import '../../../../controllers/task_controller.dart'; // <--- Import Task Model

class QuestTile extends StatefulWidget {
  final Task task; // <--- CHANGED: Uses real Task object instead of Map
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // Optional delete callback

  const QuestTile({
    super.key,
    required this.task,
    required this.index,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends State<QuestTile> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleController.value = 1.0;
  }

  void _handleTap() async {
    await _scaleController.reverse();
    await _scaleController.forward();
    widget.onTap();
  }

  // --- NEW: COLOR LOGIC ---
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
      case 'fitness':
        return const Color(0xFFFF5252); // Red
      case 'intellect':
      case 'study':
      case 'coding':
        return const Color(0xFF6C63FF); // Purple
      case 'vitality':
      case 'health':
        return const Color(0xFF00D2D3); // Cyan
      case 'spirit':
      case 'meditation':
        return const Color(0xFFFFD700); // Gold
      default:
        return const Color(0xFF54A0FF); // Blue (Default)
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Dynamic Color
    final accent = _getCategoryColor(widget.task.category);

    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final theme = ThemeManager();
        final bool isCompleted = widget.task.isCompleted;

        // ANIMATION WRAPPER
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuart,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: GestureDetector(
            onTap: _handleTap,
            child: ScaleTransition(
              scale: _scaleController,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  // Dynamic Background
                  color: isCompleted ? accent.withOpacity(0.15) : theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  // Dynamic Border
                  border: Border.all(
                    color: isCompleted ? accent.withOpacity(0.6) : theme.textColor.withOpacity(0.05),
                    width: isCompleted ? 1.5 : 1,
                  ),
                  boxShadow: isCompleted
                      ? [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Row(
                  children: [
                    // CHECKBOX
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCompleted ? accent : accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : Icon(Icons.circle_outlined, color: accent, size: 20),
                    ),
                    const SizedBox(width: 14),

                    // TEXT INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: isCompleted ? theme.subText : theme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              decorationColor: accent,
                            ),
                            child: Text(widget.task.title), // <--- Uses Task Title
                          ),
                          const SizedBox(height: 4),
                          // CATEGORY LABEL
                          Text(
                            widget.task.category.toUpperCase(), // <--- Uses Task Category
                            style: TextStyle(
                              color: accent, // <--- Uses Category Color
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // XP REWARD
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "+${widget.task.xpReward} XP",
                        style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}