// ===========================================
// Zsolt Pro AI - Központi Fordítási Központ
// Version: v1.0.3 (Teljesen Tiszta & Hibátlan Magyarítás)
// File: lib/utils/league_translator.dart
// ===========================================

class LeagueTranslator {
  static const Map<String, String> _knownLeagues = <String, String>{
    'Hungarian NB I': 'Magyarország NB I',
    'Hungarian NB II': 'Magyarország NB II',
    'Hungarian Cup': 'Magyar Kupa',
    'English Premier League': 'Angol Premier Bajnokság',
    'English League Championship': 'Angol Championship',
    'Spanish La Liga': 'Spanyol La Liga',
    'Italian Serie A': 'Olasz Serie A',
    'German Bundesliga': 'Német Bundesliga',
    'French Ligue 1': 'Francia Ligue 1',
    'UEFA Champions League': 'Bajnokok Ligája',
    'UEFA Europa League': 'Európa Liga',
    'UEFA Conference League': 'Konferencia Liga',
  };

  static String translateStatus(String rawStatus) {
    final status = rawStatus.toUpperCase().trim();
    if (status == 'FT' || status == 'FINISHED' || status == 'AET') return 'Vége';
    if (status == 'NS' || status == 'NOT STARTED' || status == 'TIMED') return 'Kezdés';
    if (status == 'HT' || status == 'HALF TIME') return 'Félidő';
    if (status == 'LIVE' || status == 'IN PLAY' || status == '1H' || status == '2H') return 'Élő';
    if (status == 'PEN' || status == 'ET') return 'Hosszabbítás / Tizenegyesek';
    if (status.contains('POSTP')) return 'Elhalasztva';
    if (status.contains('CANCL') || status.contains('CANC')) return 'Törölve';
    if (status.contains('SUSP')) return 'Felfüggesztve';
    return rawStatus;
  }

  static String formatMatchTime(String rawTime) {
    if (rawTime.isEmpty) return '';
    if (rawTime.contains(':') && rawTime.length <= 5) {
      final parts = rawTime.split(':');
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        int adjustedHour = (hour + 2) % 24;
        return '${adjustedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
    }
    return rawTime;
  }

  /// Országnevek pontos, tiszta szótára (kisbetűs kulcsokkal a biztonság kedvéért)
  static const Map<String, String> _countries = <String, String>{
    'germany': 'Németország',
    'hungary': 'Magyarország',
    'england': 'Angol',
    'spain': 'Spanyol',
    'italy': 'Olasz',
    'france': 'Francia',
    'netherlands': 'Holland',
    'portugal': 'Portugál',
    'turkey': 'Török',
    'austria': 'Osztrák',
    'switzerland': 'Svájc',
    'belgium': 'Belga',
    'greece': 'Görög',
    'czech republic': 'Csehország',
    'czech_republic': 'Csehország',
    'poland': 'Lengyelország',
    'denmark': 'Dánia',
    'sweden': 'Svédország',
    'norway': 'Norvégia',
    'finland': 'Finnország',
    'croatia': 'Horvátország',
    'serbia': 'Szerbia',
    'romania': 'Románia',
    'slovakia': 'Szlovákia',
    'ukraine': 'Ukrajna',
    'russia': 'Oroszország',
    'belarus': 'Fehéroroszország',
    'bulgaria': 'Bulgária',
    'ireland': 'Írország',
    'scotland': 'Skócia',
    'wales': 'Wales',
    'iceland': 'Izland',
    'slovenia': 'Szlovénia',
    'bosnia': 'Bosznia-Hercegovina',
    'albania': 'Albánia',
    'macedonia': 'Macedónia',
    'moldova': 'Moldova',
    'georgia': 'Grúzia',
    'armenia': 'Örményország',
    'azerbaijan': 'Azerbajdzsán',
    'cyprus': 'Ciprus',
    'malta': 'Málta',
    'estonia': 'Észtország',
    'latvia': 'Lettország',
    'lithuania': 'Litvánia',
    'luxembourg': 'Luxemburg',
    'faroe islands': 'Feröer-szigetek',
    'faroe_islands': 'Feröer-szigetek',

    'brazil': 'Brazília',
    'argentina': 'Argentína',
    'peru': 'Peru',
    'bolivia': 'Bolívia',
    'ecuador': 'Ecuador',
    'colombia': 'Kolumbia',
    'chile': 'Chile',
    'uruguay': 'Uruguay',
    'paraguay': 'Paraguay',
    'venezuela': 'Venezuela',
    'mexico': 'Mexikó',
    'costa rica': 'Costa Rica',
    'costa_rica': 'Costa Rica',
    'guatemala': 'Guatemala',
    'honduras': 'Honduras',
    'panama': 'Panama',
    'el salvador': 'Salvador',
    'el_salvador': 'Salvador',
    'jamaica': 'Jamaica',

    'usa': 'Egyesült Államok',
    'canada': 'Kanada',
    'australia': 'Ausztrália',
    'new zealand': 'Új-Zéland',

    'south korea': 'Dél-Korea',
    'south_korea': 'Dél-Korea',
    'japan': 'Japán',
    'china': 'Kína',
    'saudi arabia': 'Szaúd-Arábia',
    'kazakhstan': 'Kazahsztán',
    'kyrgyzstan': 'Kirgizisztán',
    'uzbekistan': 'Üzbegisztán',
    'iran': 'Irán',
    'iraq': 'Irak',
    'qatar': 'Katár',
    'india': 'India',
    'thailand': 'Thaiföld',
    'vietnam': 'Vietnám',
    'indonesia': 'Indonézia',
    'malaysia': 'Malajzia',

    'egypt': 'Egyiptom',
    'morocco': 'Marokkó',
    'tunisia': 'Tunézia',
    'algeria': 'Algéria',
    'south africa': 'Dél-Afrika',
    'nigeria': 'Nigéria',
    'ghana': 'Ghána',
    'senegal': 'Szenegál',
    'cameroon': 'Kamerun',
  };

  static const Map<String, String> _commonTerms = <String, String>{
    'Premier League': 'Premier Bajnokság',
    'Super League': 'Szuperbajnokság',
    'First League': 'I. Bajnokság',
    'Second League': 'II. Bajnokság',
    'Third League': 'III. Bajnokság',
    'League One': 'Bajnokság I',
    'League Two': 'Bajnokság II',
    'League': 'Bajnokság',
    'Division': 'Divízió',
    'Primera Division': 'Primera División',
    'Segunda Division': 'Segunda División',
    'Cup': 'Kupa',
    'Friendlies': 'Barátságos mérkőzések',
    'Championship': 'Bajnokság',
    'Play Offs': 'Rájátszás',
    'Group Stage': 'Csoportkör',
  };

  static String translate(String originalLeagueName) {
    String trimmed = originalLeagueName.trim();
    if (trimmed.isEmpty) return trimmed;

    if (_knownLeagues.containsKey(trimmed)) {
      return _knownLeagues[trimmed]!;
    }

    // Szétbontjuk országra és ligára, ha van benne kettőspont
    String countryPart = '';
    String leaguePart = trimmed;

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      countryPart = parts[0].trim();
      leaguePart = parts.skip(1).join(':').trim();
    }

    // Ha a ligarészben benne van az ország is megint, kiszűrjük
    if (leaguePart.toLowerCase().startsWith(countryPart.toLowerCase())) {
      leaguePart = leaguePart.substring(countryPart.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
    }

    // Ország fordítása a szótárból
    String translatedCountry = countryPart;
    final lowerCountry = countryPart.toLowerCase().replaceAll(' ', '_');
    if (_countries.containsKey(lowerCountry)) {
      translatedCountry = _countries[lowerCountry]!;
    } else {
      // Ha esetleg nem találná, csak csinálunk egy csinosabb formátumot
      translatedCountry = countryPart.replaceAll('_', ' ');
    }

    // Ligatípusok fordítása
    String translatedLeague = leaguePart;
    _commonTerms.forEach((String eng, String hun) {
      if (translatedLeague.contains(eng)) {
        translatedLeague = translatedLeague.replaceAll(eng, hun);
      }
    });

    if (translatedCountry.isEmpty) {
      return translatedLeague;
    }

    return '$translatedCountry: $translatedLeague';
  }
}
