import 'package:flutter/material.dart';
import '../../../../theme/theme_manager.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  String selectedClass = "Strength";
  double difficulty = 1.0;
  final TextEditingController _controller = TextEditingController();

  // --- COLOR LOGIC ---
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
  Widget build(BuildContext context) {
    // 1. Get the dynamic color for the currently selected class
    final Color activeColor = _getCategoryColor(selectedClass);

    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5)
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.subText.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "NEW MISSION OBJECTIVE",
                style: TextStyle(
                    color: theme.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 12),

              // Input Field
              TextField(
                controller: _controller,
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Enter quest name...",
                  hintStyle: TextStyle(color: theme.subText.withOpacity(0.5)),
                  filled: true,
                  fillColor: theme.bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),

              Text(
                "CLASS TYPE",
                style: TextStyle(
                    color: theme.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 12),

              // Class Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ["Strength", "Intellect", "Vitality", "Spirit"].map((type) {
                  bool isSelected = selectedClass == type;
                  Color categoryColor = _getCategoryColor(type);

                  return GestureDetector(
                    onTap: () => setState(() => selectedClass = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? categoryColor : theme.bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected ? categoryColor : theme.subText.withOpacity(0.1),
                            width: 1.5
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: categoryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                            color: isSelected ? Colors.white : theme.subText,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Difficulty Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "DIFFICULTY REWARD",
                    style: TextStyle(
                        color: theme.subText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5
                    ),
                  ),
                  Text(
                    "+${(difficulty * 100).toInt()} XP",
                    style: TextStyle(
                        color: activeColor, // <--- UPDATED: Matches Class Color
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              Slider(
                value: difficulty,
                min: 0.5,
                max: 2.0,
                divisions: 3,
                activeColor: activeColor, // <--- UPDATED: Matches Class Color
                inactiveColor: theme.bgColor,
                onChanged: (val) => setState(() => difficulty = val),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      Navigator.pop(context, {
                        'title': _controller.text,
                        'category': selectedClass,
                        'xp': (difficulty * 100).toInt(),
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor, // <--- UPDATED: Matches Class Color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: activeColor.withOpacity(0.4), // <--- UPDATED
                  ),
                  child: const Text(
                    "INITIATE QUEST",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1
                    ),
                  ),
                ),
              ),
              // Keyboard spacing fix
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
            ],
          ),
        );
      },
    );
  }
}