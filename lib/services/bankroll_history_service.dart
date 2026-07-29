// ============================================================================
// Zsolt Pro AI - Bankroll History & ROI Tracking Service
// File: lib/services/bankroll_history_service.dart
// ============================================================================

import 'package:flutter/foundation.dart';

class BetRecord {
  final String id;
  final String matchTitle;
  final String selection;
  final double odds;
  final double stake;
  final bool isWon;
  final bool isFinished;
  final DateTime date;

  const BetRecord({
    required this.id,
    required this.matchTitle,
    required this.selection,
    required this.odds,
    required this.stake,
    required this.isWon,
    required this.isFinished,
    required this.date,
  });

  double get profit {
    if (!isFinished) return 0.0;
    if (isWon) return (stake * odds) - stake;
    return -stake;
  }
}

class BankrollHistoryService extends ChangeNotifier {
  BankrollHistoryService._();
  static final BankrollHistoryService instance = BankrollHistoryService._();

  double _initialBankroll = 100000.0;
  final List<BetRecord> _history = <BetRecord>[];

  double get initialBankroll => _initialBankroll;
  
  double get currentBankroll {
    double totalProfit = 0.0;
    for (final BetRecord record in _history) {
      totalProfit += record.profit;
    }
    return _initialBankroll + totalProfit;
  }

  List<BetRecord> get history => List<BetRecord>.unmodifiable(_history);

  int get totalBets => _history.where((b) => b.isFinished).length;
  
  int get wonBets => _history.where((b) => b.isFinished && b.isWon).length;

  double get roi {
    final finished = _history.where((b) => b.isFinished).toList();
    if (finished.isEmpty) return 0.0;
    
    double totalStakes = 0.0;
    double totalProfit = 0.0;
    
    for (final BetRecord b in finished) {
      totalStakes += b.stake;
      totalProfit += b.profit;
    }
    
    if (totalStakes <= 0) return 0.0;
    return (totalProfit / totalStakes) * 100.0;
  }

  void setInitialBankroll(double amount) {
    _initialBankroll = amount;
    notifyListeners();
  }

  void addBetRecord({
    required String matchTitle,
    required String selection,
    required double odds,
    required double stake,
  }) {
    final record = BetRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchTitle: matchTitle,
      selection: selection,
      odds: odds,
      stake: stake,
      isWon: false,
      isFinished: false,
      date: DateTime.now(),
    );
    _history.insert(0, record);
    notifyListeners();
  }

  void resolveBet(String id, bool isWon) {
    final index = _history.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = _history[index];
      _history[index] = BetRecord(
        id: old.id,
        matchTitle: old.matchTitle,
        selection: old.selection,
        odds: old.odds,
        stake: old.stake,
        isWon: isWon,
        isFinished: true,
        date: old.date,
      );
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
