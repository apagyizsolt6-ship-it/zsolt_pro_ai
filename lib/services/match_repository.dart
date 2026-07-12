// ===========================================
// Zsolt Pro AI
// Version: v0.15.4
// File: lib/services/match_repository.dart
// ===========================================

import '../models/app_match.dart';
import 'ai_engine_v2_service.dart';
import 'favorites_service.dart';
import 'sportmonks_service.dart';
import 'the_sports_db_service.dart';

/// A Zsolt Pro AI központi mérkőzés-adatkezelője.
///
/// Feladatai:
/// - SportMonks-mérkőzések lekérése;
/// - TheSportsDB-mérkőzések lekérése;
/// - a két adatforrás eredményeinek egyesítése;
/// - azonos mérkőzések kiszűrése;
/// - egységes AppMatch objektumok létrehozása;
/// - az eredeti API-azonosítók eltárolása;
/// - AI Engine 2.0 pontszám hozzárendelése;
/// - következő elérhető mérkőzésnap megkeresése;
/// - AI Top lista előállítása.
class MatchRepository {
  MatchRepository._();

  static final MatchRepository instance =
      MatchRepository._();

  final SportMonksService _sportMonksService =
      SportMonksService.instance;

  final TheSportsDbService _theSportsDbService =
      TheSportsDbService.instance;

  final AiEngineV2Service _aiEngine =
      AiEngineV2Service.instance;

  static const bool _theSportsDbEnabled = true;
  static const bool _sportMonksEnabled = true;

  bool get isSportMonksEnabled {
    return _sportMonksEnabled;
  }

  bool get isTheSportsDbEnabled {
    return _theSportsDbEnabled;
  }

  Future<MatchRepositoryResult> fetchMatchesByDate(
    DateTime date,
  ) async {
    final DateTime normalizedDate =
        _normalizeDate(date);

    List<AppMatch> sportMonksMatches =
        <AppMatch>[];

    List<AppMatch> theSportsDbMatches =
        <AppMatch>[];

    String? sportMonksError;
    String? theSportsDbError;

    if (_sportMonksEnabled) {
      try {
        final List<SportMonksFixture> fixtures =
            await _sportMonksService
                .fetchFixturesByDate(
          normalizedDate,
        );

        sportMonksMatches = fixtures
            .where(
              _isValidSportMonksFixture,
            )
            .map(
              _sportMonksFixtureToAppMatch,
            )
            .toList(
              growable: false,
            );
      } on SportMonksException catch (error) {
        sportMonksError = error.message;
      } catch (error) {
        sportMonksError =
            'Váratlan SportMonks hiba: $error';
      }
    }

    if (_theSportsDbEnabled) {
      try {
        final List<TheSportsDbEvent> events =
            await _theSportsDbService
                .fetchEventsByDate(
          normalizedDate,
        );

        theSportsDbMatches = events
            .where(
              _isValidTheSportsDbEvent,
            )
            .map(
              _theSportsDbEventToAppMatch,
            )
            .toList(
              growable: false,
            );
      } on TheSportsDbException catch (error) {
        theSportsDbError = error.message;
      } catch (error) {
        theSportsDbError =
            'Váratlan TheSportsDB hiba: $error';
      }
    }

    final List<AppMatch> mergedMatches =
        _mergeMatches(
      sportMonksMatches:
          sportMonksMatches,
      theSportsDbMatches:
          theSportsDbMatches,
    );

    if (mergedMatches.isEmpty &&
        sportMonksError != null &&
        theSportsDbError != null) {
      throw MatchRepositoryException(
        'Egyik mérkőzés-adatforrás sem érhető el.\n\n'
        'SportMonks: $sportMonksError\n\n'
        'TheSportsDB: $theSportsDbError',
      );
    }

    return MatchRepositoryResult(
      date: normalizedDate,
      matches: mergedMatches,
      sportMonksCount:
          sportMonksMatches.length,
      theSportsDbCount:
          theSportsDbMatches.length,
      sportMonksError:
          sportMonksError,
      theSportsDbError:
          theSportsDbError,
      usedSportMonks:
          sportMonksMatches.isNotEmpty,
      usedTheSportsDb:
          theSportsDbMatches.isNotEmpty,
    );
  }

  Future<MatchRepositoryResult>
      fetchTodayMatches() {
    return fetchMatchesByDate(
      DateTime.now(),
    );
  }

  Future<MatchRepositoryResult>
      fetchTomorrowMatches() {
    return fetchMatchesByDate(
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }

  Future<MatchAvailabilityResult>
      findNextAvailableMatches({
    required DateTime startDate,
    int daysToCheck = 30,
  }) async {
    if (daysToCheck < 1) {
      throw const MatchRepositoryException(
        'Legalább egy napot ellenőrizni kell.',
      );
    }

    final int safeDays =
        daysToCheck.clamp(
      1,
      60,
    );

    final DateTime normalizedStart =
        _normalizeDate(
      startDate,
    );

    final List<String> collectedErrors =
        <String>[];

    for (
      int offset = 0;
      offset < safeDays;
      offset++
    ) {
      final DateTime checkedDate =
          normalizedStart.add(
        Duration(
          days: offset,
        ),
      );

      try {
        final MatchRepositoryResult result =
            await fetchMatchesByDate(
          checkedDate,
        );

        if (result.matches.isNotEmpty) {
          return MatchAvailabilityResult(
            date: checkedDate,
            matches: result.matches,
            checkedDays: offset + 1,
            repositoryResult: result,
          );
        }

        if (result.sportMonksError != null) {
          collectedErrors.add(
            'SportMonks '
            '${_formatDate(checkedDate)}: '
            '${result.sportMonksError}',
          );
        }

        if (result.theSportsDbError != null) {
          collectedErrors.add(
            'TheSportsDB '
            '${_formatDate(checkedDate)}: '
            '${result.theSportsDbError}',
          );
        }
      } on MatchRepositoryException catch (error) {
        collectedErrors.add(
          '${_formatDate(checkedDate)}: '
          '${error.message}',
        );
      }
    }

    return MatchAvailabilityResult(
      date: null,
      matches: const <AppMatch>[],
      checkedDays: safeDays,
      repositoryResult: null,
      diagnosticMessage:
          collectedErrors.isEmpty
              ? null
              : collectedErrors.last,
    );
  }

  Future<List<AppMatch>> fetchMatchesBetween({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime normalizedStart =
        _normalizeDate(
      startDate,
    );

    final DateTime normalizedEnd =
        _normalizeDate(
      endDate,
    );

    if (normalizedEnd.isBefore(
      normalizedStart,
    )) {
      throw const MatchRepositoryException(
        'A záró dátum nem lehet korábbi '
        'a kezdő dátumnál.',
      );
    }

    final List<AppMatch> allMatches =
        <AppMatch>[];

    DateTime currentDate =
        normalizedStart;

    while (!currentDate.isAfter(
      normalizedEnd,
    )) {
      final MatchRepositoryResult result =
          await fetchMatchesByDate(
        currentDate,
      );

      allMatches.addAll(
        result.matches,
      );

      currentDate = currentDate.add(
        const Duration(
          days: 1,
        ),
      );
    }

    return _removeDuplicateAppMatches(
      allMatches,
    );
  }

  Future<MatchTopResult> fetchTopMatches({
    DateTime? startDate,
    int limit = 5,
    int daysToCheck = 30,
  }) async {
    final int safeLimit =
        limit.clamp(
      1,
      20,
    );

    final DateTime normalizedStart =
        _normalizeDate(
      startDate ?? DateTime.now(),
    );

    MatchRepositoryResult firstResult;

    try {
      firstResult =
          await fetchMatchesByDate(
        normalizedStart,
      );
    } on MatchRepositoryException {
      firstResult = MatchRepositoryResult(
        date: normalizedStart,
        matches: const <AppMatch>[],
        sportMonksCount: 0,
        theSportsDbCount: 0,
        usedSportMonks: false,
        usedTheSportsDb: false,
      );
    }

    DateTime selectedDate =
        normalizedStart;

    List<AppMatch> availableMatches =
        List<AppMatch>.from(
      firstResult.matches,
    );

    MatchRepositoryResult? sourceResult =
        firstResult;

    if (availableMatches.isEmpty) {
      final MatchAvailabilityResult availability =
          await findNextAvailableMatches(
        startDate: normalizedStart.add(
          const Duration(
            days: 1,
          ),
        ),
        daysToCheck: daysToCheck,
      );

      if (!availability.hasMatches ||
          availability.date == null) {
        return MatchTopResult(
          date: null,
          matches: const <AppMatch>[],
          checkedDays:
              availability.checkedDays,
          repositoryResult: null,
        );
      }

      selectedDate =
          availability.date!;

      availableMatches =
          List<AppMatch>.from(
        availability.matches,
      );

      sourceResult =
          availability.repositoryResult;
    }

    availableMatches.sort(
      (
        AppMatch first,
        AppMatch second,
      ) {
        final int scoreComparison =
            second.aiScore.compareTo(
          first.aiScore,
        );

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        final int timeComparison =
            first.matchTime.compareTo(
          second.matchTime,
        );

        if (timeComparison != 0) {
          return timeComparison;
        }

        return first.homeTeam
            .toLowerCase()
            .compareTo(
              second.homeTeam.toLowerCase(),
            );
      },
    );

    return MatchTopResult(
      date: selectedDate,
      matches: availableMatches
          .take(
            safeLimit,
          )
          .toList(
            growable: false,
          ),
      checkedDays: _daysBetween(
            normalizedStart,
            selectedDate,
          ) +
          1,
      repositoryResult:
          sourceResult,
    );
  }

  List<AppMatch> _mergeMatches({
    required List<AppMatch>
        sportMonksMatches,
    required List<AppMatch>
        theSportsDbMatches,
  }) {
    final Map<String, AppMatch> merged =
        <String, AppMatch>{};

    for (final AppMatch match
        in sportMonksMatches) {
      merged[_createMatchKey(match)] =
          match;
    }

    for (final AppMatch theSportsDbMatch
        in theSportsDbMatches) {
      final String key =
          _createMatchKey(
        theSportsDbMatch,
      );

      final AppMatch? existing =
          merged[key];

      if (existing == null) {
        merged[key] =
            theSportsDbMatch;
        continue;
      }

      final AppMatch combined =
          _mergeTwoMatches(
        primary: existing,
        secondary:
            theSportsDbMatch,
      );

      merged[key] =
          _applyAiEngineScore(
        combined,
      );
    }

    final List<AppMatch> result =
        merged.values
            .map(
              _applyAiEngineScore,
            )
            .toList();

    result.sort(
      _compareMatches,
    );

    return result;
  }

  List<AppMatch> _removeDuplicateAppMatches(
    List<AppMatch> matches,
  ) {
    final Map<String, AppMatch> unique =
        <String, AppMatch>{};

    for (final AppMatch match
        in matches) {
      final String key =
          _createMatchKey(
        match,
      );

      final AppMatch? existing =
          unique[key];

      if (existing == null) {
        unique[key] =
            _applyAiEngineScore(
          match,
        );
        continue;
      }

      final AppMatch combined =
          _mergeTwoMatches(
        primary: existing,
        secondary: match,
      );

      unique[key] =
          _applyAiEngineScore(
        combined,
      );
    }

    final List<AppMatch> result =
        unique.values.toList();

    result.sort(
      _compareMatches,
    );

    return result;
  }

  AppMatch _mergeTwoMatches({
    required AppMatch primary,
    required AppMatch secondary,
  }) {
    return primary.copyWith(
      homeTeamLogoUrl:
          _preferText(
        primary.homeTeamLogoUrl,
        secondary.homeTeamLogoUrl,
      ),
      awayTeamLogoUrl:
          _preferText(
        primary.awayTeamLogoUrl,
        secondary.awayTeamLogoUrl,
      ),
      leagueLogoUrl:
          _preferText(
        primary.leagueLogoUrl,
        secondary.leagueLogoUrl,
      ),
      externalMatchId:
          _preferText(
        primary.externalMatchId,
        secondary.externalMatchId,
      ),
      externalLeagueId:
          _preferText(
        primary.externalLeagueId,
        secondary.externalLeagueId,
      ),
      homeTeamId:
          _preferText(
        primary.homeTeamId,
        secondary.homeTeamId,
      ),
      awayTeamId:
          _preferText(
        primary.awayTeamId,
        secondary.awayTeamId,
      ),
      seasonId:
          _preferText(
        primary.seasonId,
        secondary.seasonId,
      ),
      country:
          _preferText(
        primary.country,
        secondary.country,
      ),
      venue:
          _preferText(
        primary.venue,
        secondary.venue,
      ),
      status:
          _preferText(
        primary.status,
        secondary.status,
      ),
      isLive:
          primary.isLive ||
              secondary.isLive,
      hasStatistics:
          primary.hasStatistics ||
              secondary.hasStatistics,
      hasOdds:
          primary.hasOdds ||
              secondary.hasOdds,
    );
  }

  bool _isValidSportMonksFixture(
    SportMonksFixture fixture,
  ) {
    return !fixture.placeholder &&
        fixture.id > 0 &&
        fixture.homeTeam.trim().isNotEmpty &&
        fixture.awayTeam.trim().isNotEmpty;
  }

  bool _isValidTheSportsDbEvent(
    TheSportsDbEvent event,
  ) {
    return event.isSoccer &&
        event.homeTeam.trim().isNotEmpty &&
        event.awayTeam.trim().isNotEmpty &&
        event.matchDate.year > 1970;
  }

  AppMatch _sportMonksFixtureToAppMatch(
    SportMonksFixture fixture,
  ) {
    final DateTime localStart =
        fixture.startingAt.toLocal();

    final String externalMatchId =
        fixture.id.toString();

    final String id =
        'sportmonks_$externalMatchId';

    final String status =
        fixture.stateShortName.trim().isNotEmpty
            ? fixture.stateShortName.trim()
            : fixture.stateName.trim();

    final AppMatch baseMatch =
        AppMatch(
      id: id,
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
      aiScore: 0,
      isFavorite:
          FavoritesService.isFavorite(
        id,
      ),
      isLive:
          fixture.isLive,
      homeTeamLogoUrl:
          fixture.homeTeamImagePath.trim(),
      awayTeamLogoUrl:
          fixture.awayTeamImagePath.trim(),
      leagueLogoUrl:
          fixture.leagueImagePath.trim(),
      dataSource:
          MatchDataSource.sportMonks,
      externalMatchId:
          externalMatchId,
      externalLeagueId:
          fixture.leagueId > 0
              ? fixture.leagueId.toString()
              : '',
      homeTeamId:
          fixture.homeTeamId > 0
              ? fixture.homeTeamId.toString()
              : '',
      awayTeamId:
          fixture.awayTeamId > 0
              ? fixture.awayTeamId.toString()
              : '',
      seasonId:
          fixture.seasonId > 0
              ? fixture.seasonId.toString()
              : '',
      country: '',
      venue: '',
      status: status,
      hasStatistics: false,
      hasOdds:
          fixture.hasOdds,
    );

    return _applyAiEngineScore(
      baseMatch,
    );
  }

  AppMatch _theSportsDbEventToAppMatch(
    TheSportsDbEvent event,
  ) {
    final String rawId =
        event.id.trim().isEmpty
            ? event.uniqueKey
            : event.id.trim();

    final String id =
        'thesportsdb_$rawId';

    final AppMatch baseMatch =
        AppMatch(
      id: id,
      league:
          event.leagueName.trim().isEmpty
              ? 'Ismeretlen bajnokság'
              : event.leagueName.trim(),
      homeTeam:
          event.homeTeam.trim(),
      awayTeam:
          event.awayTeam.trim(),
      matchDate:
          event.matchDate,
      matchTime:
          event.matchTime,
      aiScore: 0,
      isFavorite:
          FavoritesService.isFavorite(
        id,
      ),
      isLive:
          event.isLive,
      homeTeamLogoUrl:
          event.homeTeamBadgeUrl.trim(),
      awayTeamLogoUrl:
          event.awayTeamBadgeUrl.trim(),
      leagueLogoUrl:
          event.leagueBadgeUrl.trim(),
      dataSource:
          MatchDataSource.theSportsDb,
      externalMatchId:
          event.id.trim(),
      externalLeagueId:
          event.leagueId.trim(),
      homeTeamId:
          event.homeTeamId.trim(),
      awayTeamId:
          event.awayTeamId.trim(),
      seasonId:
          event.season.trim(),
      country:
          event.country.trim(),
      venue:
          event.venue.trim(),
      status:
          event.status.trim(),
      hasStatistics: false,
      hasOdds: false,
    );

    return _applyAiEngineScore(
      baseMatch,
    );
  }

  AppMatch _applyAiEngineScore(
    AppMatch match,
  ) {
    final AiMatchAnalysis analysis =
        _aiEngine.analyzeWithFallbackData(
      match: match,
    );

    return match.copyWith(
      aiScore:
          analysis.aiScore,
    );
  }

  String _preferText(
    String primary,
    String secondary,
  ) {
    if (primary.trim().isNotEmpty) {
      return primary;
    }

    return secondary;
  }

  int _compareMatches(
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
              second.league.toLowerCase(),
            );

    if (leagueComparison != 0) {
      return leagueComparison;
    }

    return first.homeTeam
        .toLowerCase()
        .compareTo(
          second.homeTeam.toLowerCase(),
        );
  }

  String _createMatchKey(
    AppMatch match,
  ) {
    return match.uniqueComparisonKey;
  }

  DateTime _normalizeDate(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  int _daysBetween(
    DateTime first,
    DateTime second,
  ) {
    final DateTime normalizedFirst =
        _normalizeDate(
      first,
    );

    final DateTime normalizedSecond =
        _normalizeDate(
      second,
    );

    return normalizedSecond
        .difference(
          normalizedFirst,
        )
        .inDays
        .abs();
  }

  String _formatDate(
    DateTime date,
  ) {
    final String year =
        date.year.toString().padLeft(
              4,
              '0',
            );

    final String month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final String day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }
}

class MatchRepositoryResult {
  final DateTime date;
  final List<AppMatch> matches;

  final int sportMonksCount;
  final int theSportsDbCount;

  final bool usedSportMonks;
  final bool usedTheSportsDb;

  final String? sportMonksError;
  final String? theSportsDbError;

  const MatchRepositoryResult({
    required this.date,
    required this.matches,
    required this.sportMonksCount,
    required this.theSportsDbCount,
    required this.usedSportMonks,
    required this.usedTheSportsDb,
    this.sportMonksError,
    this.theSportsDbError,
  });

  int get totalCount {
    return matches.length;
  }

  bool get hasMatches {
    return matches.isNotEmpty;
  }

  bool get hasAnyError {
    return sportMonksError != null ||
        theSportsDbError != null;
  }

  bool get usedBothSources {
    return usedSportMonks &&
        usedTheSportsDb;
  }

  String get sourceLabel {
    if (usedBothSources) {
      return 'SportMonks + TheSportsDB';
    }

    if (usedSportMonks) {
      return 'SportMonks';
    }

    if (usedTheSportsDb) {
      return 'TheSportsDB';
    }

    return 'Nincs adatforrás';
  }

  String? get warningMessage {
    if (sportMonksError != null &&
        theSportsDbError == null) {
      return 'A SportMonks jelenleg nem érhető el, '
          'ezért a TheSportsDB adatait használjuk.';
    }

    if (theSportsDbError != null &&
        sportMonksError == null) {
      return 'A TheSportsDB jelenleg nem érhető el, '
          'ezért csak a SportMonks adatait használjuk.';
    }

    return null;
  }
}

class MatchAvailabilityResult {
  final DateTime? date;
  final List<AppMatch> matches;
  final int checkedDays;

  final MatchRepositoryResult?
      repositoryResult;

  final String? diagnosticMessage;

  const MatchAvailabilityResult({
    required this.date,
    required this.matches,
    required this.checkedDays,
    required this.repositoryResult,
    this.diagnosticMessage,
  });

  bool get hasMatches {
    return date != null &&
        matches.isNotEmpty;
  }
}

class MatchTopResult {
  final DateTime? date;
  final List<AppMatch> matches;
  final int checkedDays;

  final MatchRepositoryResult?
      repositoryResult;

  const MatchTopResult({
    required this.date,
    required this.matches,
    required this.checkedDays,
    required this.repositoryResult,
  });

  bool get hasMatches {
    return date != null &&
        matches.isNotEmpty;
  }
}

class MatchRepositoryException
    implements Exception {
  final String message;

  const MatchRepositoryException(
    this.message,
  );

  @override
  String toString() {
    return message;
  }
}
