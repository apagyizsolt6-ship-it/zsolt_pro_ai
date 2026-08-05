// ============================================================================
// Zsolt Pro AI - League & Text Translator Utility (Teljes Országszótár)
// File: lib/utils/league_translator.dart
// ============================================================================

class LeagueTranslator {
  static final Map<String, String> _countryMap = {
    'england': 'Anglia',
    'germany': 'Németország',
    'spain': 'Spanyolország',
    'italy': 'Olaszország',
    'france': 'Franciaország',
    'hungary': 'Magyarország',
    'brazil': 'Brazília',
    'china': 'Kína',
    'ecuador': 'Ekvador',
    'equador': 'Ekvador',
    'estonia': 'Észtország',
    'finland': 'Finnország',
    'israel': 'Izrael',
    'poland': 'Lengyelország',
    'romania': 'Románia',
    'argentina': 'Argentína',
    'belarus': 'Fehéroroszország',
    'faroe islands': 'Feröer-szigetek',
    'georgia': 'Grúzia',
    'usa': 'USA',
    'united states': 'USA',
    'india': 'India',
    'portugal': 'Portugália',
    'netherlands': 'Hollandia',
    'belgium': 'Belgium',
    'turkey': 'Törökország',
    'sweden': 'Svédország',
    'denmark': 'Dánia',
    'norway': 'Norvégia',
    'switzerland': 'Svájc',
    'czech republic': 'Csehország',
    'czech': 'Csehország',
    'greece': 'Görögország',
    'cyprus': 'Ciprus',
    'scotland': 'Skócia',
    'austria': 'Ausztria',
    'croatia': 'Horvátország',
    'slovenia': 'Szlovénia',
    'ukraine': 'Ukrajna',
    'ireland': 'Írország',
    'armenia': 'Örményország',
    'kosovo': 'Koszovó',
    'bosnia': 'Bosznia-Hercegovina',
    'latvia': 'Lettország',
    'kazakhstan': 'Kazahsztán',
    'macedonia': 'Észak-Macedónia',
    'moldova': 'Moldova',
    'albania': 'Albánia',
    'lithuania': 'Litvánia',
    'malta': 'Málta',
    'andorra': 'Andorra',
    'bulgaria': 'Bulgária',
    'wales': 'Wales',
    'mexico': 'Mexikó',
    'colombia': 'Kolumbia',
    'japan': 'Japán',
    'south korea': 'Dél-Korea',
    'korea': 'Dél-Korea',
    'iran': 'Irán',
    'egypt': 'Egyiptom',
    'nigeria': 'Nigéria',
    'tunisia': 'Tunézia',
    'qatar': 'Katár',
    'saudi arabia': 'Szaúd-Arábia',
    'philippines': 'Fülöp-szigetek',
    'hong kong': 'Hongkong',
    'serbia': 'Szerbia',
    'el salvador': 'El Salvador',
    'fiji': 'Fidzsi',
  };

  static String translateCountryName(String rawCountry) {
    final c = rawCountry.trim().toLowerCase();
    if (c.isEmpty || c == 'europe' || c == 'world' || c == 'international' || c == 'uefa') {
      return '';
    }
    return _countryMap[c] ?? (c[0].toUpperCase() + c.substring(1));
  }

  static String translate(String input) {
    if (input.trim().isEmpty) return input;

    String text = input;

    // Nemzetközi kategóriák tisztítása
    text = text.replaceAll(RegExp(r'^\s*europe:\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^\s*world:\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^\s*international:\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^\s*uefa:\s*', caseSensitive: false), '');

    // Szavak és Kupák fordítása
    text = text.replaceAll(RegExp(r'\bqualification\b', caseSensitive: false), 'Selejtező');
    text = text.replaceAll(RegExp(r'\bqualifying\b', caseSensitive: false), 'Selejtező');
    text = text.replaceAll(RegExp(r'\bestonian kupa\b', caseSensitive: false), 'Észt Kupa');
    text = text.replaceAll(RegExp(r'\bpolish kupa\b', caseSensitive: false), 'Lengyel Kupa');
    text = text.replaceAll(RegExp(r'\bromanian kupa\b', caseSensitive: false), 'Román Kupa');
    text = text.replaceAll(RegExp(r'\bcupa\b', caseSensitive: false), 'Kupa');
    text = text.replaceAll(RegExp(r'\bcup\b', caseSensitive: false), 'Kupa');

    if (!text.contains('Európa Liga') && !text.contains('Konferencia Liga') && !text.contains('Bajnokok Ligája')) {
      text = text.replaceAll(RegExp(r'\bleague\b', caseSensitive: false), 'Bajnokság');
    }

    return text.trim();
  }

  static String translateStatus(String rawStatus) {
    final status = rawStatus.trim().toUpperCase();
    if (status == 'NS' || status == 'NOT STARTED') return 'Kezdés';
    if (status == 'FT' || status == 'FINISHED') return 'Vége';
    if (status == 'HT' || status == 'HALFTIME') return 'Félidő';
    if (status == 'AET') return 'Hosszabbítás után';
    if (status == 'PEN') return 'Büntetőkkel';
    if (status == 'POSTP' || status == 'POSTPONED') return 'Elhalasztva';
    if (status == 'CANC' || status == 'CANCELLED') return 'Törölve';
    if (status.contains('MIN') || RegExp(r'^\d+$').hasMatch(status)) return '$status\'';
    return status;
  }

  static String formatMatchTime(String rawTime) {
    if (rawTime.contains('T')) {
      try {
        final parsed = DateTime.parse(rawTime).toLocal();
        final hour = parsed.hour.toString().padLeft(2, '0');
        final minute = parsed.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } catch (_) {}
    }
    return rawTime;
  }
}
