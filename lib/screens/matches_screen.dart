// ===========================================
// Zsolt Pro AI
// Version: v0.14.4
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../services/favorites_service.dart';
import '../services/match_repository.dart';
import '../widgets/day_selector.dart';
import '../widgets/filter_bar.dart';
import '../widgets/league_header.dart';
import '../widgets/match_card.dart';
import '../widgets/search_bar_widget.dart';
import 'match_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({
    super.key,
  });

  @override
  State<MatchesScreen> createState() {
    return _MatchesScreenState();
  }
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final MatchRepository _matchRepository =
      MatchRepository.instance;

  int _selectedDayIndex = 0;

  String _searchText = '';

  bool _favoritesOnly = false;
  bool _isLoading = false;
  bool _isSearchingNextDate = false;

  String? _errorMessage;
  String? _informationMessage;
  String? _warningMessage;

  DateTime? _displayedDate;
  DateTime? _nextAvailableDate;

  MatchRepositoryResult? _lastRepositoryResult;

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

  List<AppMatch> get _filteredMatches {
    final String normalizedSearch =
        _searchText.trim().toLowerCase();

    final List<AppMatch> result =
        _loadedMatches.where(
      (AppMatch match) {
        final bool searchMatches =
            normalizedSearch.isEmpty ||
                match.homeTeam
                    .toLowerCase()
                    .contains(
                      normalizedSearch,
                    ) ||
                match.awayTeam
                    .toLowerCase()
                    .contains(
                      normalizedSearch,
                    ) ||
                match.league
                    .toLowerCase()
                    .contains(
                      normalizedSearch,
                    );

        final bool favoriteMatches =
            !_favoritesOnly ||
                FavoritesService.isFavorite(
                  match.id,
                );

        return searchMatches &&
            favoriteMatches;
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

        final int timeComparison =
            first.matchTime.compareTo(
          second.matchTime,
        );

        if (timeComparison != 0) {
          return timeComparison;
        }

        final int leagueComparison =
            first.league
                .toLowerCase()
                .compareTo(
                  second.league
                      .toLowerCase(),
                );

        if (leagueComparison != 0) {
          return leagueComparison;
        }

        return first.homeTeam
            .toLowerCase()
            .compareTo(
              second.homeTeam
                  .toLowerCase(),
            );
      },
    );

    return result;
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

  @override
  Widget build(BuildContext context) {
    final List<AppMatch> matches =
        _filteredMatches;

    final Map<String, List<AppMatch>> groupedMatches =
        _groupMatchesByLeague(
      matches,
    );

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
              selectedIndex:
                  _selectedDayIndex,
              onChanged: (
                int index,
              ) {
                if (_selectedDayIndex == index) {
                  return;
                }

                setState(() {
                  _selectedDayIndex = index;
                  _loadedMatches =
                      <AppMatch>[];
                  _displayedDate = null;
                  _nextAvailableDate = null;
                  _lastRepositoryResult = null;
                  _errorMessage = null;
                  _informationMessage = null;
                  _warningMessage = null;
                });

                _loadMatches();
              },
            ),

            FilterBar(
              favoritesOnly:
                  _favoritesOnly,
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

            if (_warningMessage != null)
              _buildWarningBanner(
                context: context,
              ),

            if (_informationMessage != null)
              _buildInformationBanner(
                context: context,
              ),

            Expanded(
              child: _buildContent(
                context: context,
                groupedMatches:
                    groupedMatches,
                matches: matches,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<AppMatch>>
      _groupMatchesByLeague(
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

      grouped[leagueName]!.add(
        match,
      );
    }

    final List<MapEntry<String, List<AppMatch>>>
        sortedEntries =
        grouped.entries.toList()
          ..sort(
            (
              MapEntry<String, List<AppMatch>>
                  first,
              MapEntry<String, List<AppMatch>>
                  second,
            ) {
              return first.key
                  .toLowerCase()
                  .compareTo(
                    second.key
                        .toLowerCase(),
                  );
            },
          );

    return <String, List<AppMatch>>{
      for (final MapEntry<String, List<AppMatch>>
          entry in sortedEntries)
        entry.key: entry.value,
    };
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

    final MatchRepositoryResult? result =
        _lastRepositoryResult;

    final bool hasError =
        _errorMessage != null;

    final String sourceLabel =
        result?.sourceLabel ??
            'SportMonks + TheSportsDB';

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
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: hasError
            ? Colors.red.withValues(
                alpha: 0.08,
              )
            : colors.primaryContainer
                .withValues(
                alpha: 0.22,
              ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? Colors.redAccent.withValues(
                  alpha: 0.45,
                )
              : colors.primary.withValues(
                  alpha: 0.18,
                ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasError
                ? Icons.cloud_off_outlined
                : Icons.cloud_done_outlined,
            size: 19,
            color: hasError
                ? Colors.redAccent
                : Colors.greenAccent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasError
                  ? 'A mérkőzésadatok betöltése '
                      'nem sikerült.'
                  : '$sourceLabel • '
                      '${_formatDate(_activeDate)} • '
                      '${_loadedMatches.length} mérkőzés',
              style: TextStyle(
                color: hasError
                    ? Colors.redAccent
                    : colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner({
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
        color: colors.primaryContainer
            .withValues(
          alpha: 0.25,
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

  Widget _buildContent({
    required BuildContext context,
    required Map<String, List<AppMatch>>
        groupedMatches,
    required List<AppMatch> matches,
  }) {
    if (_isLoading &&
        _loadedMatches.isEmpty) {
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
        children:
            groupedMatches.entries.map(
          (
            MapEntry<String, List<AppMatch>>
                entry,
          ) {
            return Padding(
              padding:
                  const EdgeInsets.only(
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
                          Navigator.of(context)
                              .push(
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
                  ? 'Következő mérkőzésnap '
                      'keresése...'
                  : 'Valódi mérkőzések '
                      'betöltése...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearchingNextDate
                  ? 'A SportMonks és a '
                      'TheSportsDB következő '
                      '30 napját ellenőrizzük.'
                  : 'A SportMonks és a '
                      'TheSportsDB adatait '
                      'egyesítjük.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
                height: 1.4,
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
            color: Colors.redAccent,
          ),
          const SizedBox(height: 18),
          const Text(
            'A meccsek betöltése nem sikerült',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ??
                'Ismeretlen adatforrás-hiba.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
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
            style:
                FilledButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(
                52,
              ),
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
            color:
                colors.onSurfaceVariant,
          ),
          const SizedBox(height: 18),
          Text(
            filterActive
                ? 'Nincs találat a szűrésre'
                : 'Ezen a napon nincs '
                    'elérhető mérkőzés',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            filterActive
                ? 'Módosítsd a keresést, '
                    'vagy kapcsold ki a '
                    'kedvencek szűrését.'
                : _nextAvailableDate != null
                    ? 'A következő elérhető '
                        'mérkőzésnap: '
                        '${_formatDate(_nextAvailableDate!)}'
                    : 'A következő 30 napban '
                        'egyik adatforrás sem '
                        'talált mérkőzést.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  colors.onSurfaceVariant,
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
              style:
                  FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(
                  52,
                ),
              ),
            ),
          ],

          if (!filterActive &&
              _nextAvailableDate == null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _findNextAvailableDate,
              icon: const Icon(
                Icons.search,
              ),
              label: const Text(
                'Következő mérkőzésnap keresése',
              ),
              style:
                  OutlinedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(
                  52,
                ),
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
              style:
                  OutlinedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(
                  52,
                ),
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
      _warningMessage = null;
      _nextAvailableDate = null;
      _displayedDate = _requestedDate;
      _lastRepositoryResult = null;
    });

    try {
      final MatchRepositoryResult result =
          await _matchRepository
              .fetchMatchesByDate(
        _requestedDate,
      );

      if (!mounted) {
        return;
      }

      if (result.matches.isNotEmpty) {
        setState(() {
          _loadedMatches =
              List<AppMatch>.from(
            result.matches,
          );

          _displayedDate =
              result.date;

          _lastRepositoryResult =
              result;

          _warningMessage =
              result.warningMessage;

          _informationMessage =
              _buildSourceInformation(
            result,
          );
        });

        return;
      }

      setState(() {
        _loadedMatches =
            <AppMatch>[];

        _lastRepositoryResult =
            result;

        _warningMessage =
            result.warningMessage;

        _isSearchingNextDate = true;
      });

      await _findNextAvailableDate(
        showLoading: false,
      );
    } on MatchRepositoryException catch (
      error,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadedMatches =
            <AppMatch>[];
        _lastRepositoryResult = null;
        _errorMessage =
            error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadedMatches =
            <AppMatch>[];
        _lastRepositoryResult = null;
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

  Future<void> _findNextAvailableDate({
    bool showLoading = true,
  }) async {
    if (_isLoading && showLoading) {
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _isSearchingNextDate = true;
        _errorMessage = null;
        _informationMessage = null;
        _warningMessage = null;
      });
    }

    try {
      final MatchAvailabilityResult availability =
          await _matchRepository
              .findNextAvailableMatches(
        startDate: _requestedDate.add(
          const Duration(days: 1),
        ),
        daysToCheck: 30,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _nextAvailableDate =
            availability.date;

        if (availability.hasMatches &&
            availability.date != null) {
          _informationMessage =
              'A kiválasztott napon nincs meccs. '
              'A következő elérhető mérkőzésnap: '
              '${_formatDate(availability.date!)}.';

          _warningMessage =
              availability.repositoryResult
                  ?.warningMessage;
        } else {
          _informationMessage =
              'A SportMonks és a TheSportsDB '
              'a következő '
              '${availability.checkedDays} napban '
              'sem talált elérhető mérkőzést.';

          if (availability
                  .diagnosticMessage !=
              null) {
            _warningMessage =
                availability
                    .diagnosticMessage;
          }
        }
      });
    } on MatchRepositoryException catch (
      error,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _nextAvailableDate = null;
        _errorMessage =
            error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _nextAvailableDate = null;
        _errorMessage =
            'A következő mérkőzésnap '
            'keresése nem sikerült: $error';
      });
    } finally {
      if (mounted && showLoading) {
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

    if (date == null ||
        _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearchingNextDate = false;
      _errorMessage = null;
      _informationMessage = null;
      _warningMessage = null;
    });

    try {
      final MatchRepositoryResult result =
          await _matchRepository
              .fetchMatchesByDate(
        date,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadedMatches =
            List<AppMatch>.from(
          result.matches,
        );

        _displayedDate =
            result.date;

        _nextAvailableDate = null;

        _lastRepositoryResult =
            result;

        _warningMessage =
            result.warningMessage;

        _informationMessage =
            'A következő elérhető '
            'mérkőzésnap meccsei láthatók. '
            '${_buildSourceInformation(result)}';
      });
    } on MatchRepositoryException catch (
      error,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'A mérkőzésnap megnyitása '
            'nem sikerült: $error';
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
    MatchRepositoryResult result,
  ) {
    if (result.usedBothSources) {
      return 'SportMonks: '
          '${result.sportMonksCount} • '
          'TheSportsDB: '
          '${result.theSportsDbCount} • '
          'Egyesített lista: '
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

    return 'Egyik adatforrás sem adott '
        'mérkőzést erre a napra.';
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

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchText = '';
      _favoritesOnly = false;
    });
  }
}
