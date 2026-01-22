import 'package:shared_preferences/shared_preferences.dart';

class TimerStatistics {
  int dailyFocusMinutes = 0;
  int weeklyFocusMinutes = 0;
  int monthlyFocusMinutes = 0;
  int currentStreak = 0;
  int longestStreak = 0;
  int totalSessionsCompleted = 0;
  int totalXpEarned = 0;
  DateTime? lastSessionDate;

  TimerStatistics({
    this.dailyFocusMinutes = 0,
    this.weeklyFocusMinutes = 0,
    this.monthlyFocusMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSessionsCompleted = 0,
    this.totalXpEarned = 0,
    this.lastSessionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyFocusMinutes': dailyFocusMinutes,
      'weeklyFocusMinutes': weeklyFocusMinutes,
      'monthlyFocusMinutes': monthlyFocusMinutes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalSessionsCompleted': totalSessionsCompleted,
      'totalXpEarned': totalXpEarned,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
    };
  }

  factory TimerStatistics.fromJson(Map<String, dynamic> json) {
    return TimerStatistics(
      dailyFocusMinutes: json['dailyFocusMinutes'] ?? 0,
      weeklyFocusMinutes: json['weeklyFocusMinutes'] ?? 0,
      monthlyFocusMinutes: json['monthlyFocusMinutes'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalSessionsCompleted: json['totalSessionsCompleted'] ?? 0,
      totalXpEarned: json['totalXpEarned'] ?? 0,
      lastSessionDate: json['lastSessionDate'] != null
          ? DateTime.parse(json['lastSessionDate'])
          : null,
    );
  }
}

class TimerSettings {
  int focusMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;
  String selectedPreset = 'Classic';
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  String selectedSound = 'bell';
  bool alwaysOnDisplay = false;

  TimerSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.selectedPreset = 'Classic',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.selectedSound = 'bell',
    this.alwaysOnDisplay = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'focusMinutes': focusMinutes,
      'shortBreakMinutes': shortBreakMinutes,
      'longBreakMinutes': longBreakMinutes,
      'sessionsBeforeLongBreak': sessionsBeforeLongBreak,
      'selectedPreset': selectedPreset,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'selectedSound': selectedSound,
      'alwaysOnDisplay': alwaysOnDisplay,
    };
  }

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    return TimerSettings(
      focusMinutes: json['focusMinutes'] ?? 25,
      shortBreakMinutes: json['shortBreakMinutes'] ?? 5,
      longBreakMinutes: json['longBreakMinutes'] ?? 15,
      sessionsBeforeLongBreak: json['sessionsBeforeLongBreak'] ?? 4,
      selectedPreset: json['selectedPreset'] ?? 'Classic',
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      selectedSound: json['selectedSound'] ?? 'bell',
      alwaysOnDisplay: json['alwaysOnDisplay'] ?? false,
    );
  }
}

class TimerService {
  static const String _statsKey = 'timer_statistics';
  static const String _settingsKey = 'timer_settings';

  static Future<TimerStatistics> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_statsKey);
    if (statsJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          statsJson as Map,
        );
        return TimerStatistics.fromJson(json);
      } catch (e) {
        // Return default if parsing fails
      }
    }
    return TimerStatistics();
  }

  static Future<void> saveStatistics(TimerStatistics stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, stats.toJson().toString());
  }

  static Future<TimerSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          settingsJson as Map,
        );
        return TimerSettings.fromJson(json);
      } catch (e) {
        // Return default if parsing fails
      }
    }
    return TimerSettings();
  }

  static Future<void> saveSettings(TimerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toJson().toString());
  }

  static Future<void> updateDailyStats(int minutesFocused) async {
    final stats = await loadStatistics();
    final now = DateTime.now();

    // Check if it's a new day
    if (stats.lastSessionDate == null ||
        !isSameDay(stats.lastSessionDate!, now)) {
      stats.dailyFocusMinutes = minutesFocused;
      stats.lastSessionDate = now;

      // Update streak
      if (stats.lastSessionDate != null &&
          isConsecutiveDay(stats.lastSessionDate!, now)) {
        stats.currentStreak++;
        if (stats.currentStreak > stats.longestStreak) {
          stats.longestStreak = stats.currentStreak;
        }
      } else {
        stats.currentStreak = 1;
      }
    } else {
      stats.dailyFocusMinutes += minutesFocused;
    }

    // Update weekly and monthly stats
    stats.weeklyFocusMinutes += minutesFocused;
    stats.monthlyFocusMinutes += minutesFocused;

    await saveStatistics(stats);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isConsecutiveDay(DateTime previous, DateTime current) {
    final difference = current.difference(previous).inDays;
    return difference == 1;
  }

  static int calculateXpGain(int focusMinutes, bool completed) {
    if (!completed) return 0;
    // Base XP: 10 per minute, bonus for longer sessions
    int baseXp = focusMinutes * 10;
    int bonusXp = focusMinutes > 45 ? (focusMinutes - 45) * 5 : 0;
    return baseXp + bonusXp;
  }

  static void resetWeeklyStats() {
    // This should be called weekly by a background service
    // For now, we'll handle it when loading stats
  }

  static void resetMonthlyStats() {
    // This should be called monthly by a background service
    // For now, we'll handle it when loading stats
  }
}