// ===========================================
// Zsolt Pro AI
// Version: v0.13.6
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../screens/match_detail_screen.dart';
import '../services/favorites_service.dart';
import '../services/sportmonks_service.dart';
import '../widgets/day_selector.dart';
import '../widgets/filter_bar.dart';
import '../widgets/league_header.dart';
import '../widgets/match_card.dart';
import '../widgets/search_bar_widget.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() {
    return _MatchesScreenState();
  }
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final SportMonksService _sportMonksService =
      SportMonksService.instance;

  int _selectedDayIndex = 0;

  String _searchText = '';

  bool _favoritesOnly = false;
  bool _isLoading = false;
  bool _isSearchingNextDate = false;

  String? _errorMessage;
  String? _informationMessage;

  DateTime? _displayedDate;
  DateTime? _nextAvailableDate;

  List<AppMatch> _loadedMatches = <AppMatch>[];

  DateTime get _requestedDate {
    final DateTime now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day + _selectedDayIndex,
    );
  }

  DateTime get _activeDate {
    return _displayedDate ?? _requestedDate;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _loadMatches();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  List<AppMatch> get _filteredMatches {
    final String normalizedSearch =
        _searchText.trim().toLowerCase();

    final List<AppMatch> result =
        _loadedMatches.where(
      (AppMatch match) {
        final bool searchOk =
            normalizedSearch.isEmpty ||
                match.homeTeam
                    .toLowerCase()
                    .contains(normalizedSearch) ||
                match.awayTeam
                    .toLowerCase()
                    .contains(normalizedSearch) ||
                match.league
                    .toLowerCase()
                    .contains(normalizedSearch);

        final bool favoriteOk =
            !_favoritesOnly ||
                FavoritesService.isFavorite(
                  match.id,
                );

        return searchOk && favoriteOk;
      },
    ).toList();

    result.sort(
      (
        AppMatch first,
        AppMatch second,
      ) {
        final int dateComparison =
            first.matchDate.compareTo(
          second.matchDate,
        );

        if (dateComparison != 0) {
          return dateComparison;
        }

        return first.matchTime.compareTo(
          second.matchTime,
        );
      },
    );

    return result;
  }

  Map<String, List<AppMatch>> _groupMatchesByLeague(
    List<AppMatch> matches,
  ) {
    final Map<String, List<AppMatch>> grouped =
        <String, List<AppMatch>>{};

    for (final AppMatch match in matches) {
      final String leagueName =
          match.league.trim().isEmpty
              ? 'Ismeretlen bajnokság'
              : match.league.trim();

      grouped.putIfAbsent(
        leagueName,
        () => <AppMatch>[],
      );

      grouped[leagueName]!.add(match);
    }

    final List<MapEntry<String, List<AppMatch>>>
        entries = grouped.entries.toList()
          ..sort(
            (
              MapEntry<String, List<AppMatch>> first,
              MapEntry<String, List<AppMatch>> second,
            ) {
              return first.key
                  .toLowerCase()
                  .compareTo(
                    second.key.toLowerCase(),
                  );
            },
          );

    return <String, List<AppMatch>>{
      for (final MapEntry<String, List<AppMatch>>
          entry in entries)
        entry.key: entry.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<AppMatch> matches =
        _filteredMatches;

    final Map<String, List<AppMatch>> grouped =
        _groupMatchesByLeague(matches);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚽ Meccsek',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Meccsek frissítése',
            onPressed:
                _isLoading ? null : _loadMatches,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              onChanged: (
                String value,
              ) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
            DaySelector(
              selectedIndex: _selectedDayIndex,
              onChanged: (
                int index,
              ) {
                if (_selectedDayIndex == index) {
                  return;
                }

                setState(() {
                  _selectedDayIndex = index;
                  _displayedDate = null;
                  _nextAvailableDate = null;
                  _loadedMatches = <AppMatch>[];
                  _errorMessage = null;
                  _informationMessage = null;
                });

                _loadMatches();
              },
            ),
            FilterBar(
              favoritesOnly: _favoritesOnly,
              onChanged: (
                bool value,
              ) {
                setState(() {
                  _favoritesOnly = value;
                });
              },
            ),
            _buildDataStatusBar(
              context: context,
            ),
            if (_informationMessage != null)
              _buildInformationBanner(
                context: context,
              ),
            Expanded(
              child: _buildContent(
                context: context,
                grouped: grouped,
                matches: matches,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatusBar({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    if (_isLoading) {
      return const LinearProgressIndicator(
        minHeight: 3,
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(
          alpha: 0.22,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _errorMessage == null
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            size: 19,
            color: _errorMessage == null
                ? Colors.greenAccent
                : Colors.orangeAccent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorMessage == null
                  ? 'SportMonks • '
                      '${_formatDate(_activeDate)} • '
                      '${_loadedMatches.length} mérkőzés'
                  : 'A SportMonks-adatok betöltése '
                      'nem sikerült.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationBanner({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        6,
        16,
        4,
      ),
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

  Widget _buildContent({
    required BuildContext context,
    required Map<String, List<AppMatch>> grouped,
    required List<AppMatch> matches,
  }) {
    if (_isLoading && _loadedMatches.isEmpty) {
      return _buildLoadingState(
        context: context,
      );
    }

    if (_errorMessage != null &&
        _loadedMatches.isEmpty) {
      return _buildErrorState(
        context: context,
      );
    }

    if (matches.isEmpty) {
      return _buildEmptyState(
        context: context,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          28,
        ),
        children: grouped.entries.map(
          (
            MapEntry<String, List<AppMatch>>
                entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  LeagueHeader(
                    leagueName: entry.key,
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map(
                    (AppMatch match) {
                      return MatchCard(
                        match: match,
                        onTap: () {
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
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildLoadingState({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              _isSearchingNextDate
                  ? 'Következő mérkőzésnap keresése...'
                  : 'Valódi mérkőzések betöltése...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearchingNextDate
                  ? 'A SportMonks következő 30 napját '
                      'ellenőrizzük.'
                  : 'A SportMonks API adatait kérjük le.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          const Icon(
            Icons.cloud_off_outlined,
            size: 72,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 18),
          const Text(
            'A meccsek betöltése nem sikerült',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ??
                'Ismeretlen SportMonks hiba.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _isLoading
                ? null
                : _loadMatches,
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
      ),
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool filterActive =
        _searchText.trim().isNotEmpty ||
            _favoritesOnly;

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 55),
          Icon(
            filterActive
                ? Icons.filter_alt_off_outlined
                : Icons.event_busy_outlined,
            size: 72,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 18),
          Text(
            filterActive
                ? 'Nincs találat a szűrésre'
                : 'Ezen a napon nincs elérhető mérkőzés',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            filterActive
                ? 'Módosítsd a keresést vagy '
                    'kapcsold ki a kedvencek szűrését.'
                : _nextAvailableDate != null
                    ? 'A következő elérhető '
                        'mérkőzésnap: '
                        '${_formatDate(_nextAvailableDate!)}'
                    : 'A SportMonks csomagodban a '
                        'következő 30 napban sem találtunk '
                        'elérhető mérkőzést.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (!filterActive &&
              _nextAvailableDate != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  _openNextAvailableDate,
              icon: const Icon(
                Icons.event_available_outlined,
              ),
              label: Text(
                'Meccsek megnyitása – '
                '${_formatDate(_nextAvailableDate!)}',
              ),
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(52),
              ),
            ),
          ],
          if (!filterActive &&
              _nextAvailableDate == null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed:
                  _isLoading ? null : _runDiagnostic,
              icon: const Icon(
                Icons.troubleshoot,
              ),
              label: const Text(
                'SportMonks diagnosztika',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(52),
              ),
            ),
          ],
          if (filterActive) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(
                Icons.filter_alt_off,
              ),
              label: const Text(
                'Szűrők törlése',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadMatches() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearchingNextDate = false;
      _errorMessage = null;
      _informationMessage = null;
      _nextAvailableDate = null;
      _displayedDate = _requestedDate;
    });

    try {
      final List<SportMonksFixture> fixtures =
          await _sportMonksService
              .fetchFixturesByDate(
        _requestedDate,
      );

      final List<AppMatch> matches =
          _convertFixtures(fixtures);

      if (!mounted) {
        return;
      }

      if (matches.isNotEmpty) {
        setState(() {
          _loadedMatches = matches;
          _displayedDate = _requestedDate;
        });

        return;
      }

      setState(() {
        _isSearchingNextDate = true;
      });

      final SportMonksAvailabilityResult
          availability =
          await _sportMonksService
              .findNextAvailableFixtures(
        startDate: _requestedDate.add(
          const Duration(days: 1),
        ),
        daysToCheck: 30,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadedMatches = <AppMatch>[];
        _nextAvailableDate =
            availability.date;

        if (availability.hasFixtures) {
          _informationMessage =
              'A kiválasztott napon nincs meccs. '
              'A következő elérhető mérkőzésnap '
              '${_formatDate(availability.date!)}.';
        } else {
          _informationMessage =
              'A kapcsolat működik, de a SportMonks '
              'csomagodban a következő 30 napra sem '
              'érhető el mérkőzés.';
        }
      });
    } on SportMonksException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadedMatches = <AppMatch>[];
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadedMatches = <AppMatch>[];
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

  Future<void> _openNextAvailableDate() async {
    final DateTime? date =
        _nextAvailableDate;

    if (date == null || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearchingNextDate = false;
      _errorMessage = null;
      _informationMessage = null;
    });

    try {
      final List<SportMonksFixture> fixtures =
          await _sportMonksService
              .fetchFixturesByDate(
        date,
      );

      final List<AppMatch> matches =
          _convertFixtures(fixtures);

      if (!mounted) {
        return;
      }

      setState(() {
        _loadedMatches = matches;
        _displayedDate = date;
        _nextAvailableDate = null;
        _informationMessage =
            'A következő elérhető mérkőzésnap '
            'meccsei láthatók.';
      });
    } on SportMonksException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'A mérkőzésnap megnyitása nem '
            'sikerült: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runDiagnostic() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearchingNextDate = true;
      _errorMessage = null;
      _informationMessage = null;
    });

    try {
      final SportMonksDiagnosticResult result =
          await _sportMonksService.runDiagnostic(
        daysToCheck: 30,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _nextAvailableDate =
            result.firstAvailableDate;

        if (result.hasFixtures) {
          _informationMessage =
              'Diagnosztika: ${result.leagueCount} '
              'elérhető liga. Az első mérkőzésnap '
              '${_formatDate(result.firstAvailableDate!)} '
              '(${result.fixtureCount} meccs).';
        } else {
          _informationMessage =
              'Diagnosztika: ${result.leagueCount} '
              'elérhető liga, de a következő '
              '${result.checkedDays} napban nincs '
              'meccs a csomagodban.';
        }
      });
    } on SportMonksException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'A SportMonks diagnosztika nem '
            'sikerült: $error';
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
      league: fixture.leagueName.trim().isEmpty
          ? 'Ismeretlen bajnokság'
          : fixture.leagueName.trim(),
      homeTeam: fixture.homeTeam.trim(),
      awayTeam: fixture.awayTeam.trim(),
      matchDate: DateTime(
        localStart.year,
        localStart.month,
        localStart.day,
      ),
      matchTime: fixture.matchTime,
      aiScore: _createTemporaryAiScore(
        fixture,
      ),
      isFavorite:
          FavoritesService.isFavorite(
        fixture.id.toString(),
      ),
      isLive: fixture.isLive,
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

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchText = '';
      _favoritesOnly = false;
    });
  }
}
