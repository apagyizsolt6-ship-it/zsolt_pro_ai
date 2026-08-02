// ============================================================================
// Zsolt Pro AI - StatPal Provider / Controller (Szigorú Pozitív Listás Szűrés)
// File: lib/providers/statpal_provider.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import '../services/statpal_service.dart';
import '../models/statpal_models.dart';
import '../utils/league_translator.dart';

class StatPalProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<StatLeague> _leagues = [];
  List<StatLeague> get leagues => _leagues;

  List<StatMatch> _liveMatches = [];
  List<StatMatch> get liveMatches => _liveMatches;

  List<Map<String, dynamic>> _rawLiveMatchesGroups = [];
  List<Map<String, dynamic>> get rawLiveMatchesGroups => _rawLiveMatchesGroups;

  List<StatStandingTeam> _standings = [];
  List<StatStandingTeam> get standings => _standings;

  StatPrediction? _currentPrediction;
  StatPrediction? get currentPrediction => _currentPrediction;

  /// Szigorú, tételes engedélyezési lista (Csak a füzetedben szereplő ligák jelenhetnek meg)
  bool _isAllowedLeague(String rawCountry, String rawName) {
    String cleanCountry = rawCountry.replaceAll('_', ' ');
    String cleanName = rawName;
    if (cleanName.toLowerCase().startsWith(cleanCountry.toLowerCase())) {
      cleanName = cleanName.substring(cleanCountry.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
    }
    final full = cleanCountry.isNotEmpty ? '$cleanCountry: $cleanName' : cleanName;
    final h = LeagueTranslator.translate(full).toLowerCase();

    // 1. NEMZETKÖZI KUPÁK (Bajnokok Ligája, Európa Liga, Konferencia Liga)
    if (h.contains('bajnokok ligája') || h.contains('európa liga') || h.contains('konferencia liga')) {
      return true;
    }

    // 2. MAGYARORSZÁG (NB I, NB II, NB III, Magyar Kupa)
    if (h.contains('magyarország')) {
      return h.contains('nb i.') || h.contains('nb i') || h.contains('nb ii') || h.contains('nb iii') || h.contains('kupa');
    }

    // 3. TOP 5 + 2. OSZTÁLY + KUPÁK
    // Anglia: Premier Liga, Championship, League One, League Two, Kupa
    if (h.contains('angol')) {
      return h.contains('premier') || h.contains('championship') || h.contains('league one') || h.contains('league two') || h.contains('kupa');
    }
    // Németország: Bundesliga, 2. Bundesliga, Kupa / Pokal
    if (h.contains('német')) {
      return h.contains('bundesliga') || h.contains('2. bundesliga') || h.contains('kupa') || h.contains('pokal');
    }
    // Franciaország: Ligue 1, Ligue 2, Kupa
    if (h.contains('francia')) {
      return h.contains('ligue 1') || h.contains('ligue 2') || h.contains('kupa');
    }
    // Olaszország: Serie A, Serie B, Kupa
    if (h.contains('olasz')) {
      return h.contains('serie a') || h.contains('serie b') || h.contains('kupa');
    }
    // Spanyolország: La Liga, Segunda Division, Kupa
    if (h.contains('spanyol')) {
      return h.contains('la liga') || h.contains('segunda') || h.contains('kupa');
    }

    // 4. KÜLFÖLDI LIGÁK (A füzeted alapján: 1. osztályok + specifikus 2. osztályok)
    // Portugália (1. és 2. osztály)
    if (h.contains('portugália')) {
      return h.contains('primeira') || h.contains('liga 2') || h.contains('segunda');
    }
    // Hollandia (1. és 2. osztály)
    if (h.contains('hollandia')) {
      return h.contains('eredivisie') || h.contains('eerste divisie');
    }
    // Belgium (1. és 2. osztály)
    if (h.contains('belgium')) {
      return h.contains('pro league') || h.contains('challenger pro league');
    }
    // Törökország (1. és 2. osztály)
    if (h.contains('törökország')) {
      return h.contains('super lig') || h.contains('1. lig');
    }

    // Egyéb országok, ahol CSAK az 1. osztály engedélyezett (a képeid és a füzet alapján):
    const strictFirstDivisionOnly = [
      'cseh', 'görög', 'dánia', 'norvégia: eliteserien', 'svájc: szuperbajnokság', 
      'ciprus', 'svédország: allsvenskan', 'skócia', 'ausztria', 'románia', 
      'horvátország', 'szlovénia', 'ukrajna', 'izrael', 'írország', 
      'örményország', 'koszovó', 'bosznia', 'lettország', 'finnország', 
      'kazahsztán', 'feröer', 'macedónia', 'moldova', 'albánia', 'fehéroroszország', 
      'litvánia', 'málta', 'észtország', 'andorra', 'bulgária', 'wales', 
      'argentína: liga profesional', 'brazília: brasileiro', 'mexikó: liga mx', 
      'kolumbia', 'usa', 'japán', 'kína', 'dél-korea', 'irán', 'egyiptom', 
      'nigéria', 'tunézia', 'katár', 'szaúd-arábia', 'fülöp-szigetek', 'india', 
      'hongkong', 'szerbia', 'ekvador', 'salvador', 'fiji', 'georgia'
    ];

    for (var item in strictFirstDivisionOnly) {
      if (h.contains(item)) {
        return true;
      }
    }

    return false;
  }

  /// Adatok betöltése / frissítése
  Future<void> loadInitialData({DateTime? selectedDate, int offset = 0}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await StatPalService.instance.initialize();

      if (!StatPalService.instance.hasApiKey) {
        _errorMessage = 'Nincs beállítva StatPal API kulcs!';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final rawLeagues = await StatPalService.instance.fetchLeagues();
      _leagues = rawLeagues
          .map((json) => StatLeague.fromJson(json))
          .where((league) => _isAllowedLeague(league.country, league.name))
          .toList();

      int calculatedOffset = offset;
      if (selectedDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        calculatedOffset = target.difference(today).inDays;
      }

      final rawLive = await StatPalService.instance.fetchLiveMatches(offset: calculatedOffset);

      _rawLiveMatchesGroups = rawLive.where((leagueGroup) {
        final leagueName = leagueGroup['name']?.toString() ?? '';
        final leagueCountry = leagueGroup['country']?.toString() ?? '';
        return _isAllowedLeague(leagueCountry, leagueName);
      }).toList();

      _liveMatches = [];
      for (var leagueGroup in _rawLiveMatchesGroups) {
        if (leagueGroup['match'] is List) {
          for (var matchJson in leagueGroup['match']) {
            _liveMatches.add(StatMatch.fromJson(matchJson));
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Hiba történt az adatok betöltése közben: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStandings(String leagueId, {String? season}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await StatPalService.instance.fetchStandings(leagueId: leagueId, season: season);
      if (data != null && data['table'] is List) {
        _standings = (data['table'] as List)
            .map((item) => StatStandingTeam.fromJson(item))
            .toList();
      } else {
        _standings = [];
      }
    } catch (e) {
      _errorMessage = 'Hiba a tabella lekérésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPrediction(String matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await StatPalService.instance.fetchMatchPrediction(matchId: matchId);
      if (data != null) {
        _currentPrediction = StatPrediction.fromJson(data);
      } else {
        _currentPrediction = null;
      }
    } catch (e) {
      _errorMessage = 'Hiba az előrejelzés lekérésekor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
