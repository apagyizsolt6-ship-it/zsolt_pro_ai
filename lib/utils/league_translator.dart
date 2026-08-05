// ============================================================================
// Zsolt Pro AI - League & Text Translator Utility
// File: lib/utils/league_translator.dart
// ============================================================================

class LeagueTranslator {
  static String translate(String input) {
    if (input.trim().isEmpty) return input;

    String text = input;

    // Nemzetközi kategóriák előtagjainak tisztítása
    text = text.replaceAll(RegExp(r'^\s*europe:\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^\s*world:\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^\s*international:\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^\s*uefa:\s*', caseSensitive: false), '');

    // UEFA Kupák pontos megnevezése
    text = text.replaceAll(RegExp(r'europa\s+league', caseSensitive: false), 'UEFA Európa Liga');
    text = text.replaceAll(RegExp(r'europa\s+bajnoksag', caseSensitive: false), 'UEFA Európa Liga');
    text = text.replaceAll(RegExp(r'conference\s+league', caseSensitive: false), 'UEFA Konferencia Liga');
    text = text.replaceAll(RegExp(r'conference\s+bajnoksag', caseSensitive: false), 'UEFA Konferencia Liga');
    text = text.replaceAll(RegExp(r'champions\s+league', caseSensitive: false), 'UEFA Bajnokok Ligája');
    text = text.replaceAll(RegExp(r'champions\s+bajnoksag', caseSensitive: false), 'UEFA Bajnokok Ligája');

    // Duplikált UEFA szavak tisztítása
    text = text.replaceAll(RegExp(r'UEFA\s+UEFA', caseSensitive: false), 'UEFA');

    // Szavak fordítása
    text = text.replaceAll(RegExp(r'\bqualification\b', caseSensitive: false), 'Selejtező');
    text = text.replaceAll(RegExp(r'\bqualifying\b', caseSensitive: false), 'Selejtező');
    text = text.replaceAll(RegExp(r'\bcup\b', caseSensitive: false), 'Kupa');

    // Általános League -> Bajnokság fordítás (ha nem UEFA kupa)
    if (!text.contains('Európa Liga') && !text.contains('Konferencia Liga') && !text.contains('Bajnokok Ligája')) {
      text = text.replaceAll(RegExp(r'\bleague\b', caseSensitive: false), 'Bajnokság');
    }

    // Országnevek fordítása
    text = text.replaceAll(RegExp(r'^england:', caseSensitive: false), 'Anglia:');
    text = text.replaceAll(RegExp(r'^germany:', caseSensitive: false), 'Németország:');
    text = text.replaceAll(RegExp(r'^spain:', caseSensitive: false), 'Spanyolország:');
    text = text.replaceAll(RegExp(r'^italy:', caseSensitive: false), 'Olaszország:');
    text = text.replaceAll(RegExp(r'^france:', caseSensitive: false), 'Franciaország:');
    text = text.replaceAll(RegExp(r'^hungary:', caseSensitive: false), 'Magyarország:');
    text = text.replaceAll(RegExp(r'^belarus:', caseSensitive: false), 'Fehéroroszország:');
    text = text.replaceAll(RegExp(r'^faroe islands:', caseSensitive: false), 'Feröer-szigetek:');
    text = text.replaceAll(RegExp(r'^argentina:', caseSensitive: false), 'Argentína:');
    text = text.replaceAll(RegExp(r'^georgia:', caseSensitive: false), 'Grúzia:');
    text = text.replaceAll(RegExp(r'^usa:', caseSensitive: false), 'USA:');
    text = text.replaceAll(RegExp(r'^india:', caseSensitive: false), 'India:');

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
