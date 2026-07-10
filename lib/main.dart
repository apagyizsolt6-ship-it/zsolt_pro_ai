// Zsolt Pro AI
// Version: v0.1.0
// File: lib/main.dart

import 'package:flutter/material.dart';

void main() {
  runApp(const ZsoltProAI());
}

class ZsoltProAI extends StatelessWidget {
  const ZsoltProAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zsolt Pro AI',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Zsolt Pro AI',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
