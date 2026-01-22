import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

// Theme & Controllers
import '../../theme/theme_manager.dart';
import '../../controllers/xp_controller.dart';
import '../../controllers/task_controller.dart';

// Services
import '../../services/notification_service.dart';

// --- DATA MODEL: COUPON ---
class Coupon {
  final String brandName;
  final String category;
  final String discount;
  final int embersRequired;
  final Color accentColor;
  final String code;
  final String imagePath;

  Coupon({
    required this.brandName,
    required this.category,
    required this.discount,
    required this.embersRequired,
    required this.accentColor,
    required this.code,
    required this.imagePath,
  });
}

// --- NEW DATA MODEL: ACHIEVEMENT ---
class Achievement {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final bool isUnlocked; // Controls B&W vs Color

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.isUnlocked = false,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  bool _isGlitching = false;
  Timer? _glitchTimer;

  // Real Data State
  int _currentStreak = 0;
  int _totalQuests = 0;

  // --- AVATAR STATE ---
  String _selectedAvatar = 'assets/profile/astra_happy.png';

  final List<String> _avatarOptions = [
    'assets/profile/astra_happy.png',
    'assets/profile/astra_focused.png',
    'assets/profile/astra_sad.png',
    'assets/profile/astra_angry.png',
    'assets/profile/astra_sleepy.png',
  ];

  // --- ACHIEVEMENT LIST (Based on your Screenshot) ---
  // Note: Set 'isUnlocked' to logic based on stats in a real scenario.
  // For now, some are true and some false to show the effect.
  final List<Achievement> _achievements = [
    Achievement(id: '1', title: "Early Riser", description: "Complete a task before 7 AM", imagePath: "assets/badges/Early Riser.png", isUnlocked: true),
    Achievement(id: '2', title: "Midnight Scholar", description: "Complete a task after 11 PM", imagePath: "assets/badges/Midnight Scholar.png", isUnlocked: true),
    Achievement(id: '3', title: "Inner Balance", description: "Complete 5 Spirit tasks", imagePath: "assets/badges/Inner Balance.png", isUnlocked: false),
    Achievement(id: '4', title: "Syllabus Slayer", description: "Finish 10 Intellect tasks", imagePath: "assets/badges/Syllabus Slayer.png", isUnlocked: true),
    Achievement(id: '5', title: "Twilight Thinker", description: "Active during sunset hours", imagePath: "assets/badges/Twilight Thinker.png", isUnlocked: false),
    Achievement(id: '6', title: "Internally Driven", description: "Maintain a 7-day streak", imagePath: "assets/badges/Internally Driven.png", isUnlocked: true),
    Achievement(id: '7', title: "Ascendant", description: "Reach Level 10", imagePath: "assets/badges/Ascendant.png", isUnlocked: false),
    Achievement(id: '8', title: "Back on Track", description: "Recover a lost streak", imagePath: "assets/badges/Back on Track.png", isUnlocked: true),
    Achievement(id: '9', title: "A Long Way", description: "Total 10,000 XP earned", imagePath: "assets/badges/A Long Way.png", isUnlocked: false),
    Achievement(id: '10', title: "Still Here", description: "Active for 30 days", imagePath: "assets/badges/Still Here.png", isUnlocked: false),
    Achievement(id: '11', title: "Breakthrough", description: "Complete a high difficulty quest", imagePath: "assets/badges/Breakthrough.png", isUnlocked: true),
    Achievement(id: '12', title: "Out of Orbit", description: "Complete 100 total tasks", imagePath: "assets/badges/Out of Orbit.png", isUnlocked: false),
  ];

  final User? user = FirebaseAuth.instance.currentUser;
  String get userName => user?.displayName?.toUpperCase() ?? "COMMANDER";
  String get userId => user?.uid ?? "GUEST-001";
  String get shortId => userId.length > 4 ? userId.substring(userId.length - 4).toUpperCase() : userId;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut));

    _startGlitchLoop();
    _loadRealStats();
  }

  Future<void> _loadRealStats() async {
    // 1. Load Avatar
    if (Hive.isBoxOpen('settingsBox')) {
      var settingsBox = Hive.box('settingsBox');
      if (mounted) {
        setState(() {
          _selectedAvatar = settingsBox.get('userAvatar', defaultValue: 'assets/profile/astra_happy.png');
        });
      }
    }

    // 2. Load Streak
    if (Hive.isBoxOpen('statsBox')) {
      var statsBox = Hive.box('statsBox');
      int streak = 0;
      DateTime date = DateTime.now();

      while (true) {
        String key = DateFormat('yyyy-MM-dd').format(date);
        if (statsBox.containsKey('hourly_$key')) {
          streak++;
          date = date.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      if (mounted) setState(() => _currentStreak = streak);
    }

    // 3. Load Tasks
    if (Hive.isBoxOpen('tasks')) {
      var taskBox = Hive.box('tasks');
      int questCount = taskBox.values.where((task) => task is Map && task['isCompleted'] == true).length;
      if (mounted) setState(() => _totalQuests = questCount);
    }
  }

  void _startGlitchLoop() {
    _glitchTimer = Timer.periodic(Duration(seconds: 3 + Random().nextInt(5)), (timer) {
      if (mounted) _triggerGlitch();
    });
  }

  void _triggerGlitch() {
    setState(() => _isGlitching = true);
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isGlitching = false);
    });
  }

  ImageProvider _getAvatarProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (path.isNotEmpty) {
      File file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return const AssetImage('assets/profile/astra_happy.png');
  }

  Future<void> _pickCustomImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedAvatar = image.path);
        Hive.box('settingsBox').put('userAvatar', image.path);
        if (mounted) {
          Navigator.pop(context);
          _triggerGlitch();
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _glitchTimer?.cancel();
    super.dispose();
  }

  // =========================================================
  //  SETTINGS SLIDES (BOTTOM SHEETS)
  // =========================================================

  // 1. AVATAR SELECTION SLIDE
  void _showAvatarSelection(ThemeManager theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.60,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text("IDENTITY MODIFICATION", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickCustomImage,
                icon: Icon(Icons.upload_file, color: theme.accentColor),
                label: Text("UPLOAD FROM NEURAL LINK", style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.accentColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  final String path = _avatarOptions[index];
                  final bool isSelected = path == _selectedAvatar;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatar = path);
                      Hive.box('settingsBox').put('userAvatar', path);
                      Navigator.pop(context);
                      _triggerGlitch();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.accentColor : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: theme.accentColor.withOpacity(0.5), blurRadius: 15)] : [],
                      ),
                      child: CircleAvatar(
                        backgroundColor: theme.bgColor,
                        backgroundImage: AssetImage(path),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. THEME SETTINGS SLIDE
  void _showThemeSettings(ThemeManager theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: theme.accentColor),
                      const SizedBox(width: 12),
                      Text("INTERFACE CALIBRATION", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Container(
                    decoration: BoxDecoration(color: theme.bgColor, borderRadius: BorderRadius.circular(16)),
                    child: SwitchListTile(
                      secondary: Icon(theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: theme.textColor),
                      title: Text("Visual Interface", style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(theme.isDark ? "Stealth Mode (Dark)" : "Daylight Mode (Light)", style: TextStyle(color: theme.subText, fontSize: 11)),
                      activeColor: theme.accentColor,
                      value: theme.isDark,
                      onChanged: (val) {
                        theme.toggleTheme(val);
                        setState(() {});
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text("NEURAL LINK FREQUENCY", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildColorDot(theme, const Color(0xFF00D2D3)),
                      _buildColorDot(theme, const Color(0xFF00FF41)),
                      _buildColorDot(theme, const Color(0xFFFFD700)),
                      _buildColorDot(theme, const Color(0xFFFF5252)),
                      _buildColorDot(theme, const Color(0xFF6C63FF)),
                    ],
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.textColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("CONFIRM SETTINGS", style: TextStyle(color: theme.bgColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
      ),
    );
  }

  // 3. NOTIFICATION SETTINGS SLIDE
  void _showNotificationSettings(ThemeManager theme) {
    final settingsBox = Hive.box('settingsBox');

    bool missionAlerts = settingsBox.get('missionAlerts', defaultValue: true);
    bool dailyBrief = settingsBox.get('dailyBrief', defaultValue: true);
    bool trainingReminders = settingsBox.get('trainingReminders', defaultValue: false);

    int briefHour = settingsBox.get('briefHour', defaultValue: 8);
    int briefMinute = settingsBox.get('briefMinute', defaultValue: 0);
    TimeOfDay briefTime = TimeOfDay(hour: briefHour, minute: briefMinute);

    int train1Hour = settingsBox.get('train1Hour', defaultValue: 9);
    int train1Minute = settingsBox.get('train1Minute', defaultValue: 0);
    TimeOfDay train1Time = TimeOfDay(hour: train1Hour, minute: train1Minute);

    int train2Hour = settingsBox.get('train2Hour', defaultValue: 18);
    int train2Minute = settingsBox.get('train2Minute', defaultValue: 0);
    TimeOfDay train2Time = TimeOfDay(hour: train2Hour, minute: train2Minute);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Icon(Icons.radar_rounded, color: theme.accentColor),
                        const SizedBox(width: 12),
                        Text("COMMS UPLINK", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Text("ALERT PRIORITY", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildSwitchRow(theme, "Mission Critical", "High priority deadline warnings", missionAlerts, (val) => setSheetState(() => missionAlerts = val)),

                    _buildSwitchRow(theme, "Daily Briefing", "Morning tactical summary", dailyBrief, (val) => setSheetState(() => dailyBrief = val)),
                    if (dailyBrief) ...[
                      const SizedBox(height: 8),
                      _buildTimePickerRow(theme, "Briefing Time", briefTime, (picked) => setSheetState(() => briefTime = picked)),
                    ],

                    const SizedBox(height: 24),

                    Text("TRAINING SCHEDULE", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildSwitchRow(theme, "Training Drills", "2x Daily Reminders", trainingReminders, (val) => setSheetState(() => trainingReminders = val)),

                    if (trainingReminders) ...[
                      const SizedBox(height: 8),
                      _buildTimePickerRow(theme, "Session 1", train1Time, (picked) => setSheetState(() => train1Time = picked)),
                      const SizedBox(height: 8),
                      _buildTimePickerRow(theme, "Session 2", train2Time, (picked) => setSheetState(() => train2Time = picked)),
                    ],

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          settingsBox.put('missionAlerts', missionAlerts);
                          settingsBox.put('dailyBrief', dailyBrief);
                          settingsBox.put('briefHour', briefTime.hour);
                          settingsBox.put('briefMinute', briefTime.minute);
                          settingsBox.put('trainingReminders', trainingReminders);
                          settingsBox.put('train1Hour', train1Time.hour);
                          settingsBox.put('train1Minute', train1Time.minute);
                          settingsBox.put('train2Hour', train2Time.hour);
                          settingsBox.put('train2Minute', train2Time.minute);

                          await NotificationService.cancelAll();

                          if (dailyBrief) await NotificationService.scheduleDailySummary(briefTime);
                          if (trainingReminders) await NotificationService.scheduleTrainingReminders(train1Time, train2Time);
                          await NotificationService.resetStreakProtection();

                          Navigator.pop(context);
                          _showTacticalToast("COMMS CONFIG SAVED", theme);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text("SAVE PROTOCOLS", style: TextStyle(color: theme.bgColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  // 4. PRIVACY & DATA SLIDE
  void _showPrivacySettings(ThemeManager theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(Icons.shield_outlined, color: theme.accentColor),
                  const SizedBox(width: 12),
                  Text("SECURE HUNTER PROTOCOL", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 30),

              Text("DATA GOVERNANCE", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildDataTile(
                  theme,
                  Icons.download_rounded,
                  "Export Mission Log",
                  "Download a copy of your stats and XP history.",
                      () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(seconds: 2), () {
                      _showTacticalToast("DATA PACK DOWNLOADED", theme);
                    });
                  }
              ),

              const SizedBox(height: 12),

              _buildDataTile(
                theme,
                Icons.delete_sweep_rounded,
                "Purge Local Cache",
                "Clear temporary mission data. (Safe)",
                    () async {
                  Navigator.pop(context);
                  _showTacticalToast("CACHE MEMORY PURGED", theme);
                },
                isDestructive: true,
              ),

              const SizedBox(height: 32),

              Text("PRIVACY MANIFEST", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.subText.withOpacity(0.1)),
                ),
                child: Text(
                  "Stride operates under a strictly confidential protocol. Your mission data (XP, Streaks, and Tasks) remains stored locally on this device and synced securely via Firebase Authentication. We do not sell, trade, or compromise Hunter data. Your training metrics are yours alone.",
                  style: TextStyle(color: theme.subText, height: 1.6, fontSize: 13),
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text("SECURE CONNECTION ESTABLISHED", style: TextStyle(color: theme.accentColor, fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 5. SUPPORT CENTER SLIDE
  void _showSupportCenter(ThemeManager theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: theme.accentColor),
                  const SizedBox(width: 12),
                  Text("SYSTEM HELP DESK", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 30),

              Text("FIELD MANUAL (S.O.P)", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _buildFaqTile(theme, "How do I earn Embers?", "Embers are generated by completing Tasks and maintaining your Streak. Use them in the Supply Depot."),
              _buildFaqTile(theme, "What happens if I miss a day?", "Your Streak will reset to zero unless you have a Streak Freeze equipped. Consistency is key, Commander."),
              _buildFaqTile(theme, "How do I rank up?", "Gain XP by finishing tasks. Higher levels unlock new titles like 'Veteran' and 'S-Class'."),

              const SizedBox(height: 24),

              Text("DIRECT TRANSMISSION", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.subText.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.satellite_alt_rounded, size: 40, color: theme.accentColor),
                    const SizedBox(height: 16),
                    Text("Need to report an anomaly?", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Establish a direct uplink to HQ for bug reports or feature requests.", textAlign: TextAlign.center, style: TextStyle(color: theme.subText, fontSize: 12)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: "support@stride.app"));
                          Navigator.pop(context);
                          _showTacticalToast("UPLINK FREQUENCY COPIED", theme);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("COPY FREQUENCY (EMAIL)", style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    Text("SYSTEM FIRMWARE v1.0.4 (ALPHA)", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("ID: ${user?.uid.substring(0, 8).toUpperCase() ?? 'UNKNOWN'}", style: TextStyle(color: theme.subText.withOpacity(0.5), fontSize: 9, fontFamily: 'Courier')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW: ACHIEVEMENT GRID SLIDE ---
  void _showAchievements(ThemeManager theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.military_tech_rounded, color: theme.accentColor),
                const SizedBox(width: 12),
                Text("SERVICE RECORD", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: _achievements.length,
                itemBuilder: (context, index) {
                  final Achievement badge = _achievements[index];

                  return GestureDetector(
                    onTap: () {
                      // Show details on tap
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.accentColor.withOpacity(0.5))),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              badge.isUnlocked
                                  ? Image.asset(badge.imagePath, width: 80, height: 80)
                                  : ColorFiltered(
                                colorFilter: const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
                                ]),
                                child: Image.asset(badge.imagePath, width: 80, height: 80),
                              ),
                              const SizedBox(height: 16),
                              Text(badge.title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text(badge.description, style: TextStyle(color: theme.subText, fontSize: 12), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              Text(badge.isUnlocked ? "STATUS: UNLOCKED" : "STATUS: LOCKED", style: TextStyle(color: badge.isUnlocked ? theme.accentColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: badge.isUnlocked ? [BoxShadow(color: theme.accentColor.withOpacity(0.3), blurRadius: 10)] : [],
                            ),
                            child: badge.isUnlocked
                                ? Image.asset(badge.imagePath, fit: BoxFit.contain)
                                : ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ]),
                              child: Opacity(opacity: 0.5, child: Image.asset(badge.imagePath, fit: BoxFit.contain)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: badge.isUnlocked ? theme.textColor : theme.subText, fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  //  ACTION METHODS (REQUIRED)
  // =========================================================

  void _showIdentityCard(ThemeManager theme) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.bgColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.accentColor.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("IDENTITY CARD", style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(data: "uid:$userId|name:$userName", version: QrVersions.auto, size: 180.0, backgroundColor: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(userName, style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                  ),
                  child: Text("UNIT #$shortId", style: TextStyle(color: theme.accentColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTacticalToast(String message, ThemeManager theme) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(side: BorderSide(color: theme.accentColor.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            Icon(Icons.terminal, color: theme.accentColor, size: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(message.toUpperCase(), style: TextStyle(color: theme.textColor, fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  // --- CRITICAL FIX: UPDATED LOGOUT LOGIC ---
  void _showLogoutWarning(ThemeManager theme) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.redAccent.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.redAccent), SizedBox(width: 12), Text("WARNING", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
        content: Text("ABORTING SESSION WILL WIPE LOCAL DATA AND DISCONNECT NEURAL LINK.", style: TextStyle(color: theme.subText, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: theme.subText))),
          TextButton(
            onPressed: () async {
              // 1. Get Controller
              final taskController = Provider.of<TaskController>(context, listen: false);

              // 2. Wipe Local Data
              await taskController.resetAllData();

              // 3. Close Dialog
              if (context.mounted) Navigator.pop(context);

              // 4. Sign Out of Firebase
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("ABORT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  // UPDATED AVATAR BUILDER (Smart Loader + Tap)
  Widget _buildGlitchAvatar(ThemeManager theme, Color color) {
    return GestureDetector(
      onTap: () => _showAvatarSelection(theme), // Tap to change
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: _isGlitching ? Matrix4.translationValues(Random().nextDouble() * 4 - 2, Random().nextDouble() * 4 - 2, 0) : Matrix4.identity(),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _isGlitching ? theme.textColor : color, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(_isGlitching ? 0.8 : 0.2), blurRadius: _isGlitching ? 20 : 10)],
        ),
        child: CircleAvatar(
          backgroundColor: theme.bgColor,
          backgroundImage: _getAvatarProvider(_selectedAvatar), // Uses smart loader
        ),
      ),
    );
  }

  Widget _buildColorDot(ThemeManager theme, Color color) {
    bool isSelected = theme.accentColor.value == color.value;
    return GestureDetector(
      onTap: () {
        theme.setAccentColor(color);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: theme.textColor, width: 3) : Border.all(color: Colors.transparent, width: 3),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)] : [],
        ),
        child: isSelected ? Center(child: Icon(Icons.check, size: 18, color: Colors.black)) : null,
      ),
    );
  }

  Widget _buildSwitchRow(ThemeManager theme, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(color: theme.bgColor, borderRadius: BorderRadius.circular(12)),
        child: SwitchListTile(
          title: Text(title, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: TextStyle(color: theme.subText, fontSize: 11)),
          activeColor: theme.accentColor,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimePickerRow(ThemeManager theme, String label, TimeOfDay time, Function(TimeOfDay) onTimePicked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.subText.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 13)),
          GestureDetector(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: time,
                builder: (context, child) => Theme(data: theme.isDark ? ThemeData.dark() : ThemeData.light(), child: child!),
              );
              if (picked != null) onTimePicked(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.accentColor),
              ),
              child: Text(
                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTile(ThemeManager theme, IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    Color color = isDestructive ? Colors.redAccent : theme.textColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDestructive ? Colors.redAccent.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: theme.subText, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.subText.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(ThemeManager theme, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: theme.accentColor,
            collapsedIconColor: theme.subText,
            title: Text(question, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(answer, style: TextStyle(color: theme.subText, fontSize: 12, height: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMosaicStat(ThemeManager theme, String label, String value, IconData icon, Color color, {required double flex, VoidCallback? onTap}) {
    return Expanded(flex: (flex * 10).toInt(), child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)), boxShadow: theme.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 12), FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.w900))), const SizedBox(height: 2), Text(label, style: TextStyle(color: theme.subText, fontSize: 9, fontWeight: FontWeight.bold))]))));
  }

  Widget _buildSystemTile(ThemeManager theme, IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isHighlighted = false}) {
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: isHighlighted ? Border.all(color: theme.accentColor.withOpacity(0.5)) : null, boxShadow: theme.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: ListTile(onTap: onTap, leading: Icon(icon, color: isHighlighted ? theme.accentColor : (theme.isDark ? Colors.white70 : Colors.black54), size: 22), title: Text(title, style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold)), subtitle: Text(subtitle, style: TextStyle(color: theme.subText, fontSize: 11)), trailing: Icon(Icons.chevron_right_rounded, color: theme.isDark ? Colors.white38 : Colors.black26, size: 18)));
  }

  Widget _buildGlitchText(String text, ThemeManager theme) {
    return Stack(children: [Transform.translate(offset: const Offset(-2, 0), child: Text(text, style: const TextStyle(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1))), Transform.translate(offset: const Offset(2, 0), child: Text(text, style: const TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1))), Text(text, style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1))]);
  }

  Widget _buildPulsingStatusDot() {
    return TweenAnimationBuilder(tween: Tween<double>(begin: 0.2, end: 1.0), duration: const Duration(seconds: 1), builder: (context, double opacity, child) {return Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF00FF41).withOpacity(opacity), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF00FF41).withOpacity(opacity), blurRadius: 6)]));});
  }

  Widget _buildAnimatedScanner(ThemeManager theme) {
    return SizedBox(width: 30, height: 30, child: Stack(children: [Center(child: Icon(Icons.qr_code_2_rounded, color: theme.isDark ? Colors.white30 : Colors.black26, size: 30)), AnimatedBuilder(animation: _scannerAnimation, builder: (context, child) {return Positioned(top: _scannerAnimation.value * 28, child: Container(width: 30, height: 2, decoration: BoxDecoration(color: theme.accentColor, boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.8), blurRadius: 4)])));})]));
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    final xpController = context.watch<XpController>();

    return ListenableBuilder(
        listenable: ThemeManager(),
        builder: (context, child) {
          final theme = ThemeManager();
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: theme.bgColor,
                    child: Opacity(
                      opacity: theme.isDark ? 0.03 : 0.05,
                      child: SvgPicture.asset('assets/textures/circuit_pattern.svg', fit: BoxFit.cover, colorFilter: ColorFilter.mode(theme.textColor, BlendMode.srcIn)),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RotatedBox(quarterTurns: 3, child: Text("UNIT #$shortId", style: TextStyle(color: theme.subText, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          GestureDetector(onTap: _triggerGlitch, child: _buildGlitchAvatar(theme, theme.accentColor)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [_isGlitching ? _buildGlitchText(userName, theme) : Text(userName, style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(width: 8), _buildPulsingStatusDot()]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text("Level ${xpController.level}", style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text("Rank ${xpController.getRankName()}", style: const TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold))
                                  )
                                ]),
                              ],
                            ),
                          ),
                          GestureDetector(onTap: () => _showIdentityCard(theme), child: _buildAnimatedScanner(theme)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // STATS
                      Text("TACTICAL STATUS", style: TextStyle(color: theme.subText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      IntrinsicHeight(child: Row(children: [
                        _buildMosaicStat(theme, "TOTAL XP", xpController.currentXp.toString(), Icons.bolt_rounded, const Color(0xFFFFD700), flex: 1.2, onTap: () => _showTacticalToast("> DOWNLOADING XP LOGS...", theme)),
                        const SizedBox(width: 12),
                        _buildMosaicStat(theme, "STREAK", _currentStreak.toString(), Icons.local_fire_department_rounded, Colors.orangeAccent, flex: 1, onTap: () => _showTacticalToast("> SYNCING STREAK DATA...", theme))
                      ])),
                      const SizedBox(height: 12),
                      IntrinsicHeight(child: Row(children: [
                        _buildMosaicStat(theme, "QUESTS", _totalQuests.toString(), Icons.verified_rounded, theme.accentColor, flex: 1, onTap: () => _showTacticalToast("> RETRIEVING QUEST ARCHIVE...", theme)),
                        const SizedBox(width: 12),
                        _buildMosaicStat(theme, "GLOBAL RANK", "#${(10000 - xpController.currentXp).clamp(1, 10000)}", Icons.leaderboard_rounded, const Color(0xFF6C63FF), flex: 1.2, onTap: () => _showTacticalToast("> UPDATING LEADERBOARD...", theme))
                      ])),
                      const SizedBox(height: 32),

                      // SETTINGS
                      Text("SYSTEM SETTINGS", style: TextStyle(color: theme.subText, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 16),

                      // 1. INTERFACE CALIBRATION (Opened via Tap)
                      _buildSystemTile(
                          theme,
                          Icons.tune_rounded,
                          "Interface Calibration",
                          "Visual & Neural Frequency",
                          isHighlighted: true,
                          onTap: () => _showThemeSettings(theme)
                      ),

                      // --- NEW: ACHIEVEMENT TILE ---
                      _buildSystemTile(
                          theme,
                          Icons.military_tech_rounded,
                          "Achievements",
                          "Service Record & Badges",
                          onTap: () => _showAchievements(theme)
                      ),

                      // 2. NOTIFICATIONS (Opened via Tap)
                      _buildSystemTile(
                          theme,
                          Icons.notifications_none_rounded,
                          "Notifications",
                          "Comms Uplink & Alerts",
                          onTap: () => _showNotificationSettings(theme)
                      ),

                      _buildSystemTile(theme, Icons.security_rounded, "Privacy & Data", "Secure Hunter Protocol", onTap: () => _showPrivacySettings(theme)),

                      _buildSystemTile(
                        theme,
                        Icons.confirmation_num_outlined,
                        "Supply Depot",
                        "Redeem Rewards & Gear",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TacticalRedeemPage())),
                      ),

                      _buildSystemTile(theme, Icons.help_outline_rounded, "Support", "System Help Desk", onTap: () => _showSupportCenter(theme)),
                      const SizedBox(height: 24),
                      GestureDetector(onTap: () => _showLogoutWarning(theme), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.redAccent.withOpacity(0.05), border: Border.all(color: Colors.redAccent.withOpacity(0.2))), child: const Center(child: Text("ABORT SESSION", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 2))))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }
}

// ==========================================================
//  TACTICAL REDEEM PAGE
// ==========================================================

class TacticalRedeemPage extends StatefulWidget {
  const TacticalRedeemPage({super.key});

  @override
  State<TacticalRedeemPage> createState() => _TacticalRedeemPageState();
}

class _TacticalRedeemPageState extends State<TacticalRedeemPage> {
  final List<Coupon> coupons = [
    Coupon(
      brandName: "ETLE FASHION",
      category: "PREMIUM APPAREL",
      discount: "20% OFF",
      embersRequired: 500,
      accentColor: const Color(0xFFD4AF37),
      code: "ETLE-20-STRIDE",
      imagePath: "assets/images/etle_logo.png",
    ),
    Coupon(
      brandName: "KANSHIKA CARE",
      category: "LUXURY SKINCARE",
      discount: "FREE KIT",
      embersRequired: 800,
      accentColor: const Color(0xFFFF69B4),
      code: "KAN-GIFT-SYS",
      imagePath: "assets/images/kanshika_logo.png",
    ),
    Coupon(
      brandName: "AMAZON",
      category: "GIFT CARD",
      discount: "\$10 CREDIT",
      embersRequired: 1200,
      accentColor: const Color(0xFFFF9900),
      code: "AMZ-10-GIFT",
      imagePath: "https://img.icons8.com/color/48/amazon.png",
    ),
    Coupon(
      brandName: "STARBUCKS",
      category: "CONSUMABLE",
      discount: "FREE LATTE",
      embersRequired: 400,
      accentColor: const Color(0xFF00704A),
      code: "SBX-FREE-COF",
      imagePath: "https://img.icons8.com/color/48/starbucks.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final xpController = context.watch<XpController>();

    return ListenableBuilder(
        listenable: ThemeManager(),
        builder: (context, child) {
          final theme = ThemeManager();
          return Scaffold(
            backgroundColor: theme.bgColor,
            appBar: AppBar(
              title: Text("SUPPLY DEPOT", style: TextStyle(color: theme.textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.textColor),
            ),
            body: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.1), blurRadius: 15)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("AVAILABLE EMBERS:", style: TextStyle(color: theme.subText, fontSize: 12, letterSpacing: 1)),
                      Text("${xpController.embers} EMBERS", style: TextStyle(color: theme.accentColor, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: GestureDetector(
                          onTap: () => _showEnlargedTicket(context, coupon, theme, xpController),
                          child: ClipPath(
                            clipper: TicketClipper(),
                            child: Container(
                              height: 110,
                              color: theme.cardColor,
                              child: Row(
                                children: [
                                  Container(width: 8, color: coupon.accentColor),
                                  const SizedBox(width: 15),

                                  Hero(
                                    tag: coupon.code,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]
                                      ),
                                      child: _buildLogoImage(coupon.imagePath, 45),
                                    ),
                                  ),
                                  const SizedBox(width: 15),

                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(coupon.brandName, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                                        const SizedBox(height: 4),
                                        Text(coupon.category, style: TextStyle(color: theme.subText, fontSize: 10, letterSpacing: 1.5)),
                                      ],
                                    ),
                                  ),

                                  Container(height: 60, width: 1, color: theme.subText.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 10)),
                                  SizedBox(width: 90, child: Center(child: Text(coupon.discount, textAlign: TextAlign.center, style: TextStyle(color: coupon.accentColor, fontWeight: FontWeight.w900, fontSize: 14)))),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  // --- HELPER TO SWITCH BETWEEN ASSET AND NETWORK ---
  Widget _buildLogoImage(String path, double size) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: size, height: size, fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.grey, size: size),
      );
    } else {
      return Image.asset(
        path,
        width: size, height: size, fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.grey, size: size),
      );
    }
  }

  void _showEnlargedTicket(BuildContext context, Coupon coupon, ThemeManager theme, XpController xp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: coupon.accentColor, width: 2)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(width: 50, height: 4, decoration: BoxDecoration(color: theme.subText.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 30),

            Hero(
              tag: coupon.code,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: coupon.accentColor.withOpacity(0.5), blurRadius: 20)]),
                child: _buildLogoImage(coupon.imagePath, 100),
              ),
            ),
            const SizedBox(height: 15),
            Text(coupon.brandName, style: TextStyle(color: theme.textColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 30),

            ClipPath(
              clipper: TicketClipper(),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(color: coupon.accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(coupon.discount, style: TextStyle(color: coupon.accentColor, fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    BarcodeWidget(barcode: Barcode.code128(), data: coupon.code, color: theme.textColor, height: 60, width: double.infinity, drawText: false),
                    const SizedBox(height: 15),
                    Text(coupon.code, style: TextStyle(color: theme.subText, fontFamily: 'Courier', letterSpacing: 3, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text("OFFER EXPIRES IN 24H", style: TextStyle(color: Colors.redAccent, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 20),

            // --- REDEEM BUTTON (LOGIC CONNECTED) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: xp.embers >= coupon.embersRequired ? coupon.accentColor : Colors.grey[800],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: xp.embers >= coupon.embersRequired
                    ? () {
                  // DEDUCT EMBERS via CONTROLLER
                  bool success = xp.spendEmbers(coupon.embersRequired);
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: theme.cardColor, content: Text("ITEM ACQUIRED: ${coupon.brandName}", style: TextStyle(color: coupon.accentColor))));
                  }
                }
                    : null,
                child: Text(xp.embers >= coupon.embersRequired ? "ACQUIRE FOR ${coupon.embersRequired} EMBERS" : "INSUFFICIENT EMBERS", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double r = 15;
    path.lineTo(0, size.height / 2 - r);
    path.arcToPoint(Offset(0, size.height / 2 + r), radius: Radius.circular(r), clockwise: true);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height / 2 + r);
    path.arcToPoint(Offset(size.width, size.height / 2 - r), radius: Radius.circular(r), clockwise: true);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}