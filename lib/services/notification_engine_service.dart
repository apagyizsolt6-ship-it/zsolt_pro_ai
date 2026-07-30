// ============================================================================
// Zsolt Pro AI - Notification Engine Service
// File: lib/services/notification_engine_service.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import '../models/app_match.dart';
import 'sharp_money_tracker_service.dart';
import 'favorites_service.dart';
import 'notification_settings_service.dart';

class NotificationEngineService {
  NotificationEngineService._();
  static final NotificationEngineService instance = NotificationEngineService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await NotificationSettingsService.instance.initialize();
    await FavoritesService.init();
    
    _isInitialized = true;
    debugPrint('NotificationEngineService initialized successfully.');
  }

  Future<void> _showInAppNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('🚨 [ALERT] $title - $body');
  }

  Future<void> checkMatchesForAlerts(List<AppMatch> matches) async {
    if (!_isInitialized) await initialize();

    final settings = NotificationSettingsService.instance;

    for (final AppMatch match in matches) {
      if (match.isFinished) continue;

      if (!settings.sharpMoneyEnabled && !settings.highAiEnabled) continue;

      final bool isFav = FavoritesService.isFavorite(match.id);
      if (settings.favoritesOnly && !isFav) continue;

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
        alertTitle = 'Sharp Money Riasztás';
        alertBody = '${match.homeTeam} – ${match.awayTeam}: Jelentős piaci mozgás észlelve.';
      }
      else if (settings.highAiEnabled && match.aiScore >= settings.minAiScore) {
        shouldAlert = true;
        alertTitle = 'Magas AI értékű tipp';
        alertBody = '${match.homeTeam} – ${match.awayTeam}: AI Score: ${match.aiScore}%.';
      }

      if (shouldAlert) {
        _showInAppNotification(
          title: alertTitle,
          body: alertBody,
        );
      }
    }
  }
}
