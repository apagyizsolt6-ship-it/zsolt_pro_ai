// ===========================================
// Zsolt Pro AI
// Version: v0.14.6
// File: lib/screens/ai_top5_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../services/match_repository.dart';
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
  final MatchRepository _matchRepository =
      MatchRepository.instance;

  bool _isLoading = false;

  String? _errorMessage;
  String? _informationMessage;
  String? _warningMessage;

  DateTime? _loadedDate;

  MatchRepositoryResult? _repositoryResult;

  List<AppMatch> _topMatches = <AppMatch>[];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _loadTopMatches();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Top 5',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Top 5 frissítése',
            onPressed:
                _isLoading ? null : _loadTopMatches,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTopMatches,
          child: _buildContent(
            context,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
  ) {
    if (_isLoading &&
        _topMatches.isEmpty) {
      return _buildLoadingState(
        context,
      );
    }

    if (_errorMessage != null &&
        _topMatches.isEmpty) {
      return _buildErrorState(
        context,
      );
    }

    if (_topMatches.isEmpty) {
      return _buildEmptyState(
        context,
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        28,
      ),
      children: [
        _buildHeaderCard(
          context,
        ),

        if (_warningMessage != null) ...[
          const SizedBox(height: 14),
          _buildWarningBanner(
            context,
          ),
        ],

        if (_informationMessage != null) ...[
          const SizedBox(height: 14),
          _buildInformationBanner(
            context,
          ),
        ],

        const SizedBox(height: 20),

        ...List<Widget>.generate(
          _topMatches.length,
          (
            int index,
          ) {
            final AppMatch match =
                _topMatches[index];

            return _TopMatchCard(
              position: index + 1,
              match: match,
              recommendation:
                  _recommendation(
                match.aiScore,
              ),
              confidenceText:
                  _confidenceText(
                match.aiScore,
              ),
              onTap: () {
                _openMatchDetails(
                  context,
                  match,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final String sourceLabel =
        _repositoryResult?.sourceLabel ??
            'SportMonks + TheSportsDB';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            colors.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(
                alpha: 0.16,
              ),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.psychology,
              color: colors.onPrimary,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Az 5 legerősebb AI tipp',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _loadedDate == null
                      ? sourceLabel
                      : '${_formatDate(_loadedDate!)} • '
                          '${_topMatches.length} kiválasztott meccs',
                  style: TextStyle(
                    color: colors.onPrimary
                        .withValues(
                      alpha: 0.88,
                    ),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sourceLabel • ideiglenes AI-pontszám',
                  style: TextStyle(
                    color: colors.onPrimary
                        .withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orangeAccent.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _warningMessage!,
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationBanner(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.primaryContainer
            .withValues(
          alpha: 0.24,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colors.primary,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _informationMessage!,
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 110),
        const Center(
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 20),
        const Text(
          'AI Top 5 betöltése...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'A SportMonks és a TheSportsDB '
          'mérkőzéseit egyesítjük, majd '
          'kiválasztjuk a legmagasabb '
          'AI-pontszámú meccseket.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 85),
        const Icon(
          Icons.cloud_off_outlined,
          size: 76,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 18),
        const Text(
          'Az AI Top 5 betöltése nem sikerült',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ??
              'Ismeretlen adatforrás-hiba történt.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed:
              _isLoading ? null : _loadTopMatches,
          icon: const Icon(
            Icons.refresh,
          ),
          label: const Text(
            'Újrapróbálás',
          ),
          style: FilledButton.styleFrom(
            minimumSize:
                const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 85),
        Icon(
          Icons.event_busy_outlined,
          size: 76,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(height: 18),
        const Text(
          'Nincs elérhető mérkőzés',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A SportMonks és a TheSportsDB '
          'a következő 30 napra sem talált '
          'megjeleníthető mérkőzést.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed:
              _isLoading ? null : _loadTopMatches,
          icon: const Icon(
            Icons.refresh,
          ),
          label: const Text(
            'Újraellenőrzés',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize:
                const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }

  Future<void> _loadTopMatches() async {
    if (_isLoading) {
      return;
    }

    final DateTime now = DateTime.now();

    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _informationMessage = null;
      _warningMessage = null;
      _repositoryResult = null;
    });

    try {
      final MatchTopResult result =
          await _matchRepository.fetchTopMatches(
        startDate: today,
        limit: 5,
        daysToCheck: 30,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _topMatches =
            List<AppMatch>.from(
          result.matches,
        );

        _loadedDate =
            result.date;

        _repositoryResult =
            result.repositoryResult;

        _warningMessage =
            result.repositoryResult
                ?.warningMessage;

        if (result.hasMatches &&
            result.date != null) {
          if (_isSameDay(
            result.date!,
            today,
          )) {
            _informationMessage =
                _buildSourceInformation(
              result.repositoryResult,
            );
          } else {
            _informationMessage =
                'Ma nincs elérhető mérkőzés. '
                'A következő elérhető nap '
                'Top tippjei láthatók: '
                '${_formatDate(result.date!)} '
                '(${result.checkedDays} nap ellenőrizve). '
                '${_buildSourceInformation(result.repositoryResult)}';
          }
        }
      });
    } on MatchRepositoryException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _topMatches = <AppMatch>[];
        _loadedDate = null;
        _repositoryResult = null;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _topMatches = <AppMatch>[];
        _loadedDate = null;
        _repositoryResult = null;
        _errorMessage =
            'Váratlan hiba történt. '
            'Típus: ${error.runtimeType}. '
            'Részlet: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildSourceInformation(
    MatchRepositoryResult? result,
  ) {
    if (result == null) {
      return '';
    }

    if (result.usedBothSources) {
      return 'SportMonks: '
          '${result.sportMonksCount} • '
          'TheSportsDB: '
          '${result.theSportsDbCount} • '
          'egyesített lista: '
          '${result.totalCount}.';
    }

    if (result.usedSportMonks) {
      return 'SportMonks adatforrás: '
          '${result.sportMonksCount} mérkőzés.';
    }

    if (result.usedTheSportsDb) {
      return 'TheSportsDB adatforrás: '
          '${result.theSportsDbCount} mérkőzés.';
    }

    return '';
  }

  void _openMatchDetails(
    BuildContext context,
    AppMatch match,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (
          BuildContext context,
        ) {
          return MatchDetailScreen(
            match: match,
          );
        },
      ),
    );
  }

  String _recommendation(
    int aiScore,
  ) {
    if (aiScore >= 93) {
      return '1X és több mint 1,5 gól';
    }

    if (aiScore >= 90) {
      return 'Több mint 2,5 gól';
    }

    if (aiScore >= 87) {
      return 'Mindkét csapat szerez gólt';
    }

    if (aiScore >= 84) {
      return 'Hazai csapat nem kap ki';
    }

    if (aiScore >= 78) {
      return 'Kevesebb mint 4,5 gól';
    }

    return 'Kevesebb mint 5,5 gól';
  }

  String _confidenceText(
    int aiScore,
  ) {
    if (aiScore >= 93) {
      return 'Kiemelt AI tipp';
    }

    if (aiScore >= 90) {
      return 'Nagyon erős tipp';
    }

    if (aiScore >= 87) {
      return 'Erős tipp';
    }

    if (aiScore >= 84) {
      return 'Jó tipp';
    }

    if (aiScore >= 75) {
      return 'Közepes tipp';
    }

    return 'Óvatos tipp';
  }

  String _formatDate(
    DateTime date,
  ) {
    final String year =
        date.year.toString();

    final String month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year.$month.$day.';
  }

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _TopMatchCard extends StatelessWidget {
  final int position;
  final AppMatch match;
  final String recommendation;
  final String confidenceText;
  final VoidCallback onTap;

  const _TopMatchCard({
    required this.position,
    required this.match,
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
    if (match.aiScore >= 85) {
      return Colors.greenAccent;
    }

    if (match.aiScore >= 70) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final double progress =
        match.aiScore.clamp(
              0,
              100,
            ) /
            100;

    final Color aiColor =
        _aiColor();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        _positionColor(),
                    child: Text(
                      '$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  _SmallNetworkLogo(
                    imageUrl:
                        match.leagueLogoUrl,
                    fallbackIcon:
                        Icons.emoji_events_outlined,
                    size: 34,
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      match.league,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: aiColor.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${match.aiScore}%',
                      style: TextStyle(
                        color: aiColor,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  Expanded(
                    child: _TopTeamDisplay(
                      teamName:
                          match.homeTeam,
                      logoUrl:
                          match.homeTeamLogoUrl,
                      fallbackIcon:
                          Icons.shield,
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    child: Column(
                      children: [
                        Text(
                          match.matchTime
                                  .trim()
                                  .isEmpty
                              ? '--:--'
                              : match.matchTime,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'VS',
                          style: TextStyle(
                            color: colors
                                .onSurfaceVariant,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _TopTeamDisplay(
                      teamName:
                          match.awayTeam,
                      logoUrl:
                          match.awayTeamLogoUrl,
                      fallbackIcon:
                          Icons.shield_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  color: aiColor,
                  backgroundColor:
                      colors.surfaceContainerHighest,
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: aiColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      confidenceText,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer
                      .withValues(
                    alpha: 0.25,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Text(
                  'Ajánlott tipp: $recommendation',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 11),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color:
                        colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatCardDate(
                      match.matchDate,
                    ),
                    style: TextStyle(
                      color:
                          colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color:
                        colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCardDate(
    DateTime date,
  ) {
    final String year =
        date.year.toString();

    final String month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year.$month.$day.';
  }
}

class _TopTeamDisplay extends StatelessWidget {
  final String teamName;
  final String logoUrl;
  final IconData fallbackIcon;

  const _TopTeamDisplay({
    required this.teamName,
    required this.logoUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SmallNetworkLogo(
          imageUrl: logoUrl,
          fallbackIcon: fallbackIcon,
          size: 58,
        ),
        const SizedBox(height: 8),
        Text(
          teamName.trim().isEmpty
              ? 'Ismeretlen csapat'
              : teamName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _SmallNetworkLogo extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final double size;

  const _SmallNetworkLogo({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final String cleanUrl =
        imageUrl.trim();

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(
        size >= 50 ? 7 : 5,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          size >= 50 ? 17 : 10,
        ),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: cleanUrl.isEmpty
          ? Icon(
              fallbackIcon,
              color: colors.primary,
              size: size * 0.58,
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

                final int? totalBytes =
                    loadingProgress
                        .expectedTotalBytes;

                final double? progress =
                    totalBytes == null
                        ? null
                        : loadingProgress
                                .cumulativeBytesLoaded /
                            totalBytes;

                return Center(
                  child: SizedBox(
                    width: size * 0.35,
                    height: size * 0.35,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
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
                return Icon(
                  fallbackIcon,
                  color: colors.primary,
                  size: size * 0.58,
                );
              },
            ),
    );
  }
}
