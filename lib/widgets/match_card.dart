// ===========================================
// Zsolt Pro AI
// Version: v0.16.2 - Linter Fix & Compact Typography
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

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isLive ? Colors.redAccent : Colors.transparent,
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
                // 1. IDŐPONT / ÉLŐ STÁTUSZ
                _buildTimeOrStatus(colors),

                const SizedBox(width: 8),

                // Elválasztó vonal
                Container(
                  width: 1,
                  height: 30,
                  color: colors.outlineVariant.withValues(alpha: 0.25),
                ),

                const SizedBox(width: 8),

                // 2. CSAPATOK ÉS LOGÓK
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTeamRow(
                        teamName: widget.match.homeTeam,
                        logoUrl: widget.match.homeTeamLogoUrl,
                        colors: colors,
                      ),
                      const SizedBox(height: 3),
                      _buildTeamRow(
                        teamName: widget.match.awayTeam,
                        logoUrl: widget.match.awayTeamLogoUrl,
                        colors: colors,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // 3. AI JELVÉNY & CSILLAG
                _buildRightActions(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kisméretű időpont / Élő státusz
  Widget _buildTimeOrStatus(ColorScheme colors) {
    final bool isLive = widget.match.isLive;

    return SizedBox(
      width: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLive) ...[
            const Icon(
              Icons.circle,
              size: 6,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 1),
            const Text(
              'ÉLŐ',
              style: TextStyle(
                color: Colors.redAccent,
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

  /// Csapat sora (Kicsi 16x16 logo + 12.5px finom betűk)
  Widget _buildTeamRow({
    required String teamName,
    required String logoUrl,
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
      ],
    );
  }

  /// Mini AI kapszula + csillag
  Widget _buildRightActions(ColorScheme colors) {
    final Color aiColor = _getAiScoreColor(widget.match.aiScore);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
