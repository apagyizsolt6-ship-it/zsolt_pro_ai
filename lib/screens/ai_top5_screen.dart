// ===========================================
// Zsolt Pro AI
// Version: v0.14.1
// File: lib/screens/ai_top5_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../services/favorites_service.dart';
import '../services/sportmonks_service.dart';
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
  final SportMonksService _sportMonksService =
      SportMonksService.instance;

  bool _isLoading = false;
  bool _isSearchingNextDate = false;

  String? _errorMessage;
  String? _informationMessage;

  DateTime? _loadedDate;

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
    final ColorScheme colors =
        Theme.of(context).colorScheme;

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
          child: _buildBody(
            context: context,
            colors: colors,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ColorScheme colors,
  }) {
    if (_isLoading && _topMatches.isEmpty) {
      return _buildLoadingState(
        colors: colors,
      );
    }

    if (_errorMessage != null &&
        _topMatches.isEmpty) {
      return _buildErrorState(
        colors: colors,
      );
    }

    if (_topMatches.isEmpty) {
      return _buildEmptyState(
        colors: colors,
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
          colors: colors,
        ),

        if (_informationMessage != null) ...[
          const SizedBox(height: 14),
          _buildInformationBanner(
            colors: colors,
          ),
        ],

        const SizedBox(height: 20),

        ...List<Widget>.generate(
          _topMatches.length,
          (int index) {
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

  Widget _buildHeaderCard({
    required ColorScheme colors,
  }) {
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
        borderRadius: BorderRadius.circular(22),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _loadedDate == null
                      ? 'Valódi SportMonks meccsek'
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
                  'Az AI-pontszám jelenleg ideiglenes számítás.',
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

  Widget _buildInformationBanner({
    required ColorScheme colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
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
            Icons.info_outline,
            color: Colors.orangeAccent,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _informationMessage!,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState({
    required ColorScheme colors,
  }) {
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
        Text(
          _isSearchingNextDate
              ? 'Következő mérkőzésnap keresése...'
              : 'Valódi AI Top 5 betöltése...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _isSearchingNextDate
              ? 'A SportMonks következő 30 napját '
                  'ellenőrizzük.'
              : 'A valódi mérkőzéseket kérjük le '
                  'a SportMonks API-ból.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState({
    required ColorScheme colors,
  }) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 85),
        const Icon(
          Icons.cloud_off_outlined,
          size: 76,
          color: Colors.orangeAccent,
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
              'Ismeretlen SportMonks hiba történt.',
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

  Widget _buildEmptyState({
    required ColorScheme colors,
  }) {
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
          'A SportMonks csomagodban a következő '
          '30 napra sem találtunk megjeleníthető '
          'mérkőzést.',
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
      _isSearchingNextDate = false;
      _errorMessage = null;
      _informationMessage = null;
    });

    try {
      List<SportMonksFixture> fixtures =
          await _sportMonksService
              .fetchFixturesByDate(
        today,
      );

      DateTime selectedDate = today;

      List<AppMatch> matches =
          _convertFixtures(
        fixtures,
      );

      if (matches.isEmpty) {
        if (mounted) {
          setState(() {
            _isSearchingNextDate = true;
          });
        }

        final SportMonksAvailabilityResult
            availability =
            await _sportMonksService
                .findNextAvailableFixtures(
          startDate: today.add(
            const Duration(days: 1),
          ),
          daysToCheck: 30,
        );

        if (availability.hasFixtures &&
            availability.date != null) {
          selectedDate =
              availability.date!;

          fixtures =
              availability.fixtures;

          matches =
              _convertFixtures(
            fixtures,
          );
        }
      }

      matches.sort(
        (
          AppMatch first,
          AppMatch second,
        ) {
          final int aiComparison =
              second.aiScore.compareTo(
            first.aiScore,
          );

          if (aiComparison != 0) {
            return aiComparison;
          }

          return first.matchTime.compareTo(
            second.matchTime,
          );
        },
      );

      final List<AppMatch> topMatches =
          matches.take(5).toList(
                growable: false,
              );

      if (!mounted) {
        return;
      }

      setState(() {
        _topMatches = topMatches;

        _loadedDate = topMatches.isEmpty
            ? null
            : selectedDate;

        if (topMatches.isNotEmpty &&
            !_isSameDay(
              selectedDate,
              today,
            )) {
          _informationMessage =
              'Ma nincs elérhető mérkőzés a '
              'SportMonks csomagodban. A következő '
              'elérhető nap Top tippjei láthatók: '
              '${_formatDate(selectedDate)}';
        }
      });
    } on SportMonksException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _topMatches = <AppMatch>[];
        _loadedDate = null;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _topMatches = <AppMatch>[];
        _loadedDate = null;
        _errorMessage =
            'Váratlan hiba történt. '
            'Típus: ${error.runtimeType}. '
            'Részlet: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearchingNextDate = false;
        });
      }
    }
  }

  List<AppMatch> _convertFixtures(
    List<SportMonksFixture> fixtures,
  ) {
    return fixtures
        .where(
          (
            SportMonksFixture fixture,
          ) {
            return !fixture.placeholder &&
                fixture.homeTeam
                    .trim()
                    .isNotEmpty &&
                fixture.awayTeam
                    .trim()
                    .isNotEmpty;
          },
        )
        .map(
          _fixtureToAppMatch,
        )
        .toList(growable: false);
  }

  AppMatch _fixtureToAppMatch(
    SportMonksFixture fixture,
  ) {
    final DateTime localStart =
        fixture.startingAt.toLocal();

    return AppMatch(
      id: fixture.id.toString(),
      league:
          fixture.leagueName.trim().isEmpty
              ? 'Ismeretlen bajnokság'
              : fixture.leagueName.trim(),
      homeTeam:
          fixture.homeTeam.trim(),
      awayTeam:
          fixture.awayTeam.trim(),
      matchDate: DateTime(
        localStart.year,
        localStart.month,
        localStart.day,
      ),
      matchTime:
          fixture.matchTime,
      aiScore:
          _createTemporaryAiScore(
        fixture,
      ),
      isFavorite:
          FavoritesService.isFavorite(
        fixture.id.toString(),
      ),
      isLive:
          fixture.isLive,
      homeTeamLogoUrl:
          fixture.homeTeamImagePath.trim(),
      awayTeamLogoUrl:
          fixture.awayTeamImagePath.trim(),
      leagueLogoUrl:
          fixture.leagueImagePath.trim(),
    );
  }

  int _createTemporaryAiScore(
    SportMonksFixture fixture,
  ) {
    final int seed =
        fixture.id +
            fixture.homeTeam.length * 3 +
            fixture.awayTeam.length * 5;

    return 65 + seed.abs() % 31;
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

    return 'Kevesebb mint 4,5 gól';
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

    return 'Közepes tipp';
  }

  String _formatDate(
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
            .padLeft(2, '0');

    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

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
          teamName,
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

                return Center(
                  child: SizedBox(
                    width: size * 0.35,
                    height: size * 0.35,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
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
                  fallbackIcon,
                  color: colors.primary,
                  size: size * 0.58,
                );
              },
            ),
    );
  }
}
