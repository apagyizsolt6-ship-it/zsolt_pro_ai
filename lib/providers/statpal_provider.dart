// ============================================================================
// Zsolt Pro AI - StatPal Provider / Controller (FTC & UEFA Kupák Teljes Szűrésével)
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

  /// KIZÁRÓLAG AZ ENGEDÉLYEZETT LISTA - Országfüggetlen UEFA Kupákkal (FTC meccsek is)
  bool _isAllowedLeague(String rawCountry, String rawName) {
    final String c = rawCountry.trim().toLowerCase();
    final String n = rawName.trim().toLowerCase();
    final String fullRaw = '$c $n'.toLowerCase();

    // 0. GLOBÁLIS KIZÁRÁSOK (Női, Utánpótlás, Barátságos, Tartalékok)
    if (fullRaw.contains('women') || fullRaw.contains('női') || fullRaw.contains(' w ') || fullRaw.endsWith(' w') ||
        fullRaw.contains('u15') || fullRaw.contains('u16') || fullRaw.contains('u17') || fullRaw.contains('u18') || 
        fullRaw.contains('u19') || fullRaw.contains('u20') || fullRaw.contains('u21') || fullRaw.contains('u23') ||
        fullRaw.contains('youth') || fullRaw.contains('juniors') || fullRaw.contains('nextgen') ||
        fullRaw.contains('friendly') || fullRaw.contains('barátságos') || fullRaw.contains('baratsagos') ||
        fullRaw.contains('reserve') || fullRaw.contains('tartalék') || fullRaw.contains('tartalek')) {
      return false;
    }

    // 1. NEMZETKÖZI KUPÁK (BL, EL, KL) - BÁRMILYEN ORSZÁGNÉV ESETÉN!
    if (n.contains('champions') || n.contains('bajnokok') ||
        n.contains('europa') || n.contains('európa') ||
        n.contains('conference') || n.contains('konferencia') ||
        ((c == 'europe' || c == 'uefa') && n.contains('uefa'))) {
      if (n.contains('concacaf') || n.contains('afc') || n.contains('caf') || n.contains('durand')) {
        return false;
      }
      return true;
    }

    String cleanCountry = rawCountry.replaceAll('_', ' ').trim();
    String cleanName = rawName.trim();
    if (cleanName.toLowerCase().startsWith(cleanCountry.toLowerCase())) {
      cleanName = cleanName.substring(cleanCountry.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
    }
    final full = cleanCountry.isNotEmpty ? '$cleanCountry: $cleanName' : cleanName;
    final h = LeagueTranslator.translate(full).toLowerCase();

    // 2. MAGYARORSZÁG (Csak NB I, NB II, Kupa - NB III kizárva)
    if (h.contains('magyarország')) {
      return (h.contains('nb i.') || h.contains('nb i') || h.contains('nb ii') || h.contains('kupa')) && !h.contains('nb iii');
    }

    // 3. TOP 5 + 2. OSZTÁLY + KUPÁK
    if (h.contains('angol') || c == 'england') {
      return h.contains('premier') || h.contains('championship') || h.contains('league one') || h.contains('league two') || h.contains('kupa') || n.contains('fa cup') || n.contains('efl cup');
    }
    if (h.contains('német') || c == 'germany') {
      return h.contains('bundesliga') || h.contains('2.') || h.contains('kupa') || h.contains('pokal');
    }
    if (h.contains('francia') || c == 'france') {
      return h.contains('ligue 1') || h.contains('ligue 2') || h.contains('kupa');
    }
    if (h.contains('olasz') || c == 'italy') {
      return h.contains('serie a') || h.contains('serie b') || h.contains('kupa');
    }
    if (h.contains('spanyol') || c == 'spain') {
      return h.contains('la liga') || h.contains('segunda') || h.contains('kupa');
    }

    // 4. KÜLFÖLDI LIGÁK (1. és 2. osztályok)
    if ((h.contains('portugália') || c == 'portugal') && (h.contains('primeira') || h.contains('liga 2') || h.contains('segunda'))) return true;
    if ((h.contains('hollandia') || c == 'netherlands') && (h.contains('eredivisie') || h.contains('eerste divisie'))) return true;
    if ((h.contains('belgium') || c == 'belgium') && (h.contains('pro league') || h.contains('challenger pro league'))) return true;
    if ((h.contains('törökország') || c == 'turkey') && (h.contains('super lig') || h.contains('1. lig'))) return true;
    if ((h.contains('svédország') || c == 'sweden') && (h.contains('allsvenskan') || h.contains('superettan'))) return true;
    if ((h.contains('dánia') || c == 'denmark') && (h.contains('superliga') || h.contains('1. division'))) return true;
    if ((h.contains('norvégia') || c == 'norway') && (h.contains('eliteserien') || h.contains('obos-ligaen'))) return true;
    if ((h.contains('svájc') || c == 'switzerland') && (h.contains('szuperbajnokság') || h.contains('super league') || h.contains('challenge league') || h.contains('promotion'))) return true;

    // 5. TOVÁBBI ORSZÁGOK (Kizárólag 1. osztály)
    if (n.contains('usl') || n.contains('liga 2') || n.contains('liga 3') || n.contains('liga 4') ||
        n.contains('pershaya') || n.contains('1. deild') || n.contains('durand') || 
        n.contains('primera nacional') || n.contains('clausura reserve') || n.contains('sub-') ||
        n.contains('division 2') || n.contains('division 3') || n.contains('2. liga') || n.contains('3. liga')) {
      return false;
    }

    const strictFirstDivisionOnly = [
      'cseh', 'czech', 'görög', 'greece', 'ciprus', 'cyprus', 'skócia', 'scotland', 
      'ausztria', 'austria', 'románia', 'romania', 'horvátország', 'croatia', 
      'szlovénia', 'slovenia', 'ukrajna', 'ukraine', 'izrael', 'israel', 'írország', 'ireland', 
      'örményország', 'armenia', 'koszovó', 'kosovo', 'bosznia', 'bosnia', 'lettország', 'latvia', 
      'finnország', 'finland', 'kazahsztán', 'kazakhstan', 'feröer', 'faroe', 'macedónia', 'macedonia', 
      'moldova', 'albánia', 'albania', 'fehéroroszország', 'belarus', 'litvánia', 'lithuania', 
      'málta', 'malta', 'észtország', 'estonia', 'andorra', 'bulgária', 'bulgaria', 
      'wales', 'argentína', 'argentina', 'brazília', 'brazil', 'mexikó', 'mexico', 
      'kolumbia', 'colombia', 'usa', 'united states', 'japán', 'japan', 'kína', 'china', 
      'dél-korea', 'south korea', 'korea', 'irán', 'iran', 'egyiptom', 'egypt', 
      'nigéria', 'nigeria', 'tunézia', 'tunisia', 'katár', 'qatar', 'szaúd-arábia', 'saudi arabia', 
      'fülöp-szigetek', 'philippines', 'india', 'hongkong', 'hong kong', 'szerbia', 'serbia', 
      'ekvador', 'ecuador', 'salvador', 'el salvador', 'fiji', 'georgia', 'grúzia', 'lengyelország', 'poland'
    ];

    for (var item in strictFirstDivisionOnly) {
      if (h.contains(item) || c.contains(item)) {
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
