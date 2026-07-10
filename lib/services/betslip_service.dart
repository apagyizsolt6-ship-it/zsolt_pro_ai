// ===========================================
// Zsolt Pro AI
// Version: v0.8.2
// File: lib/services/betslip_service.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../models/bet_builder_selection.dart';
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

  int get totalSelectionCount {
    return _items.fold<int>(
      0,
      (total, item) => total + item.selectionCount,
    );
  }

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

  bool addBetBuilder(
    AppMatch match, {
    required List<BetBuilderSelection> selections,
    double odds = 0.0,
  }) {
    if (selections.isEmpty) {
      return false;
    }

    final BetslipItem item = BetslipItem(
      match: match,
      market: 'Fogadáskészítő',
      selection: '${selections.length} kiválasztott tipp',
      builderSelections: List<BetBuilderSelection>.unmodifiable(
        selections,
      ),
      odds: odds,
    );

    return addItem(item);
  }

  bool updateItem({
    required String matchId,
    String? market,
    String? selection,
    List<BetBuilderSelection>? builderSelections,
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
      builderSelections: builderSelections,
      odds: odds,
    );

    notifyListeners();

    return true;
  }

  bool updateBetBuilder({
    required String matchId,
    required List<BetBuilderSelection> selections,
    double? odds,
  }) {
    if (selections.isEmpty) {
      return false;
    }

    return updateItem(
      matchId: matchId,
      market: 'Fogadáskészítő',
      selection: '${selections.length} kiválasztott tipp',
      builderSelections: List<BetBuilderSelection>.unmodifiable(
        selections,
      ),
      odds: odds,
    );
  }

  bool saveBetBuilder(
    AppMatch match, {
    required List<BetBuilderSelection> selections,
    double odds = 0.0,
  }) {
    if (selections.isEmpty) {
      return false;
    }

    if (contains(match.id)) {
      return updateBetBuilder(
        matchId: match.id,
        selections: selections,
        odds: odds,
      );
    }

    return addBetBuilder(
      match,
      selections: selections,
      odds: odds,
    );
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
          (item) => item.isBetBuilder
              ? item.builderOdds
              : item.odds,
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

  int get averageAiScore {
    if (_items.isEmpty) {
      return 0;
    }

    final int total = _items.fold<int>(
      0,
      (sum, item) {
        return sum +
            (item.isBetBuilder
                ? item.builderAiScore
                : item.match.aiScore);
      },
    );

    return (total / _items.length).round();
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();
    notifyListeners();
  }
}
