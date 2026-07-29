// ============================================================================
// Zsolt Pro AI - Bankroll & ROI Screen
// File: lib/screens/bankroll_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../services/bankroll_history_service.dart';

class BankrollScreen extends StatelessWidget {
  const BankrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final BankrollHistoryService bankrollService = BankrollHistoryService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Bankroll & ROI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: bankrollService,
        builder: (BuildContext context, Widget? child) {
          final double current = bankrollService.currentBankroll;
          final double initial = bankrollService.initialBankroll;
          final double profit = current - initial;
          final double roi = bankrollService.roi;
          final List<BetRecord> history = bankrollService.history;

          final Color profitColor = profit >= 0 ? Colors.greenAccent : Colors.redAccent;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Fő egyenleg kártya
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Aktuális Virtuális Tőke',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${current.toStringAsFixed(1)} Ft',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(
                            label: 'Össz. Profit',
                            value: '${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(1)} Ft',
                            valueColor: profitColor,
                          ),
                          _StatColumn(
                            label: 'ROI',
                            value: '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                            valueColor: profitColor,
                          ),
                          _StatColumn(
                            label: 'Találati arány',
                            value: bankrollService.totalBets > 0
                                ? '${((bankrollService.wonBets / bankrollService.totalBets) * 100).toStringAsFixed(0)}%'
                                : '0%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Fogadási Előzmények & Eredmények',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Még nincsenek rögzített fogadások.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...history.map((BetRecord record) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        record.matchTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${record.selection} • Odds: ${record.odds.toStringAsFixed(2)} • Tét: ${record.stake.toStringAsFixed(0)} Ft',
                      ),
                      trailing: record.isFinished
                          ? Chip(
                              label: Text(
                                record.isWon ? 'NYERT' : 'VESZTETT',
                                style: TextStyle(
                                  color: record.isWon ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: (record.isWon ? Colors.green : Colors.red).withValues(alpha: 0.15),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => bankrollService.resolveBet(record.id, true),
                                  tooltip: 'Nyertnek jelöl',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => bankrollService.resolveBet(record.id, false),
                                  tooltip: 'Vesztesnek jelöl',
                                ),
                              ],
                            ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? colors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
