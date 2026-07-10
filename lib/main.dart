// ===========================================
// Zsolt Pro AI
// Version: v0.4.4
// File: lib/main.dart
// ===========================================

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService.instance.loadTheme();

  runApp(const ZsoltProAI());
}

class ZsoltProAI extends StatelessWidget {
  const ZsoltProAI({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Zsolt Pro AI',

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,

          home: const ZsoltProApp(),
        );
      },
    );
  }
}
