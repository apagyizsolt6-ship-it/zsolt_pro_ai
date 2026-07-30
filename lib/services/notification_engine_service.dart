// ============================================================================
// Zsolt Pro AI - Notification Engine Service (Finomhangolt)
// File: lib/services/notification_engine_service.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';
import 'sharp_money_tracker_service.dart';
import 'favorites_service.dart';
import 'notification_settings_service.dart'; // <--- Új import

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
    
    // Inicializáljuk a beállításokat is
    await NotificationSettingsService.instance.initialize();
    
    _isInitialized = true;
    debugPrint('NotificationEngineService initialized (with settings).');
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'zsolt_pro_ai_alerts',
      'Zsolt Pro AI Riasztások',
      channelDescription: 'Értesítések Value Bet és Sharp Money szignálokról',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    const NotificationDetails platformChannelSpecifics =
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

    // Lekérjük a felhasználói beállításokat
    final settings = NotificationSettingsService.instance;

    for (final AppMatch match in matches) {
      if (match.status != MatchStatus.notStarted) continue;

      // 🚀 ÚJ: Ellenőrizzük, hogy be van-e kapcsolva bármilyen értesítés
      if (!settings.sharpMoneyEnabled && !settings.highAiEnabled) return;

      final bool isFavorite = FavoritesService.instance.isLeagueFavorite(match.league);
      
      // 🚀 ÚJ: Ha csak kedvenc ligákat figyelünk, és ez a meccs nem az
      if (settings.favoritesOnly && !isFavorite) continue;

      // Elemzés (mint tegnap)
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

      // 🚀 ÚJ: Sharp Money riasztás feltétele
      if (settings.sharpMoneyEnabled && sharpSignal.hasSharpMovement) {
        shouldAlert = true;
        alertTitle = '🔥 Sharp Money Riasztás!';
        alertBody = '${match.homeTeam} – ${match.awayTeam}: A piac hirtelen elmozdult a ${sharpSignal.sharpSide} irányába.';
      }
      
      // 🚀 ÚJ: Magas AI Score riasztás feltétele (felhasználói minimummal)
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
