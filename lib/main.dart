// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/main.dart
// ===========================================

import 'package:flutter/material.dart';

import 'app.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ZsoltProAI());
}

class ZsoltProAI extends StatelessWidget {
  const ZsoltProAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zsolt Pro AI',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      home: const ZsoltProApp(),
    );
  }
}
