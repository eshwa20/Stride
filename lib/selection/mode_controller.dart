import 'package:flutter/material.dart';

enum AppMode { student, normal, personalized }

class ModeController extends ChangeNotifier {
  AppMode mode = AppMode.normal;
}
