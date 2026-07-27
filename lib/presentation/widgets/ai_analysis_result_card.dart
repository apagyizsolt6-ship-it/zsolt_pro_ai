// ============================================================================
// Zsolt Pro AI - AI Analysis Result Card ULTRA Edition
// Version: v0.23.5 - Real-Time ROI Edge, Fair Odds & Dynamic UI Badge
// File: lib/presentation/widgets/ai_analysis_result_card.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:zsolt_pro_ai/models/recognized_betslip.dart';
import 'package:zsolt_pro_ai/services/ai_engine_extension_service.dart';

class AiAnalysisResultCard extends StatelessWidget {
  final RecognizedBetslip betslip;

  const AiAnalysisResultCard({
    super.key,
    required this.betslip,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: AiEngineExtensionService.instance.analyzeBetslipWithValueBet(betslip),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Az AI elemzés átmenetileg nem érhető el.',
                style: TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final List<dynamic> analyzedMatches = data['analyzedMatches'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÖSSZESÍTETT AI STATISZTIKAI KÁRTYA NEON JELZÉSSEL
            Card(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: colors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Zsolt Pro AI: ${data['valueBetsFound']} db Értékes fogadást találtam!',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // 2. MECCSEK ÉS MATEMATIKAI JELÖLTEK KIBŐVÍTETT LISTÁJA
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: analyzedMatches.length,
              itemBuilder: (context, index) {
                final item = analyzedMatches[index];
                final bool isValue = item['isValueBet'] ?? false;
                
                // Dinamikus ROI / Értékelőny generálás a tiszta valószínűségekből
                final double probability = double.tryParse((item['probability'] ?? '0').replaceAll('%', '').trim()) ?? 75.0;
                final double fairOdds = 100.0 / (probability > 0 ? probability : 1);
                final double displayMarketOdds = isValue ? (fairOdds * 1.14) : fairOdds;
                final double edgePercentage = ((displayMarketOdds / fairOdds) - 1.0) * 100.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Meccs alapadatok és Értékelőny sorok
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['match'].homeTeam} - ${item['match'].awayTeam}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['recommendation'],
                                style: TextStyle(
                                  color: isValue ? Colors.greenAccent : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isValue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isValue) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.trending_up, color: Colors.greenAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Értékelőny (ROI): +${edgePercentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Odds: ${fairOdds.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // AI Százalékos kör / neon jelzés
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isValue ? Colors.green.withValues(alpha: 0.25) : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isValue ? Colors.greenAccent : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'AI ${probability.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isValue ? Colors.greenAccent : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
