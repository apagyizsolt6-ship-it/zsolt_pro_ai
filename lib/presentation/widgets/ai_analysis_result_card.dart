// ===========================================
// Zsolt Pro AI
// Version: v0.23.0
// File: lib/presentation/widgets/ai_analysis_result_card.dart
// ===========================================

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
            // Összesített AI Statisztikai Kártya
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
            
            // Meccsek listázása a valós esélyekkel
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: analyzedMatches.length,
              itemBuilder: (context, index) {
                final item = analyzedMatches[index];
                final bool isValue = item['isValueBet'] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Meccs alapadatok
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['match'].homeTeam} - ${item['match'].awayTeam}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['recommendation'],
                                style: TextStyle(
                                  color: isValue ? Colors.greenAccent : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isValue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // AI Százalékos kör / jelzés
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isValue ? Colors.green.withValues(alpha: 0.25) : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isValue ? Colors.greenAccent : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            'AI ${item['probability']}',
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
