import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeManager extends ChangeNotifier {
  // Singleton Pattern: Ensures the entire app uses the same theme instance
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  // Constructor: Loads saved settings immediately when the app starts
  ThemeManager._internal() {
    _loadFromStorage();
  }

  // --- VARIABLES ---
  bool _isDark = true; // Default to "Stealth Mode" (Dark)
  Color _accentColor = const Color(0xFF00D2D3); // Default to Cyan

  // --- GETTERS (The UI listens to these) ---
  bool get isDark => _isDark;
  Color get accentColor => _accentColor;

  // --- DYNAMIC COLORS (Auto-update based on mode) ---
  // Background: Deep Blue-Black (Dark) or Clean Grey-White (Light)
  Color get bgColor => _isDark ? const Color(0xFF0D1117) : const Color(0xFFF2F4F8);

  // Cards: Dark Grey (Dark) or Pure White (Light)
  Color get cardColor => _isDark ? const Color(0xFF161B22) : Colors.white;

  // Text: White (Dark) or Dark Navy (Light)
  Color get textColor => _isDark ? Colors.white : const Color(0xFF1A1A2D);

  // Subtext: Faded White (Dark) or Grey (Light)
  Color get subText => _isDark ? Colors.white54 : const Color(0xFF6E6E80);

  // --- STORAGE LOGIC (The Brain) ---
  void _loadFromStorage() {
    // NOTE: 'settingsBox' MUST be opened in main.dart before this runs
    if (Hive.isBoxOpen('settingsBox')) {
      final box = Hive.box('settingsBox');

      // 1. Load Theme Mode
      _isDark = box.get('isDark', defaultValue: true);

      // 2. Load Accent Color
      int colorValue = box.get('accentColor', defaultValue: 0xFF00D2D3);
      _accentColor = Color(colorValue);

      notifyListeners();
    }
  }

  // --- ACTIONS (Call these from your Settings Page) ---

  // Switch between Light & Dark
  // Accepts a boolean to match the Switch widget's onChanged(val)
  void toggleTheme(bool isDark) {
    _isDark = isDark;
    if (Hive.isBoxOpen('settingsBox')) {
      Hive.box('settingsBox').put('isDark', _isDark);
    }
    notifyListeners();
  }

  // Change the main "Hero Color" (Red, Green, Gold, etc.)
  void setAccentColor(Color color) {
    _accentColor = color;
    if (Hive.isBoxOpen('settingsBox')) {
      Hive.box('settingsBox').put('accentColor', _accentColor.value);
    }
    notifyListeners();
  }
}