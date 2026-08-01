// ============================================================================
// Zsolt Pro AI - Match Detail Screen (Teljes, Univerzális Verzió)
// File: lib/screens/match_detail_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statpal_provider.dart';
import '../models/statpal_models.dart';
import '../utils/league_translator.dart';

class MatchDetailScreen extends StatefulWidget {
  final dynamic match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool _isLoadingPrediction = true;
  StatPrediction? _prediction;

  @override
  void initState() {
    super.initState();
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    try {
      final matchId = widget.match?.id?.toString() ?? '';
      if (matchId.isEmpty) {
        if (mounted) setState(() { _isLoadingPrediction = false; });
        return;
      }
      final provider = Provider.of<StatPalProvider>(context, listen: false);
      await provider.loadPrediction(matchId);
      if (mounted) {
        setState(() {
          _prediction = provider.currentPrediction;
          _isLoadingPrediction = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingPrediction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String rawStatus = '';
    String rawTime = '';
    String homeName = 'Hazai Csapat';
    String awayName = 'Vendég Csapat';
    String homeGoals = '0';
    String awayGoals = '0';

    try {
      if (widget.match != null) {
        rawStatus = widget.match.status?.toString() ?? widget.match.strStatus?.toString() ?? '';
        rawTime = widget.match.time?.toString() ?? widget.match.strTime?.toString() ?? '';
        
        // Univerzális adatszerkezet-kezelés a különböző API modellekhez
        if (widget.match.homeName != null) {
          homeName = widget.match.homeName.toString();
        } else if (widget.match.home?.name != null) {
          homeName = widget.match.home.name.toString();
        } else if (widget.match.strHomeTeam != null) {
          homeName = widget.match.strHomeTeam.toString();
        }

        if (widget.match.awayName != null) {
          awayName = widget.match.awayName.toString();
        } else if (widget.match.away?.name != null) {
          awayName = widget.match.away.name.toString();
        } else if (widget.match.strAwayTeam != null) {
          awayName = widget.match.strAwayTeam.toString();
        }

        homeGoals = widget.match.homeGoals?.toString() ?? widget.match.home?.goals?.toString() ?? widget.match.intHomeScore?.toString() ?? '0';
        awayGoals = widget.match.awayGoals?.toString() ?? widget.match.away?.goals?.toString() ?? widget.match.intAwayScore?.toString() ?? '0';
      }
    } catch (_) {}

    final translatedStatus = LeagueTranslator.translateStatus(rawStatus);
    final correctedTime = LeagueTranslator.formatMatchTime(rawTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meccselemzés', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fő meccs kártya
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('Státusz: $translatedStatus ($correctedTime)', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: Text(homeName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Text('$homeGoals : $awayGoals', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
                        Expanded(child: Text(awayName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Előrejelzés / Elemzés
            if (_isLoadingPrediction)
              const Padding(
                padding: EdgeInsets.all(30.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_prediction != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Zsolt Pro AI Elemzés & Esélyek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 20),
                      if (_prediction!.advice.isNotEmpty) ...[
                        Text('Tipp: ${_prediction!.advice}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 15)),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hazai (1):'),
                          Text('${_prediction!.homePercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Döntetlen (X):'),
                          Text('${_prediction!.drawPercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Vendég (2):'),
                          Text('${_prediction!.awayPercentage}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.amber),
                        SizedBox(height: 12),
                        Text('Ehhez a mérkőzéshez jelenleg nem érhető el részletes AI predikció.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Értékelő / Value Bet kártya
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('Value Bet & Kelly Tőkeajánlás', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Divider(height: 20),
                    Text('Optimális értékelőny és biztonságos tétajánlás az aktuális oddsok alapján.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
