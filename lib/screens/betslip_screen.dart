// ===========================================
// Zsolt Pro AI
// Version: v0.1.0
// File: lib/screens/betslip_screen.dart
// ===========================================

import 'package:flutter/material.dart';

class BetslipScreen extends StatelessWidget {
  const BetslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎫 Szelvény"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [

              Icon(
                Icons.receipt_long,
                size: 90,
                color: Colors.blue,
              ),

              SizedBox(height: 20),

              Text(
                "A szelvényed jelenleg üres.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 12),

              Text(
                "A Meccsek képernyőről tudsz majd tippeket hozzáadni.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
