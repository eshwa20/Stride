import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';

// Services
import 'services/notification_service.dart';

// Screens
import 'splash/splash_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'onboarding/identity_protocol_screen.dart';
import 'auth/login_screen.dart';
import 'ascension/ascension_screen.dart';

// Navigation Shell
import 'navigation/app_shell.dart';

// Controllers
import 'controllers/xp_controller.dart';
import 'controllers/task_controller.dart';
import 'selection/mode_controller.dart';

// Theme
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Database
  await Hive.initFlutter();

  // --- OPEN ALL BOXES (CRITICAL FOR APP FUNCTIONALITY) ---
  await Hive.openBox('stepBox');      // Stores XP & Level
  await Hive.openBox('settingsBox');  // Stores Theme & Accent Color
  await Hive.openBox('statsBox');     // Stores Analytics & Focus History
  await Hive.openBox('tasks');        // Stores Quests & Tasks

  // Initialize Notifications (Astra)
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => XpController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => ModeController()),
      ],
      child: const StrideApp(),
    ),
  );
}

class StrideApp extends StatelessWidget {
  const StrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stride',

      // Theme Logic
      themeMode: themeManager.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // ROUTING
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/identity': (context) => const IdentityProtocolScreen(),
        '/auth': (context) => const LoginScreen(),
        '/home': (context) => AppShell(),
        '/ascension': (context) => AscensionScreen(
          onComplete: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
      },
    );
  }
}