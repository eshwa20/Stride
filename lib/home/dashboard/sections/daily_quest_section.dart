import 'package:flutter/material.dart';
import '../../../../theme/theme_manager.dart';
import '../../../../controllers/task_controller.dart';
// ✅ IMPORT: Points to your feature folder
import 'package:stride/features/active_session/run_tracker_page.dart';
import 'quest_tile.dart';

class DailyQuestSection extends StatelessWidget {
  final List<Task> quests;
  final Function(String id) onQuestToggle;
  final Function(String id) onQuestDelete;

  const DailyQuestSection({
    super.key,
    required this.quests,
    required this.onQuestToggle,
    required this.onQuestDelete,
  });

  // --- 🏃‍♂️ LOGIC: Intercept Taps ---
  void _handleTaskTap(BuildContext context, Task task) {
    // 1. Check if the task is cardio-related
    bool isCardio = task.title.toLowerCase().contains("run") ||
        task.title.toLowerCase().contains("walk") ||
        task.title.toLowerCase().contains("jog");

    // 2. If Cardio & Not Done -> FORCE TRACKER
    if (isCardio && !task.isCompleted) {
      _showTrackerOptions(context, task);
    } else {
      // 3. Normal Task -> Toggle normally
      onQuestToggle(task.id);
    }
  }

  // --- 📱 UI: Tracker Prompt (No "Mark Done" Option) ---
  void _showTrackerOptions(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeManager().cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_run_rounded, size: 50, color: Colors.orangeAccent),
            const SizedBox(height: 10),
            Text("Time to Move", style: TextStyle(color: ThemeManager().textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("This is a tracked event. GPS is required to complete '${task.title}'.", textAlign: TextAlign.center, style: TextStyle(color: ThemeManager().subText)),
            const SizedBox(height: 25),

            // BUTTON: START GPS TRACKER (The Only Way Forward)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.gps_fixed_rounded),
                label: const Text("Start Session"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close the popup

                  // Open the Map/Tracker Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RunTrackerPage(taskName: task.title)),
                  ).then((result) {
                    // Only mark done if they actually finished the run logic
                    if (result == true) {
                      onQuestToggle(task.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 10),

            // ❌ "Just Mark Done" button has been REMOVED.
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, child) {
        final theme = ThemeManager();

        return Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ACTIVE PROTOCOLS",
                    style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5
                    ),
                  ),
                  Text(
                    "${quests.where((t) => !t.isCompleted).length} PENDING",
                    style: TextStyle(
                        color: theme.subText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QUEST LIST
            quests.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(Icons.radar_rounded, size: 48, color: theme.subText.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    "NO ACTIVE DIRECTIVES",
                    style: TextStyle(color: theme.subText, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quests.length,
              itemBuilder: (context, index) {
                final task = quests[index];

                return Dismissible(
                  key: Key(task.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (direction) => onQuestDelete(task.id),
                  child: QuestTile(
                    task: task,
                    index: index,
                    // ✅ MODIFIED: Use _handleTaskTap to intercept taps
                    onTap: () => _handleTaskTap(context, task),
                    onDelete: () => onQuestDelete(task.id),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}