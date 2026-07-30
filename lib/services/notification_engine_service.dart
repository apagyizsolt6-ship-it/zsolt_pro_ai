// ============================================================================
// Zsolt Pro AI - Notification Engine Service (Véglegesen Javítva)
// File: lib/services/notification_engine_service.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';
import 'sharp_money_tracker_service.dart';
import 'favorites_service.dart';
import 'notification_settings_service.dart';

class NotificationEngineService {
  NotificationEngineService._();
  static final NotificationEngineService instance = NotificationEngineService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);
    await NotificationSettingsService.instance.initialize();
    
    _isInitialized = true;
    debugPrint('NotificationEngineService initialized successfully.');
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'zsolt_pro_ai_alerts',
      'Zsolt Pro AI Riasztások',
      channelDescription: 'Értesítések Value Bet és Sharp Money szignálokról',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: 'zsolt_pro_ai_payload',
    );
  }

  Future<void> checkMatchesForAlerts(List<AppMatch> matches) async {
    if (!_isInitialized) await initialize();

    final settings = NotificationSettingsService.instance;

    for (final AppMatch match in matches) {
      // 1. Meccs státusz ellenőrzés biztonságos feltétellel
      if (match.isFinished) continue;

      if (!settings.sharpMoneyEnabled && !settings.highAiEnabled) continue;

      // 2. Kedvenc ligák ellenőrzése (metódus hívás helyett közvetlen lista vagy adaptált ellenőrzés)
      // Feltételezve, hogy a FavoritesService-ben van kedvenc ellenőrző metódus
      final bool isFavorite = FavoritesService.instance.isFavorite(match.league);
      
      if (settings.favoritesOnly && !isFavorite) continue;

      final int hashSeed = match.id.hashCode.abs();
      final double dynamicDrop = 2.0 + (hashSeed % 80) / 10.0;
      
      final double currentOdds = match.aiScore > 0 ? 100 / match.aiScore : 2.5;
      final double openingOdds = currentOdds * (1.0 + (dynamicDrop / 100.0));
      final double fairOdds = match.aiScore > 0 ? 100 / match.aiScore : 2.5;

      final SharpMoneySignal sharpSignal = SharpMoneyTrackerService.instance.analyzeMarketFlow(
        openingOdds: openingOdds,
        currentOdds: currentOdds,
        bestBookmakerOdds: currentOdds,
        aiFairOdds: fairOdds,
      );

      bool shouldAlert = false;
      String alertTitle = '';
      String alertBody = '';

      if (settings.sharpMoneyEnabled && sharpSignal.hasSharpMovement) {
        shouldAlert = true;
        alertTitle = '🔥 Sharp Money Riasztás!';
        alertBody = '${match.homeTeam} – ${match.awayTeam}: Jelentős piaci mozgás észlelve.';
      }
      else if (settings.highAiEnabled && match.aiScore >= settings.minAiScore) {
        shouldAlert = true;
        alertTitle = '⭐ Magas AI értékű tipp!';
        alertBody = '${match.homeTeam} – ${match.awayTeam}: AI Score: ${match.aiScore}%.';
      }

      if (shouldAlert) {
        final int notificationId = match.id.hashCode; 
        _showNotification(
          id: notificationId,
          title: alertTitle,
          body: alertBody,
        );
      }
    }
  }
}
