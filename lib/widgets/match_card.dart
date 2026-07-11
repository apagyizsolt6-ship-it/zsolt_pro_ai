// ===========================================
// Zsolt Pro AI
// Version: v0.13.7
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
  State<MatchCard> createState() {
    return _MatchCardState();
  }
}

class _MatchCardState extends State<MatchCard> {
  bool get _isFavorite {
    return FavoritesService.isFavorite(
      widget.match.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            10,
            12,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildLeagueHeader(
                context: context,
                colors: colors,
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamDisplay(
                      teamName:
                          widget.match.homeTeam,
                      logoUrl: widget
                          .match.homeTeamLogoUrl,
                      fallbackIcon:
                          Icons.shield,
                    ),
                  ),
                  const SizedBox(width: 10),

                  _buildMatchCenter(
                    context: context,
                    colors: colors,
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: _TeamDisplay(
                      teamName:
                          widget.match.awayTeam,
                      logoUrl: widget
                          .match.awayTeamLogoUrl,
                      fallbackIcon:
                          Icons.shield_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Divider(
                height: 1,
                color: colors.outlineVariant,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildDateInformation(
                    context: context,
                    colors: colors,
                  ),
                  const Spacer(),
                  _buildAiBadge(
                    colors: colors,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: _isFavorite
                        ? 'Eltávolítás a kedvencekből'
                        : 'Hozzáadás a kedvencekhez',
                    visualDensity:
                        VisualDensity.compact,
                    icon: Icon(
                      _isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueHeader({
    required BuildContext context,
    required ColorScheme colors,
  }) {
    return Row(
      children: [
        _LeagueLogo(
          logoUrl: widget.match.leagueLogoUrl,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            widget.match.league.trim().isEmpty
                ? 'Ismeretlen bajnokság'
                : widget.match.league,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.match.isLive) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.redAccent.withValues(
                  alpha: 0.70,
                ),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 5),
                Text(
                  'ÉLŐ',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMatchCenter({
    required BuildContext context,
    required ColorScheme colors,
  }) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: widget.match.isLive
                  ? Colors.red.withValues(
                      alpha: 0.13,
                    )
                  : colors.primaryContainer.withValues(
                      alpha: 0.55,
                    ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              widget.match.matchTime.trim().isEmpty
                  ? '--:--'
                  : widget.match.matchTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.match.isLive
                    ? Colors.redAccent
                    : colors.onPrimaryContainer,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'VS',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInformation({
    required BuildContext context,
    required ColorScheme colors,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _formatMatchDate(
                widget.match.matchDate,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBadge({
    required ColorScheme colors,
  }) {
    final Color aiColor =
        _getAiScoreColor(
      widget.match.aiScore,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: aiColor.withValues(
          alpha: 0.14,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: aiColor.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: aiColor,
          ),
          const SizedBox(width: 5),
          Text(
            'AI ${widget.match.aiScore}%',
            style: TextStyle(
              color: aiColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAiScoreColor(
    int score,
  ) {
    if (score >= 85) {
      return Colors.greenAccent;
    }

    if (score >= 70) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  String _formatMatchDate(
    DateTime date,
  ) {
    final String year =
        date.year.toString();

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    return '$year.$month.$day.';
  }

  void _toggleFavorite() {
    FavoritesService.toggleFavorite(
      widget.match.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }
}

class _TeamDisplay extends StatelessWidget {
  final String teamName;
  final String logoUrl;
  final IconData fallbackIcon;

  const _TeamDisplay({
    required this.teamName,
    required this.logoUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Column(
      children: [
        _TeamLogo(
          logoUrl: logoUrl,
          fallbackIcon: fallbackIcon,
        ),
        const SizedBox(height: 9),
        Text(
          teamName.trim().isEmpty
              ? 'Ismeretlen csapat'
              : teamName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String logoUrl;
  final IconData fallbackIcon;

  const _TeamLogo({
    required this.logoUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final String cleanUrl =
        logoUrl.trim();

    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: cleanUrl.isEmpty
          ? _buildFallbackIcon(
              colors: colors,
            )
          : Image.network(
              cleanUrl,
              fit: BoxFit.contain,
              filterQuality:
                  FilterQuality.medium,
              loadingBuilder: (
                BuildContext context,
                Widget child,
                ImageChunkEvent?
                    loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                final int? expectedBytes =
                    loadingProgress
                        .expectedTotalBytes;

                final double? progress =
                    expectedBytes == null
                        ? null
                        : loadingProgress
                                .cumulativeBytesLoaded /
                            expectedBytes;

                return Center(
                  child: SizedBox(
                    width: 23,
                    height: 23,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.2,
                      value: progress,
                    ),
                  ),
                );
              },
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return _buildFallbackIcon(
                  colors: colors,
                );
              },
            ),
    );
  }

  Widget _buildFallbackIcon({
    required ColorScheme colors,
  }) {
    return Icon(
      fallbackIcon,
      size: 34,
      color: colors.primary,
    );
  }
}

class _LeagueLogo extends StatelessWidget {
  final String logoUrl;

  const _LeagueLogo({
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final String cleanUrl =
        logoUrl.trim();

    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: cleanUrl.isEmpty
          ? Icon(
              Icons.emoji_events_outlined,
              size: 19,
              color: colors.onPrimaryContainer,
            )
          : Image.network(
              cleanUrl,
              fit: BoxFit.contain,
              filterQuality:
                  FilterQuality.medium,
              loadingBuilder: (
                BuildContext context,
                Widget child,
                ImageChunkEvent?
                    loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                return Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 1.7,
                      value: loadingProgress
                                  .expectedTotalBytes ==
                              null
                          ? null
                          : loadingProgress
                                  .cumulativeBytesLoaded /
                              loadingProgress
                                  .expectedTotalBytes!,
                    ),
                  ),
                );
              },
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return Icon(
                  Icons.emoji_events_outlined,
                  size: 19,
                  color:
                      colors.onPrimaryContainer,
                );
              },
            ),
    );
  }
}
