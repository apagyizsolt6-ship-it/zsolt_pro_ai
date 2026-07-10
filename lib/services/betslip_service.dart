// ===========================================
// Zsolt Pro AI
// Version: v0.5.4
// File: lib/services/betslip_service.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';

class BetslipService extends ChangeNotifier {
  BetslipService._();

  static final BetslipService instance = BetslipService._();

  final List<AppMatch> _matches = <AppMatch>[];

  List<AppMatch> get matches {
    return List<AppMatch>.unmodifiable(_matches);
  }

  int get itemCount => _matches.length;

  bool get isEmpty => _matches.isEmpty;

  bool contains(String matchId) {
    return _matches.any(
      (match) => match.id == matchId,
    );
  }

  bool addMatch(AppMatch match) {
    if (contains(match.id)) {
      return false;
    }

    _matches.add(match);
    notifyListeners();

    return true;
  }

  bool removeMatch(String matchId) {
    final int oldLength = _matches.length;

    _matches.removeWhere(
      (match) => match.id == matchId,
    );

    final bool removed = _matches.length < oldLength;

    if (removed) {
      notifyListeners();
    }

    return removed;
  }

  void toggleMatch(AppMatch match) {
    if (contains(match.id)) {
      removeMatch(match.id);
    } else {
      addMatch(match);
    }
  }

  void clear() {
    if (_matches.isEmpty) {
      return;
    }

    _matches.clear();
    notifyListeners();
  }
}
