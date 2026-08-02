// ===========================================
// Zsolt Pro AI - Központi Fordítási Központ
// Version: v1.0.2 (StatPal Speciális Országnevekkel Bővítve)
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

  static const Map<String, String> _countryPrefixes = <String, String>{
    // StatPal alulvonásos és speciális formátumok kezelése először
    'South_korea': 'Dél-Korea',
    'Faroe_islands': 'Feröer-szigetek',
    'El_salvador': 'Salvador',
    'Costa_rica': 'Costa Rica',
    'Czech_republic': 'Csehország',
    
    // Alap országnevek
    'Hungarian': 'Magyarország',
    'English': 'Angol',
    'Spanish': 'Spanyol',
    'Italian': 'Olasz',
    'German': 'Német',
    'French': 'Francia',
    'Dutch': 'Holland',
    'Portuguese': 'Portugál',
    'Turkish': 'Török',
    'Austrian': 'Osztrák',
    'Swiss': 'Svájci',
    'Belgian': 'Belga',
    'Greek': 'Görög',
    'Czech': 'Cseh',
    'Polish': 'Lengyel',
    'Danish': 'Dán',
    'Swedish': 'Svéd',
    'Norwegian': 'Norvég',
    'Finnish': 'Finn',
    'Croatian': 'Horvát',
    'Serbian': 'Szerb',
    'Romanian': 'Román',
    'Slovakian': 'Szlovák',
    'Slovak': 'Szlovák',
    'Ukrainian': 'Ukrán',
    'Russian': 'Orosz',
    'Belarusian': 'Fehérorosz',
    'Bulgarian': 'Bolgár',
    'Irish': 'Ír',
    'Scottish': 'Skót',
    'Welsh': 'Walesi',
    'Icelandic': 'Izlandi',
    'Slovenian': 'Szlovén',
    'Bosnian': 'Bosnyák',
    'Albanian': 'Albán',
    'Macedonian': 'Macedón',
    'Moldovan': 'Moldáv',
    'Georgian': 'Grúz',
    'Armenian': 'Örmény',
    'Azerbaijani': 'Azeri',
    'Cypriot': 'Ciprusi',
    'Maltese': 'Máltai',
    'Estonian': 'Észt',
    'Latvian': 'Lett',
    'Lithuanian': 'Litván',
    'Luxembourg': 'Luxemburgi',
    'Faroe Islands': 'Feröer',

    'Brazilian': 'Brazília',
    'Argentinian': 'Argentin',
    'Argentine': 'Argentin',
    'Peruvian': 'Perui',
    'Bolivian': 'Bolíviai',
    'Ecuadorian': 'Ecuadori',
    'Colombian': 'Kolumbiai',
    'Chilean': 'Chilei',
    'Uruguayan': 'Uruguayi',
    'Paraguayan': 'Paraguayi',
    'Venezuelan': 'Venezuelai',
    'Mexican': 'Mexikói',
    'Costa Rican': 'Costa Rica-i',
    'Guatemalan': 'Guatemalai',
    'Honduran': 'Hondurasi',
    'Panamanian': 'Panamai',
    'Jamaican': 'Jamaicai',

    'American': 'Amerikai',
    'Canadian': 'Kanadai',
    'Australia': 'Ausztrál',
    'Australian': 'Ausztrál',
    'New Zealand': 'Új-zélandi',

    'Korean': 'Koreai',
    'Japanese': 'Japán',
    'Chinese': 'Kínai',
    'Saudi': 'Szaúdi',
    'Kazakhstan': 'Kazah',
    'Kazakhstani': 'Kazah',
    'Kyrgyz': 'Kirgiz',
    'Uzbek': 'Üzbég',
    'Iranian': 'Iráni',
    'Iraqi': 'Iraki',
    'Qatari': 'Katari',
    'Emirati': 'Emírségekbeli',
    'Indian': 'Indiai',
    'Thai': 'Thaiföldi',
    'Vietnamese': 'Vietnámi',
    'Indonesian': 'Indonéz',
    'Malaysian': 'Maláj',

    'Egyptian': 'Egyiptomi',
    'Moroccan': 'Marokkói',
    'Tunisian': 'Tunéziai',
    'Algerian': 'Algériai',
    'South African': 'Dél-afrikai',
    'Nigerian': 'Nigériai',
    'Ghanaian': 'Ghánai',
    'Senegalese': 'Szenegáli',
    'Cameroonian': 'Kameruni',
    'Ivory Coast': 'Elefántcsontparti',
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

    // Duplikációk szűrése (pl. "Costa Rica: Costa Rica: ...")
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        final p0 = parts[0].trim().toLowerCase();
        final p1 = parts[1].trim().toLowerCase();
        if (p0 == p1 || p1.contains(p0)) {
          trimmed = parts.skip(1).join(':').trim();
        }
      }
    }

    String translated = trimmed;

    _countryPrefixes.forEach((String englishPrefix, String hungarianPrefix) {
      if (translated.startsWith(englishPrefix)) {
        translated = translated.replaceFirst(englishPrefix, hungarianPrefix);
      }
    });

    _commonTerms.forEach((String englishTerm, String hungarianTerm) {
      if (translated.contains(englishTerm)) {
        translated = translated.replaceAll(englishTerm, hungarianTerm);
      }
    });

    return translated;
  }
}
