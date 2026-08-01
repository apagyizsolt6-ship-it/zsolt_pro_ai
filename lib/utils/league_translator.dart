// ===========================================
// Zsolt Pro AI - Központi Fordítási Központ
// Version: v1.0.1 (Teljes körű fordító csomag + Időbélyeg formázó)
// File: lib/utils/league_translator.dart
// ===========================================

class LeagueTranslator {
  /// Fixen definiált konkrét ligakifejezések és nevek
  static const Map<String, String> _knownLeagues = <String, String>{
    // Magyarország
    'Hungarian NB I': 'Magyarország NB I',
    'Hungarian NB II': 'Magyarország NB II',
    'Hungarian NB III Northeast': 'Magyarország NB III - Északkelet',
    'Hungarian NB III Northwest': 'Magyarország NB III - Északnyugat',
    'Hungarian NB III Southeast': 'Magyarország NB III - Délkelet',
    'Hungarian NB III Southwest': 'Magyarország NB III - Délnyugat',
    'Hungarian Cup': 'Magyar Kupa',

    // Kiemelt nemzetközi & Top ligák
    'English Premier League': 'Angol Premier Bajnokság',
    'English League Championship': 'Angol Championship',
    'Spanish La Liga': 'Spanyol La Liga',
    'Italian Serie A': 'Olasz Serie A',
    'German Bundesliga': 'Német Bundesliga',
    'French Ligue 1': 'Francia Ligue 1',
    'UEFA Champions League': 'Bajnokok Ligája',
    'UEFA Europa League': 'Európa Liga',
    'UEFA Conference League': 'Konferencia Liga',
    'American Major League Soccer': 'Amerikai MLS',
    'International Friendlies': 'Nemzetközi Barátságos',
    'Club Friendlies': 'Klub Barátságos Mérkőzések',
  };

  /// Meccs státuszok teljes körű fordítása
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

  /// Pontos időzóna-korrekció (UTC -> Helyi magyar idő)
  static String formatMatchTime(String rawTime) {
    if (rawTime.isEmpty) return '';
    
    if (rawTime.contains(':') && rawTime.length <= 5) {
      final parts = rawTime.split(':');
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      
      if (hour != null && minute != null) {
        int adjustedHour = (hour + 2) % 24;
        final formattedHour = adjustedHour.toString().padLeft(2, '0');
        final formattedMinute = minute.toString().padLeft(2, '0');
        return '$formattedHour:$formattedMinute';
      }
    }
    
    return rawTime;
  }

  /// Országok és régiók magyarosító szótára
  static const Map<String, String> _countryPrefixes = <String, String>{
    // Európa
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
    'Faroe Islands': 'Feröeri',

    // Dél- és Közép-Amerika
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

    // Észak-Amerika & Ausztrália
    'American': 'Amerikai',
    'Canadian': 'Kanadai',
    'Australia': 'Ausztrál',
    'Australian': 'Ausztrál',
    'New Zealand': 'Új-zélandi',

    // Ázsia & Közel-Kelet
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

    // Afrika
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

  /// Gyakori angol kifejezések és ligatípusok fordítása
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
    'Copa de la Liga': 'Ligakupa',
    'Cup': 'Kupa',
    'Friendlies': 'Barátságos mérkőzések',
    'Championship': 'Bajnokság',
    'Play Offs': 'Rájátszás',
    'Group Stage': 'Csoportkör',
  };

  /// Fő fordító metódus ligákhoz és bajnokságokhoz
  static String translate(String originalLeagueName) {
    final String trimmed = originalLeagueName.trim();
    if (trimmed.isEmpty) return trimmed;

    // 1. Pontos szótári egyezés
    if (_knownLeagues.containsKey(trimmed)) {
      return _knownLeagues[trimmed]!;
    }

    String translated = trimmed;

    // 2. Országnév cseréje
    _countryPrefixes.forEach((String englishPrefix, String hungarianPrefix) {
      if (translated.contains(englishPrefix)) {
        translated = translated.replaceAll(englishPrefix, hungarianPrefix);
      }
    });

    // 3. Gyakori angol kifejezések cseréje
    _commonTerms.forEach((String englishTerm, String hungarianTerm) {
      if (translated.contains(englishTerm)) {
        translated = translated.replaceAll(englishTerm, hungarianTerm);
      }
    });

    return translated;
  }
}
