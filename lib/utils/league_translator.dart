// ===========================================
// Zsolt Pro AI
// Version: v0.4.4
// File: lib/utils/league_translator.dart
// ===========================================

class LeagueTranslator {
  /// Közvetlen szótár a legnépszerűbb bajnokságok pontos magyar nevégre
  static const Map<String, String> _knownLeagues = <String, String>{
    // Magyarország
    'Hungarian NB I': 'Magyarország NB I',
    'Hungarian NB II': 'Magyarország NB II',
    'Hungarian Cup': 'Magyar Kupa',

    // Angol ligák
    'English Premier League': 'Angol Premier League',
    'English League Championship': 'Angol Championship',
    'English FA Cup': 'Angol FA Kupa',
    'English League Cup': 'Angol Ligakupa',

    // Spanyol ligák
    'Spanish La Liga': 'Spanyol La Liga',
    'Spanish Segunda Division': 'Spanyol Segunda Division',
    'Spanish Copa del Rey': 'Spanyol Király-kupa',

    // Olasz ligák
    'Italian Serie A': 'Olasz Serie A',
    'Italian Serie B': 'Olasz Serie B',
    'Italian Coppa Italia': 'Olasz Kupa',

    // Német ligák
    'German Bundesliga': 'Német Bundesliga',
    'German 2. Bundesliga': 'Német 2. Bundesliga',
    'German DFB Pokal': 'Német Kupa',

    // Francia ligák
    'French Ligue 1': 'Francia Ligue 1',
    'French Ligue 2': 'Francia Ligue 2',

    // Nemzetközi
    'UEFA Champions League': 'Bajnokok Ligája',
    'UEFA Europa League': 'Európa Liga',
    'UEFA Conference League': 'Konferencia Liga',
    'UEFA Nations League': 'Nemzetek Ligája',

    // Egyéb népszerű
    'Brazilian Serie A': 'Brazília Serie A',
    'Dutch Eredivisie': 'Holland Eredivisie',
    'Portuguese Primeira Liga': 'Portugál Primeira Liga',
    'Turkish Super Lig': 'Török Süper Lig',
    'Austrian Bundesliga': 'Osztrák Bundesliga',
    'Swiss Super League': 'Svájci Super League',
    'Belgian Pro League': 'Belga Pro League',
  };

  /// Dinamikus országnév-fordító szótár az ismeretlen ligákhoz
  static const Map<String, String> _countryPrefixes = <String, String>{
    'Hungarian': 'Magyarország',
    'English': 'Angol',
    'Spanish': 'Spanyol',
    'Italian': 'Olasz',
    'German': 'Német',
    'French': 'Francia',
    'Brazilian': 'Brazília',
    'Argentine': 'Argentin',
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
    'Croatian': 'Horvát',
    'Serbian': 'Szerb',
    'Romanian': 'Román',
    'Slovakian': 'Szlovák',
    'Ukrainian': 'Ukrán',
  };

  /// Bajnokság nevének magyarosítása
  static String translate(String originalLeagueName) {
    final String trimmed = originalLeagueName.trim();
    if (trimmed.isEmpty) return trimmed;

    // 1. Ha benne van a pontos szótárunkban, azt adjuk vissza
    if (_knownLeagues.containsKey(trimmed)) {
      return _knownLeagues[trimmed]!;
    }

    // 2. Egyébként keressük az országnév előtagot és cseréljük ki
    String translated = trimmed;
    _countryPrefixes.forEach((String englishPrefix, String hungarianPrefix) {
      if (translated.startsWith(englishPrefix)) {
        translated = translated.replaceFirst(englishPrefix, hungarianPrefix);
      }
    });

    return translated;
  }
}
