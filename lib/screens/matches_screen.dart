// ===========================================
// Zsolt Pro AI
// Version: v0.16.5 - Hide Both Info Bars
// File: lib/screens/matches_screen.dart
// ===========================================

import 'package:flutter/material.dart';

import '../models/app_match.dart';
import '../services/favorites_service.dart';
import '../services/match_repository.dart';
import '../utils/league_translator.dart';
import '../widgets/day_selector.dart';
import '../widgets/league_header.dart';
import '../widgets/match_card.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final MatchRepository _matchRepository = MatchRepository.instance;

  int _selectedDayIndex = 0;
  String _searchText = '';

  bool _favoritesOnly = false;
  bool _isLoading = false;
  bool _isSearchingNextDate = false;
  bool _showDataStatus = false; // ALAPÉRTELMEZETTEN MINDKÉT INFÓ SÁV REJTVE

  String? _errorMessage;
  String? _informationMessage;
  String? _warningMessage;

  DateTime? _nextAvailableDate;
  MatchRepositoryResult? _lastRepositoryResult;

  List<AppMatch> _loadedMatches = <AppMatch>[];

  /// Tárolja, hogy mely bajnokságcsoportok vannak kinyitva/összecsukva.
  final Map<String, bool> _leagueExpansionState = <String, bool>{};

  /// Kiemelt topligák listája a rendezéshez
  static const List<String> _topLeaguesKeywords = <String>[
    'hungarian nb i',
    'nb i',
    'otp bank liga',
    'premier league',
    'la liga',
    'laliga',
    'serie a',
    'bundesliga',
    'ligue 1',
    'champions league',
    'europa league',
  ];

  DateTime get _requestedDate {
    final DateTime now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day + _selectedDayIndex,
    );
  }

  List<AppMatch> get _filteredMatches {
    final String normalizedSearch = _searchText.trim().toLowerCase();

    final List<AppMatch> result = _loadedMatches.where((AppMatch match) {
      final String translatedLeague = LeagueTranslator.translate(match.league).toLowerCase();

      final bool searchMatches = normalizedSearch.isEmpty ||
          match.homeTeam.toLowerCase().contains(normalizedSearch) ||
          match.awayTeam.toLowerCase().contains(normalizedSearch) ||
          match.league.toLowerCase().contains(normalizedSearch) ||
          translatedLeague.contains(normalizedSearch);

      final bool favoriteMatches =
          !_favoritesOnly || FavoritesService.isFavorite(match.id);

      return searchMatches && favoriteMatches;
    }).toList();

    result.sort((AppMatch first, AppMatch second) {
      final int dateComparison = first.matchDate.compareTo(second.matchDate);
      if (dateComparison != 0) return dateComparison;

      final int timeComparison = first.matchTime.compareTo(second.matchTime);
      if (timeComparison != 0) return timeComparison;

      final int leagueComparison =
          first.league.toLowerCase().compareTo(second.league.toLowerCase());
      if (leagueComparison != 0) return leagueComparison;

      return first.homeTeam
          .toLowerCase()
          .compareTo(second.homeTeam.toLowerCase());
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<AppMatch> matches = _filteredMatches;
    final Map<String, List<AppMatch>> groupedMatches = _groupMatchesByLeague(matches);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚽ Meccsek',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Meccsek frissítése',
            onPressed: _isLoading ? null : _loadMatches,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÁRAMVONALASÍTOTT KERESŐ + INFÓ + KEDVENCEK + NYITÁS/CSUKÁS
            _buildStreamlinedHeader(groupedMatches),

            const SizedBox(height: 6),

            // 2. KOMPAKT DÁTUMVÁLASZTÓ SÁV
            DaySelector(
              selectedIndex: _selectedDayIndex,
              onChanged: (int index) {
                if (_selectedDayIndex == index) return;

                setState(() {
                  _selectedDayIndex = index;
                  _loadedMatches = <AppMatch>[];
                  _leagueExpansionState.clear();
                  _nextAvailableDate = null;
                  _errorMessage = null;
                  _informationMessage = null;
                  _warningMessage = null;
                });

                _loadMatches();
              },
            ),

            // 3. MINDKÉT ADATINFÓ DOBOZ ELREJTVE (CSAK AKKOR LÁTHATÓK, HA _showDataStatus == TRUE)
            if (_showDataStatus) ...[
              _buildDataStatusBar(context: context),
              if (_informationMessage != null)
                _buildInformationBanner(context: context),
            ],

            if (_warningMessage != null) _buildWarningBanner(context: context),

            const SizedBox(height: 4),

            Expanded(
              child: _buildContent(
                context: context,
                groupedMatches: groupedMatches,
                matches: matches,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Áramvonalasított felső sor: Kereső + Infó kapcsoló + Kedvencek + Nyitás/Csukás
  Widget _buildStreamlinedHeader(Map<String, List<AppMatch>> groupedMatches) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          // Keresőmező
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13.5),
                onChanged: (String value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Keresés csapatra, ligára...",
                  hintStyle: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Infó dobozok megjelenítése / elrejtése kapcsoló
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _showDataStatus = !_showDataStatus;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _showDataStatus
                    ? colors.primaryContainer.withValues(alpha: 0.5)
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _showDataStatus ? colors.primary : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Icon(
                _showDataStatus ? Icons.info : Icons.info_outline,
                color: _showDataStatus ? colors.primary : colors.onSurfaceVariant,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Kedvencek gyorsgomb
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _favoritesOnly = !_favoritesOnly;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _favoritesOnly
                    ? Colors.amber.withValues(alpha: 0.18)
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _favoritesOnly ? Colors.amber : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Icon(
                _favoritesOnly ? Icons.star : Icons.star_border,
                color: _favoritesOnly ? Colors.amber : colors.onSurfaceVariant,
                size: 18,
              ),
            ),
          ),

          if (groupedMatches.isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              tooltip: _areAllExpanded(groupedMatches) ? 'Összes csukása' : 'Összes nyitása',
              icon: Icon(
                _areAllExpanded(groupedMatches)
                    ? Icons.unfold_less
                    : Icons.unfold_more,
                size: 20,
                color: colors.primary,
              ),
              onPressed: () => _toggleAllLeagues(groupedMatches),
            ),
          ],
        ],
      ),
    );
  }

  /// Adatinfó sáv (csak akkor látható, ha a felső ⓘ ikonra rányomsz)
  Widget _buildDataStatusBar({required BuildContext context}) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    final MatchRepositoryResult? result = _lastRepositoryResult;
    final bool hasError = _errorMessage != null;
    final String sourceLabel =
        result?.sourceLabel ?? 'SportMonks + TheSportsDB';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hasError
            ? Colors.red.withValues(alpha: 0.08)
            : colors.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError
              ? Colors.redAccent.withValues(alpha: 0.45)
              : colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
            size: 16,
            color: hasError ? Colors.redAccent : Colors.greenAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasError
                  ? 'A mérkőzésadatok betöltése nem sikerült.'
                  : '$sourceLabel • ${_loadedMatches.length} mérkőzés',
              style: TextStyle(
                color: hasError ? Colors.redAccent : colors.onSurfaceVariant,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<AppMatch>> _groupMatchesByLeague(List<AppMatch> matches) {
    final Map<String, List<AppMatch>> grouped = <String, List<AppMatch>>{};

    for (final AppMatch match in matches) {
      final String rawLeague = match.league.trim().isEmpty
          ? 'Ismeretlen bajnokság'
          : match.league.trim();

      final String leagueName = LeagueTranslator.translate(rawLeague);

      grouped.putIfAbsent(leagueName, () => <AppMatch>[]);
      grouped[leagueName]!.add(match);
    }

    final List<MapEntry<String, List<AppMatch>>> sortedEntries =
        grouped.entries.toList()
          ..sort((first, second) {
            final bool firstIsTop = _isTopLeague(first.key);
            final bool secondIsTop = _isTopLeague(second.key);

            if (firstIsTop && !secondIsTop) return -1;
            if (!firstIsTop && secondIsTop) return 1;

            return first.key.toLowerCase().compareTo(second.key.toLowerCase());
          });

    final Map<String, List<AppMatch>> result = <String, List<AppMatch>>{};
    for (final MapEntry<String, List<AppMatch>> entry in sortedEntries) {
      result[entry.key] = entry.value;

      _leagueExpansionState.putIfAbsent(
        entry.key,
        () => _isTopLeague(entry.key) || _searchText.trim().isNotEmpty,
      );
    }

    return result;
  }

  bool _isTopLeague(String leagueName) {
    final String normalized = leagueName.toLowerCase();
    return _topLeaguesKeywords.any((keyword) => normalized.contains(keyword));
  }

  bool _areAllExpanded(Map<String, List<AppMatch>> groupedMatches) {
    return groupedMatches.keys.every((key) => _leagueExpansionState[key] ?? false);
  }

  void _toggleAllLeagues(Map<String, List<AppMatch>> groupedMatches) {
    final bool targetState = !_areAllExpanded(groupedMatches);
    setState(() {
      for (final String key in groupedMatches.keys) {
        _leagueExpansionState[key] = targetState;
      }
    });
  }

  Widget _buildWarningBanner({required BuildContext context}) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _warningMessage!,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationBanner({required BuildContext context}) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: colors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _informationMessage!,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required Map<String, List<AppMatch>> groupedMatches,
    required List<AppMatch> matches,
  }) {
    if (_isLoading && _loadedMatches.isEmpty) {
      return _buildLoadingState(context: context);
    }

    if (_errorMessage != null && _loadedMatches.isEmpty) {
      return _buildErrorState(context: context);
    }

    if (matches.isEmpty) {
      return _buildEmptyState(context: context);
    }

    final ColorScheme colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
        children: groupedMatches.entries.map((entry) {
          final String leagueName = entry.key;
          final List<AppMatch> leagueMatches = entry.value;
          final bool isExpanded = _leagueExpansionState[leagueName] ?? false;
          final bool isTop = _isTopLeague(leagueName);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isTop
                      ? colors.primary.withValues(alpha: 0.3)
                      : colors.outlineVariant.withValues(alpha: 0.2),
                  width: isTop ? 1.2 : 1,
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _leagueExpansionState[leagueName] = !isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: LeagueHeader(leagueName: leagueName),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${leagueMatches.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: colors.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Column(
                        children: leagueMatches.map((match) {
                          return MatchCard(
                            match: match,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) {
                                    return MatchDetailScreen(match: match);
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState({required BuildContext context}) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              _isSearchingNextDate
                  ? 'Következő mérkőzésnap keresése...'
                  : 'Valódi mérkőzések betöltése...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearchingNextDate
                  ? 'A SportMonks és a TheSportsDB következő 30 napját ellenőrizzük.'
                  : 'A SportMonks és a TheSportsDB adatait egyesítjük.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({required BuildContext context}) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          const Icon(
            Icons.cloud_off_outlined,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'A meccsek betöltése nem sikerült',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Ismeretlen adatforrás-hiba.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isLoading ? null : _loadMatches,
            icon: const Icon(Icons.refresh),
            label: const Text('Újrapróbálás'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required BuildContext context}) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool filterActive =
        _searchText.trim().isNotEmpty || _favoritesOnly;

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 55),
          Icon(
            filterActive
                ? Icons.filter_alt_off_outlined
                : Icons.event_busy_outlined,
            size: 64,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            filterActive
                ? 'Nincs találat a szűrésre'
                : 'Ezen a napon nincs elérhető mérkőzés',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filterActive
                ? 'Módosítsd a keresést, vagy kapcsold ki a kedvencek szűrését.'
                : _nextAvailableDate != null
                    ? 'A következő elérhető mérkőzésnap: ${_formatDate(_nextAvailableDate!)}'
                    : 'A következő 30 napban egyik adatforrás sem talált mérkőzést.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (!filterActive && _nextAvailableDate != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openNextAvailableDate,
              icon: const Icon(Icons.event_available_outlined),
              label: Text(
                'Meccsek megnyitása – ${_formatDate(_nextAvailableDate!)}',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (!filterActive && _nextAvailableDate == null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _findNextAvailableDate,
              icon: const Icon(Icons.search),
              label: const Text('Következő mérkőzésnap keresése'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (filterActive) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Szűrők törlése'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadMatches() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isSearchingNextDate = false;
      _errorMessage = null;
      _informationMessage = null;
      _warningMessage = null;
      _nextAvailableDate = null;
    });

    try {
      final MatchRepositoryResult result =
          await _matchRepository.fetchMatchesByDate(_requestedDate);

      if (!mounted) return;

      if (result.matches.isNotEmpty) {
        setState(() {
          _loadedMatches = List<AppMatch>.from(result.matches);
          _lastRepositoryResult = result;
          _warningMessage = result.warningMessage;
          _informationMessage = _buildSourceInformation(result);
        });
        return;
      }

      setState(() {
        _loadedMatches = <AppMatch>[];
        _lastRepositoryResult = result;
        _warningMessage = result.warningMessage;
        _isSearchingNextDate = true;
      });

      await _findNextAvailableDate(showLoading: false);
    } on MatchRepositoryException catch (error) {
      if (!mounted) return;

      setState(() {
        _loadedMatches = <AppMatch>[];
        _lastRepositoryResult = null;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadedMatches = <AppMatch>[];
        _lastRepositoryResult = null;
        _errorMessage =
            'Váratlan hiba történt. Típus: ${error.runtimeType}. Részlet: $error';
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

  Future<void> _findNextAvailableDate({bool showLoading = true}) async {
    if (_isLoading && showLoading) return;

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
          await _matchRepository.findNextAvailableMatches(
        startDate: _requestedDate.add(const Duration(days: 1)),
        daysToCheck: 30,
      );

      if (!mounted) return;

      setState(() {
        _nextAvailableDate = availability.date;

        if (availability.hasMatches && availability.date != null) {
          _informationMessage =
              'A kiválasztott napon nincs meccs. A következő elérhető mérkőzésnap: ${_formatDate(availability.date!)}.';
          _warningMessage = availability.repositoryResult?.warningMessage;
        } else {
          _informationMessage =
              'A SportMonks és a TheSportsDB a következő ${availability.checkedDays} napban sem talált elérhető mérkőzést.';
          if (availability.diagnosticMessage != null) {
            _warningMessage = availability.diagnosticMessage;
          }
        }
      });
    } on MatchRepositoryException catch (error) {
      if (!mounted) return;

      setState(() {
        _nextAvailableDate = null;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _nextAvailableDate = null;
        _errorMessage =
            'A következő mérkőzésnap keresése nem sikerült: $error';
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
    final DateTime? date = _nextAvailableDate;
    if (date == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _isSearchingNextDate = false;
      _errorMessage = null;
      _informationMessage = null;
      _warningMessage = null;
    });

    try {
      final MatchRepositoryResult result =
          await _matchRepository.fetchMatchesByDate(date);

      if (!mounted) return;

      setState(() {
        _loadedMatches = List<AppMatch>.from(result.matches);
        _nextAvailableDate = null;
        _lastRepositoryResult = result;
        _warningMessage = result.warningMessage;
        _informationMessage =
            'A következő elérhető mérkőzésnap meccsei láthatók. ${_buildSourceInformation(result)}';
      });
    } on MatchRepositoryException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'A mérkőzésnap megnyitása nem sikerült: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildSourceInformation(MatchRepositoryResult result) {
    if (result.usedBothSources) {
      return 'SportMonks: ${result.sportMonksCount} • TheSportsDB: ${result.theSportsDbCount} • Egyesített lista: ${result.totalCount}.';
    }

    if (result.usedSportMonks) {
      return 'SportMonks adatforrás: ${result.sportMonksCount} mérkőzés.';
    }

    if (result.usedTheSportsDb) {
      return 'TheSportsDB adatforrás: ${result.theSportsDbCount} mérkőzés.';
    }

    return 'Egyik adatforrás sem adott mérkőzést erre a napra.';
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString();
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

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
