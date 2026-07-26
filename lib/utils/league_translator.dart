// ===========================================
// Zsolt Pro AI
// Version: v0.4.8
// File: lib/utils/league_translator.dart
// ===========================================

class LeagueTranslator {
  /// Fixen definiált konkrét liganevek
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
  };

  /// A Föld összes futballal rendelkező országának és régiójának magyarosítója
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
    'Emirati': 'EIR-beli',
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
    'Primera Division': 'Primera División',
    'Segunda Division': 'Segunda División',
    'Copa de la Liga': 'Ligakupa',
    'Cup': 'Kupa',
    'Friendlies': 'Barátságos mérkőzések',
    'Championship': 'Bajnokság',
  };

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

    // 3. Gyakori angol kifejezések és "League" cseréje
    _commonTerms.forEach((String englishTerm, String hungarianTerm) {
      if (translated.contains(englishTerm)) {
        translated = translated.replaceAll(englishTerm, hungarianTerm);
      }
    });

    return translated;
  }
}
