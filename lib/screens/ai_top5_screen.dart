// ===========================================
// Zsolt Pro AI
// Version: v0.25.0 - StatPal PRO AI Top 5 Integration
// File: lib/screens/ai_top5_screen.dart
// ===========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_match.dart';
import '../services/ai_engine_v2_service.dart';
import '../utils/league_translator.dart';
import '../providers/statpal_provider.dart';
import 'statpal_dashboard_screen.dart';
import 'match_detail_screen.dart';

class AITop5Screen extends StatefulWidget {
  const AITop5Screen({
    super.key,
  });

  @override
  State<AITop5Screen> createState() {
    return _AITop5ScreenState();
  }
}

class _AITop5ScreenState extends State<AITop5Screen> {
  final AiEngineV2Service _aiEngine = AiEngineV2Service.instance;

  List<AppMatch> _topMatches = <AppMatch>[];
  final Map<String, AiMatchAnalysis> _analyses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTopMatchesFromProvider();
    });
  }

  void _loadTopMatchesFromProvider() {
    final provider = Provider.of<StatPalProvider>(context, listen: false);
    
    // Lekérjük a providerben már szigorúan szűrt élő/napi meccseket
    final allMatches = provider.liveMatches;

    final Map<String, AiMatchAnalysis> newAnalyses = {};
    for (final match in allMatches) {
      final analysis = _aiEngine.analyzeWithFallbackData(
        match: match,
        diversify: true,
      );
      newAnalyses[match.id] = analysis;
    }

    final sortedMatches = List<AppMatch>.from(allMatches);
    sortedMatches.sort((a, b) {
      final scoreA = newAnalyses[a.id]?.aiScore ?? a.aiScore;
      final scoreB = newAnalyses[b.id]?.aiScore ?? b.aiScore;
      return scoreB.compareTo(scoreA);
    });

    setState(() {
      _topMatches = sortedMatches.take(5).toList(growable: false);
      _analyses.clear();
      _analyses.addAll(newAnalyses);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Top 5 PRO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Top 5 frissítése',
            onPressed: () {
              final provider = Provider.of<StatPalProvider>(context, listen: false);
              provider.loadInitialData().then((_) {
                _loadTopMatchesFromProvider();
              });
            },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<StatPalProvider>(
          builder: (context, provider, child) {
            // Ha közben frissül a provider, frissítjük a top meccseket is
            if (!provider.isLoading && _topMatches.isEmpty && provider.liveMatches.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadTopMatchesFromProvider();
              });
            }

            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadInitialData();
                _loadTopMatchesFromProvider();
              },
              child: _buildContent(
                context,
                provider.isLoading,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isLoading,
  ) {
    if (isLoading && _topMatches.isEmpty) {
      return _buildLoadingState(context);
    }

    if (_topMatches.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _buildHeaderCard(context),
        const SizedBox(height: 16),
        ...List<Widget>.generate(
          _topMatches.length,
          (int index) {
            final AppMatch match = _topMatches[index];
            final AiMatchAnalysis? analysis = _analyses[match.id];
            final int displayScore = analysis?.aiScore ?? match.aiScore;

            final String recommendationText = analysis != null
                ? '${analysis.recommendation.marketName}: ${analysis.recommendation.selection}'
                : 'Elemzés folyamatban...';

            final String confidenceText = _confidenceText(displayScore);

            return _TopMatchCard(
              position: index + 1,
              match: match,
              displayScore: displayScore,
              recommendation: recommendationText,
              confidenceText: confidenceText,
              onTap: () {
                _openMatchDetails(context, match);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            colors.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.psychology,
              color: colors.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Az 5 legerősebb StatPal AI tipp',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kizárólag a szűrt ligák kínálatából',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.88),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'StatPal PRO • AI Engine v2.0 Quant',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 110),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 20),
        const Text(
          'AI Top 5 elemzése...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'A szűrt mérkőzések elemzése folyamatban.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 85),
        Icon(Icons.event_busy_outlined, size: 68, color: colors.onSurfaceVariant),
        const SizedBox(height: 16),
        const Text(
          'Nincs elegendő mérkőzés a szűrt listában',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'A megadott engedélyezett ligákban jelenleg nincsenek mérkőzések.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }

  void _openMatchDetails(BuildContext context, AppMatch match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MatchDetailScreen(match: match);
        },
      ),
    );
  }

  String _confidenceText(int aiScore) {
    if (aiScore >= 90) return 'Kiemelt AI tipp (Quant V2)';
    if (aiScore >= 85) return 'Nagyon erős tipp';
    if (aiScore >= 80) return 'Erős elemzés';
    return 'Jó esélyű tipp';
  }
}

class _TopMatchCard extends StatelessWidget {
  final int position;
  final AppMatch match;
  final int displayScore;
  final String recommendation;
  final String confidenceText;
  final VoidCallback onTap;

  const _TopMatchCard({
    required this.position,
    required this.match,
    required this.displayScore,
    required this.recommendation,
    required this.confidenceText,
    required this.onTap,
  });

  Color _positionColor() {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Color _aiColor() {
    if (displayScore >= 85) return Colors.greenAccent;
    if (displayScore >= 75) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double progress = displayScore.clamp(0, 100) / 100;
    final Color aiColor = _aiColor();
    final String translatedLeague = StatPalHelper.formatLeagueHeader(match.country, match.league);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _positionColor(),
                    child: Text(
                      '$position',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      translatedLeague.isEmpty ? match.league : translatedLeague,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.primary, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: aiColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$displayScore%',
                      style: TextStyle(color: aiColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.homeTeam,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      match.matchTime.trim().isEmpty ? '--:--' : match.matchTime,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.awayTeam,
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.85)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: aiColor,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Ajánlott tipp: $recommendation',
                  style: TextStyle(color: colors.onSurface, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
