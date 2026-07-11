// ===========================================
// Zsolt Pro AI
// Version: v0.14.3
// File: lib/services/match_repository.dart
// ===========================================

import '../models/app_match.dart';
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
/// - következő elérhető mérkőzésnap megkeresése;
/// - AI Top lista előállítása.
///
/// A képernyőknek később már nem kell közvetlenül tudniuk,
/// hogy a mérkőzés melyik API-ból érkezett.
class MatchRepository {
  MatchRepository._();

  static final MatchRepository instance =
      MatchRepository._();

  final SportMonksService _sportMonksService =
      SportMonksService.instance;

  final TheSportsDbService _theSportsDbService =
      TheSportsDbService.instance;

  /// A TheSportsDB használatának központi kapcsolója.
  ///
  /// Ha később ki akarjuk kapcsolni vagy eltávolítani,
  /// elég ezt false értékre állítani.
  static const bool _theSportsDbEnabled = true;

  /// SportMonks használata elsődleges adatforrásként.
  static const bool _sportMonksEnabled = true;

  bool get isSportMonksEnabled {
    return _sportMonksEnabled;
  }

  bool get isTheSportsDbEnabled {
    return _theSportsDbEnabled;
  }

  /// Egy kiválasztott nap összes elérhető mérkőzését lekéri.
  ///
  /// Mindkét API-t megpróbálja használni. Ha az egyik hibázik,
  /// de a másik működik, a használható eredményt visszaadja.
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
            .where(_isValidSportMonksFixture)
            .map(_sportMonksFixtureToAppMatch)
            .toList(growable: false);
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
            .where(_isValidTheSportsDbEvent)
            .map(_theSportsDbEventToAppMatch)
            .toList(growable: false);
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

  /// A mai nap mérkőzéseit tölti be.
  Future<MatchRepositoryResult>
      fetchTodayMatches() {
    return fetchMatchesByDate(
      DateTime.now(),
    );
  }

  /// A holnapi nap mérkőzéseit tölti be.
  Future<MatchRepositoryResult>
      fetchTomorrowMatches() {
    return fetchMatchesByDate(
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }

  /// Megkeresi az első olyan napot, amelyen van legalább
  /// egy megjeleníthető mérkőzés.
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
        daysToCheck.clamp(1, 60);

    final DateTime normalizedStart =
        _normalizeDate(startDate);

    final List<String> collectedErrors =
        <String>[];

    for (
      int offset = 0;
      offset < safeDays;
      offset++
    ) {
      final DateTime checkedDate =
          normalizedStart.add(
        Duration(days: offset),
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

  /// Egy dátumintervallum összes mérkőzését lekéri.
  Future<List<AppMatch>> fetchMatchesBetween({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DateTime normalizedStart =
        _normalizeDate(startDate);

    final DateTime normalizedEnd =
        _normalizeDate(endDate);

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
        const Duration(days: 1),
      );
    }

    return _removeDuplicateAppMatches(
      allMatches,
    );
  }

  /// A következő elérhető mérkőzésnap legjobb
  /// AI-pontszámú meccseit adja vissza.
  Future<MatchTopResult> fetchTopMatches({
    DateTime? startDate,
    int limit = 5,
    int daysToCheck = 30,
  }) async {
    final int safeLimit =
        limit.clamp(1, 20);

    final DateTime normalizedStart =
        _normalizeDate(
      startDate ?? DateTime.now(),
    );

    MatchRepositoryResult firstResult;

    try {
      firstResult = await fetchMatchesByDate(
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
      final MatchAvailabilityResult
          availability =
          await findNextAvailableMatches(
        startDate: normalizedStart.add(
          const Duration(days: 1),
        ),
        daysToCheck: daysToCheck,
      );

      if (!availability.hasMatches ||
          availability.date == null) {
        return MatchTopResult(
          date: null,
          matches:
              const <AppMatch>[],
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
          .take(safeLimit)
          .toList(growable: false),
      checkedDays: _daysBetween(
            normalizedStart,
            selectedDate,
          ) +
          1,
      repositoryResult:
          sourceResult,
    );
  }

  /// SportMonks és TheSportsDB listák egyesítése.
  ///
  /// Ha ugyanaz a mérkőzés mindkét API-ban megtalálható,
  /// a SportMonks-adat az elsődleges, de a hiányzó logókat
  /// a TheSportsDB adataiból kiegészítjük.
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

      merged[key] = existing.copyWith(
        homeTeamLogoUrl:
            existing.homeTeamLogoUrl
                    .trim()
                    .isNotEmpty
                ? existing.homeTeamLogoUrl
                : theSportsDbMatch
                    .homeTeamLogoUrl,
        awayTeamLogoUrl:
            existing.awayTeamLogoUrl
                    .trim()
                    .isNotEmpty
                ? existing.awayTeamLogoUrl
                : theSportsDbMatch
                    .awayTeamLogoUrl,
        leagueLogoUrl:
            existing.leagueLogoUrl
                    .trim()
                    .isNotEmpty
                ? existing.leagueLogoUrl
                : theSportsDbMatch
                    .leagueLogoUrl,
        isLive:
            existing.isLive ||
                theSportsDbMatch.isLive,
      );
    }

    final List<AppMatch> result =
        merged.values.toList();

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
              second.homeTeam.toLowerCase(),
            );
      },
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
        unique[key] = match;
        continue;
      }

      unique[key] = existing.copyWith(
        homeTeamLogoUrl:
            existing.homeTeamLogoUrl
                    .trim()
                    .isNotEmpty
                ? existing.homeTeamLogoUrl
                : match.homeTeamLogoUrl,
        awayTeamLogoUrl:
            existing.awayTeamLogoUrl
                    .trim()
                    .isNotEmpty
                ? existing.awayTeamLogoUrl
                : match.awayTeamLogoUrl,
        leagueLogoUrl:
            existing.leagueLogoUrl
                    .trim()
                    .isNotEmpty
                ? existing.leagueLogoUrl
                : match.leagueLogoUrl,
        isLive:
            existing.isLive ||
                match.isLive,
      );
    }

    final List<AppMatch> result =
        unique.values.toList();

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

    final String id =
        'sportmonks_${fixture.id}';

    return AppMatch(
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
      aiScore:
          _createTemporaryAiScore(
        sourceId: fixture.id,
        league: fixture.leagueName,
        homeTeam: fixture.homeTeam,
        awayTeam: fixture.awayTeam,
      ),
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

    final int sourceId =
        int.tryParse(event.id) ??
            event.uniqueKey.hashCode;

    return AppMatch(
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
      aiScore:
          _createTemporaryAiScore(
        sourceId: sourceId,
        league: event.leagueName,
        homeTeam: event.homeTeam,
        awayTeam: event.awayTeam,
      ),
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
    );
  }

  /// Ideiglenes, kiszámítható AI-pontszám.
  ///
  /// Nem véletlenszerű, ugyanahhoz a meccshez mindig
  /// ugyanazt az eredményt adja. Később ezt cseréljük le
  /// a valódi forma-, H2H-, gól- és oddselemzésre.
  int _createTemporaryAiScore({
    required int sourceId,
    required String league,
    required String homeTeam,
    required String awayTeam,
  }) {
    final int seed =
        sourceId.abs() +
            league.length * 2 +
            homeTeam.length * 3 +
            awayTeam.length * 5;

    return 65 + seed % 31;
  }

  String _createMatchKey(
    AppMatch match,
  ) {
    final String home =
        _normalizeText(
      match.homeTeam,
    );

    final String away =
        _normalizeText(
      match.awayTeam,
    );

    final String date =
        _formatDate(
      match.matchDate,
    );

    return '$home|$away|$date';
  }

  String _normalizeText(
    String value,
  ) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ő', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ű', 'u')
        .replaceAll('æ', 'ae')
        .replaceAll('ø', 'o')
        .replaceAll('å', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ë', 'e')
        .replaceAll('ï', 'i')
        .replaceAll('ü', 'u')
        .replaceAll(
          RegExp(r'\b(fc|cf|sc|afc|fk|bk)\b'),
          '',
        )
        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
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
        _normalizeDate(first);

    final DateTime normalizedSecond =
        _normalizeDate(second);

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
  final MatchRepositoryResult? repositoryResult;
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
  final MatchRepositoryResult? repositoryResult;

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
