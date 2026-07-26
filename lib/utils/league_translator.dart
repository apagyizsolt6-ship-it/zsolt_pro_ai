// ===========================================
// Zsolt Pro AI
// Version: v0.4.5
// File: lib/utils/league_translator.dart
// ===========================================

class LeagueTranslator {
  static const Map<String, String> _knownLeagues = <String, String>{
    'Hungarian NB I': 'Magyarország NB I',
    'Hungarian NB II': 'Magyarország NB II',
    'Hungarian NB III Northeast': 'Magyarország NB III - Északkelet',
    'Hungarian NB III Northwest': 'Magyarország NB III - Északnyugat',
    'Hungarian NB III Southeast': 'Magyarország NB III - Délkelet',
    'Hungarian NB III Southwest': 'Magyarország NB III - Délnyugat',
    'Hungarian Cup': 'Magyar Kupa',
    'English Premier League': 'Angol Premier League',
    'English League Championship': 'Angol Championship',
    'English FA Cup': 'Angol FA Kupa',
    'Spanish La Liga': 'Spanyol La Liga',
    'Spanish Segunda Division': 'Spanyol Segunda Division',
    'Italian Serie A': 'Olasz Serie A',
    'German Bundesliga': 'Német Bundesliga',
    'French Ligue 1': 'Francia Ligue 1',
    'UEFA Champions League': 'Bajnokok Ligája',
    'UEFA Europa League': 'Európa Liga',
    'UEFA Conference League': 'Konferencia Liga',
    'Brazilian Serie A': 'Brazília Serie A',
    'Argentinian Primera Division': 'Argentin Primera Division',
    'Argentinian Primera C': 'Argentin Primera C',
    'Peruvian Copa de la Liga': 'Perui Ligakupa',
    'Kyrgyz Premier League': 'Kirgiz Premier League',
  };

  static const Map<String, String> _countryPrefixes = <String, String>{
    'Hungarian': 'Magyarország',
    'English': 'Angol',
    'Spanish': 'Spanyol',
    'Italian': 'Olasz',
    'German': 'Német',
    'French': 'Francia',
    'Brazilian': 'Brazília',
    'Argentinian': 'Argentin',
    'Argentine': 'Argentin',
    'Peruvian': 'Perui',
    'Kyrgyz': 'Kirgiz',
    'Australia': 'Ausztrál',
    'Australian': 'Ausztrál',
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

  static String translate(String originalLeagueName) {
    final String trimmed = originalLeagueName.trim();
    if (trimmed.isEmpty) return trimmed;

    if (_knownLeagues.containsKey(trimmed)) {
      return _knownLeagues[trimmed]!;
    }

    String translated = trimmed;
    _countryPrefixes.forEach((String englishPrefix, String hungarianPrefix) {
      if (translated.startsWith(englishPrefix)) {
        translated = translated.replaceFirst(englishPrefix, hungarianPrefix);
      }
    });

    return translated;
  }
}
