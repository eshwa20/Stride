import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class XpController extends ChangeNotifier {
  int _currentXp = 0;
  int _embers = 0; // The missing currency variable
  int _level = 1;

  // GETTERS
  int get currentXp => _currentXp;
  int get embers => _embers;
  int get level => _level;

  // ATTRIBUTES
  final Map<String, double> _attributes = {
    'STR': 60, 'AGI': 50, 'INT': 70, 'VIT': 80, 'SEN': 40,
  };
  Map<String, double> get attributes => _attributes;

  XpController() {
    _loadFromHive();
  }

  // --- ACTIONS ---

  void addXp(int amount) {
    _currentXp += amount;
    _embers += amount; // Earn embers alongside XP
    _checkLevelUp();
    _saveToHive();
    notifyListeners();
  }

  // The missing function causing the error
  bool spendEmbers(int amount) {
    if (_embers >= amount) {
      _embers -= amount;
      _saveToHive();
      notifyListeners();
      return true;
    }
    return false;
  }

  // The missing rank function causing the error
  String getRankName() {
    if (_level >= 50) return "S-CLASS";
    if (_level >= 30) return "COMMANDER";
    if (_level >= 20) return "VETERAN";
    if (_level >= 10) return "OPERATOR";
    return "ROOKIE";
  }

  // --- INTERNAL LOGIC ---

  void _checkLevelUp() {
    int newLevel = (_currentXp ~/ 1000) + 1;
    if (newLevel > _level) {
      _level = newLevel;
    }
  }

  Future<void> _loadFromHive() async {
    var box = await Hive.openBox('stepBox');
    _currentXp = box.get('xp', defaultValue: 0);
    _embers = box.get('embers', defaultValue: 0);
    _level = box.get('level', defaultValue: 1);
    notifyListeners();
  }

  Future<void> _saveToHive() async {
    var box = await Hive.openBox('stepBox');
    box.put('xp', _currentXp);
    box.put('embers', _embers);
    box.put('level', _level);
  }
}