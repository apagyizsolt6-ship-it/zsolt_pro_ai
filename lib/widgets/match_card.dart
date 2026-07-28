// ===========================================
// Zsolt Pro AI
// Version: v0.17.0 - Livescore & Result Evaluation
// File: lib/widgets/match_card.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../services/favorites_service.dart';

class MatchCard extends StatefulWidget {
  final AppMatch match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  bool get _isFavorite {
    return FavoritesService.isFavorite(widget.match.id);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isLive = widget.match.isLive;
    final bool isFinished = widget.match.isFinished;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isLive
                ? Colors.redAccent
                : isFinished
                    ? Colors.blueGrey
                    : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // 1. IDŐPONT / JÁTÉKPERC / FT STÁTUSZ
                _buildTimeOrStatus(colors),

                const SizedBox(width: 8),

                // Elválasztó vonal
                Container(
                  width: 1,
                  height: 32,
                  color: colors.outlineVariant.withValues(alpha: 0.25),
                ),

                const SizedBox(width: 8),

                // 2. CSAPATOK ÉS EREDMÉNYEK
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTeamRow(
                        teamName: widget.match.homeTeam,
                        logoUrl: widget.match.homeTeamLogoUrl,
                        score: (isLive || isFinished) ? widget.match.homeScore : null,
                        colors: colors,
                      ),
                      const SizedBox(height: 3),
                      _buildTeamRow(
                        teamName: widget.match.awayTeam,
                        logoUrl: widget.match.awayTeamLogoUrl,
                        score: (isLive || isFinished) ? widget.match.awayScore : null,
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // 3. AI JELVÉNY / KIÉRTÉKELÉS (✅ NYERT) & CSILLAG
                _buildRightActions(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Időpont / Játékperc / Vége státusz
  Widget _buildTimeOrStatus(ColorScheme colors) {
    final bool isLive = widget.match.isLive;
    final bool isFinished = widget.match.isFinished;

    return SizedBox(
      width: 45,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  _formatLiveMinute(widget.match.minute),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else if (isFinished) ...[
            Text(
              'VÉGE',
              style: TextStyle(
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Text(
              widget.match.matchTime.trim().isEmpty
                  ? '--:--'
                  : widget.match.matchTime,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Státusz kódok átalakítása percekre
  String _formatLiveMinute(String rawMinute) {
    final String clean = rawMinute.trim().toUpperCase();

    // Ha félidő van, jelöljük szünetként vagy 45. perc környékeként
    if (clean == 'HT') return '45\'';
    if (clean == '1H') return '1.f';
    if (clean == '2H') return '90\''; // vagy ha nincs pontos perc, átmeneti jelölés
    if (clean == 'ET') return 'Hossz.';
    if (clean == 'PEN') return 'Tizi';

    if (clean.isEmpty) return 'ÉLŐ';

    // Ha már szám vagy pl. "45+2", tegyük rá a perc jelet
    return clean.endsWith('\'') ? clean : '$clean\'';
  }

  /// Csapat sora + Élő/Végső gólok száma
  Widget _buildTeamRow({
    required String teamName,
    required String logoUrl,
    required int? score,
    required ColorScheme colors,
  }) {
    final String cleanLogo = logoUrl.trim();

    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: cleanLogo.isEmpty
              ? Icon(Icons.shield_outlined, size: 14, color: colors.primary)
              : Image.network(
                  cleanLogo,
                  fit: BoxFit.contain,
                  errorBuilder: (BuildContext ctx, Object err, StackTrace? stack) => Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: colors.primary,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            teamName.trim().isEmpty ? 'Ismeretlen csapat' : teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
        if (score != null) ...[
          const SizedBox(width: 6),
          Text(
            '$score',
            style: TextStyle(
              color: widget.match.isLive ? Colors.redAccent : colors.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  /// Mini AI kapszula + ✅ NYERT Kiértékelés + Csillag
  Widget _buildRightActions(ColorScheme colors) {
    final Color aiColor = _getAiScoreColor(widget.match.aiScore);
    final bool isWon = widget.match.isFinished && _evaluateAiRecommendation();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWon) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 11, color: Colors.greenAccent),
                SizedBox(width: 2),
                Text(
                  'NYERT',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: aiColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: aiColor.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            '${widget.match.aiScore}%',
            style: TextStyle(
              color: aiColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          icon: Icon(
            _isFavorite ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 18,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  bool _evaluateAiRecommendation() {
    final int totalGoals = widget.match.homeScore + widget.match.awayScore;
    final int score = widget.match.aiScore;

    if (score >= 90 && totalGoals > 2) return true;
    if (score >= 87 && widget.match.homeScore > 0 && widget.match.awayScore > 0) return true;
    if (score >= 78 && totalGoals < 5) return true;
    if (score < 78 && totalGoals < 6) return true;

    return false;
  }

  Color _getAiScoreColor(int score) {
    if (score >= 85) return Colors.greenAccent;
    if (score >= 70) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _toggleFavorite() {
    FavoritesService.toggleFavorite(widget.match.id);
    if (mounted) {
      setState(() {});
    }
  }
}
