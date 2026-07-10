// ===========================================
// Zsolt Pro AI
// Version: v0.6.0
// File: lib/services/betslip_service.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../models/betslip_item.dart';

class BetslipService extends ChangeNotifier {
  BetslipService._();

  static final BetslipService instance = BetslipService._();

  final List<BetslipItem> _items = <BetslipItem>[];

  List<BetslipItem> get items {
    return List<BetslipItem>.unmodifiable(_items);
  }

  List<AppMatch> get matches {
    return _items
        .map(
          (item) => item.match,
        )
        .toList(growable: false);
  }

  int get itemCount => _items.length;

  bool get isEmpty => _items.isEmpty;

  bool contains(String matchId) {
    return _items.any(
      (item) => item.id == matchId,
    );
  }

  BetslipItem? getItem(String matchId) {
    for (final BetslipItem item in _items) {
      if (item.id == matchId) {
        return item;
      }
    }

    return null;
  }

  bool addItem(BetslipItem item) {
    if (contains(item.id)) {
      return false;
    }

    _items.add(item);
    notifyListeners();

    return true;
  }

  bool addMatch(
    AppMatch match, {
    String market = 'AI ajánlott piac',
    String selection = '1X és több mint 1,5 gól',
    double odds = 0.0,
  }) {
    final BetslipItem item = BetslipItem(
      match: match,
      market: market,
      selection: selection,
      odds: odds,
    );

    return addItem(item);
  }

  bool updateItem({
    required String matchId,
    String? market,
    String? selection,
    double? odds,
  }) {
    final int index = _items.indexWhere(
      (item) => item.id == matchId,
    );

    if (index == -1) {
      return false;
    }

    final BetslipItem currentItem = _items[index];

    _items[index] = currentItem.copyWith(
      market: market,
      selection: selection,
      odds: odds,
    );

    notifyListeners();

    return true;
  }

  bool removeMatch(String matchId) {
    final int oldLength = _items.length;

    _items.removeWhere(
      (item) => item.id == matchId,
    );

    final bool removed = _items.length < oldLength;

    if (removed) {
      notifyListeners();
    }

    return removed;
  }

  void toggleMatch(
    AppMatch match, {
    String market = 'AI ajánlott piac',
    String selection = '1X és több mint 1,5 gól',
    double odds = 0.0,
  }) {
    if (contains(match.id)) {
      removeMatch(match.id);
    } else {
      addMatch(
        match,
        market: market,
        selection: selection,
        odds: odds,
      );
    }
  }

  double get totalOdds {
    if (_items.isEmpty) {
      return 0.0;
    }

    final List<double> validOdds = _items
        .map(
          (item) => item.odds,
        )
        .where(
          (odds) => odds > 0,
        )
        .toList();

    if (validOdds.isEmpty) {
      return 0.0;
    }

    return validOdds.fold<double>(
      1.0,
      (total, odds) => total * odds,
    );
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();
    notifyListeners();
  }
}
