// ============================================================================
// Zsolt Pro AI - StatPal Dashboard & Szigorú Fehérlistás Ligaszűrés
// File: lib/screens/statpal_dashboard_screen.dart
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/statpal_provider.dart';
import '../models/statpal_models.dart';
import '../widgets/day_selector.dart';
import '../utils/league_translator.dart';
import 'match_detail_screen.dart';

class StatPalHelper {
  static String translateStatus(String rawStatus) {
    return LeagueTranslator.translateStatus(rawStatus);
  }

  static String formatMatchTime(String rawTime) {
    return LeagueTranslator.formatMatchTime(rawTime);
  }

  static String translateCountry(String rawCountry) {
    return LeagueTranslator.translate(rawCountry);
  }

  static String formatLeagueHeader(String country, String name) {
    String cleanCountry = country.replaceAll('_', ' ');
    String cleanName = name;
    if (cleanName.toLowerCase().startsWith(cleanCountry.toLowerCase())) {
      cleanName = cleanName.substring(cleanCountry.length).replaceAll(RegExp(r'^[:\s]+'), '').trim();
    }
    final full = cleanCountry.isNotEmpty ? '$cleanCountry: $cleanName' : cleanName;
    return LeagueTranslator.translate(full);
  }

  /// Szigorú fehérlista a füzeted alapján – CSAK EZEK jelenhetnek meg
  static bool isAllowedLeague(String translatedHeader) {
    final h = translatedHeader.toLowerCase();

    // 1. Nemzetközi Kupák (Bajnokok Ligája, Európa Liga, Konferencia Liga)
    if (h.contains('bajnokok ligája') || h.contains('európa liga') || h.contains('konferencia liga')) {
      return true;
    }

    // 2. Magyarország (NB I, NB II, NB III, Kupa)
    if (h.contains('magyarország')) {
      if (h.contains('nb i.') || h.contains('nb i') || h.contains('nb ii') || h.contains('nb iii') || h.contains('kupa')) {
        return true;
      }
      return false;
    }

    // 3. Top 5 Ligák + 2. osztály + Kupák
    if (h.contains('angol')) {
      if (h.contains('premier') || h.contains('championship') || h.contains('league one') || h.contains('league two') || h.contains('kupa')) {
        return true;
      }
      return false;
    }
    if (h.contains('német')) {
      if (h.contains('bundesliga') || h.contains('2.') || h.contains('kupa') || h.contains('pokal')) {
        return true;
      }
      return false;
    }
    if (h.contains('francia')) {
      if (h.contains('ligue 1') || h.contains('ligue 2') || h.contains('kupa')) {
        return true;
      }
      return false;
    }
    if (h.contains('olasz')) {
      if (h.contains('serie a') || h.contains('serie b') || h.contains('kupa')) {
        return true;
      }
      return false;
    }
    if (h.contains('spanyol')) {
      if (h.contains('la liga') || h.contains('segunda') || h.contains('kupa')) {
        return true;
      }
      return false;
    }

    // 4. Egyéb országok (A füzeted alapján csak a megjelöltek)
    // Portugália (1. és 2. osztály)
    if (h.contains('portugália') && (h.contains('primeira') || h.contains('liga 2') || h.contains('2.') || h.contains('segunda'))) return true;
    // Hollandia (1. és 2. osztály)
    if (h.contains('hollandia') && (h.contains('eredivisie') || h.contains('eerste divisie') || h.contains('2.'))) return true;
    // Belgium (1. és 2. osztály)
    if (h.contains('belgium') && (h.contains('pro league') || h.contains('challenger pro league') || h.contains('2.'))) return true;
    // Törökország (1. és 2. osztály)
    if (h.contains('törökország') && (h.contains('super lig') || h.contains('1. lig') || h.contains('2.'))) return true;

    // Egyéb országok, ahol csak az 1. osztály (vagy a megadottak) kellenek:
    const strictFirstDivisionCountries = [
      'cseh', 'görög', 'dánia', 'norvégia', 'svájc', 'ciprus', 'svédország', 
      'skócia', 'ausztria', 'románia', 'horvátország', 'szlovénia', 'ukrajna', 
      'izrael', 'írország', 'örményország', 'koszovó', 'bosznia', 'lettország', 
      'finnország', 'kazahsztán', 'feröer', 'macedónia', 'moldova', 'albánia', 
      'fehéroroszország', 'litvánia', 'málta', 'észtország', 'andorra', 'bulgária', 
      'wales', 'argentína', 'brazília', 'mexikó', 'kolumbia', 'usa', 'japán', 
      'kína', 'dél-korea', 'irán', 'egyiptom', 'nigéria', 'tunézia', 'katár', 
      'szaúd-arábia', 'fülöp-szigetek', 'india', 'hongkong', 'szerbia', 'ekvador', 
      'salvador', 'fiji', 'georgia'
    ];

    for (var c in strictFirstDivisionCountries) {
      if (h.contains(c)) {
        return true;
      }
    }

    return false;
  }
}

class StatPalDashboardScreen extends StatelessWidget {
  const StatPalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatPalProvider()..loadInitialData(offset: 0),
      child: const _StatPalDashboardView(),
    );
  }
}

class _StatPalDashboardView extends StatefulWidget {
  const _StatPalDashboardView();

  @override
  State<_StatPalDashboardView> createState() => _StatPalDashboardViewState();
}

class _StatPalDashboardViewState extends State<_StatPalDashboardView> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _matchSearchController = TextEditingController();
  final TextEditingController _leagueSearchController = TextEditingController();
  
  bool _hasKey = false;
  bool _showSettings = false;
  int _selectedDayIndex = 0;
  String _matchSearchQuery = '';
  String _leagueSearchQuery = '';
  String _matchFilter = 'all';
  
  Set<String> _favoriteMatchIds = {};
  bool _allExpanded = true;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
    _loadFavorites();
    
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        final provider = Provider.of<StatPalProvider>(context, listen: false);
        if (_hasKey && !provider.isLoading) {
          provider.loadInitialData(offset: _selectedDayIndex);
        }
      }
    });

    _matchSearchController.addListener(() {
      setState(() {
        _matchSearchQuery = _matchSearchController.text.toLowerCase();
      });
    });
    _leagueSearchController.addListener(() {
      setState(() {
        _leagueSearchQuery = _leagueSearchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('statpal_api_key') ?? '';
      if (savedKey.isNotEmpty && mounted) {
        setState(() {
          _apiKeyController.text = savedKey;
          _hasKey = true;
          _showSettings = false;
        });
      } else {
        setState(() {
          _showSettings = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('statpal_favorites') ?? [];
      if (mounted) {
        setState(() {
          _favoriteMatchIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String matchId) async {
    setState(() {
      if (_favoriteMatchIds.contains(matchId)) {
        _favoriteMatchIds.remove(matchId);
      } else {
        _favoriteMatchIds.add(matchId);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('statpal_favorites', _favoriteMatchIds.toList());
    } catch (_) {}
  }

  Future<void> _saveApiKey(StatPalProvider provider) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('statpal_api_key', key);

      if (!mounted) return;
      setState(() {
        _hasKey = true;
        _showSettings = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API kulcs sikeresen elmentve! Adatok frissülnek...'),
          backgroundColor: Colors.green,
        ),
      );

      provider.loadInitialData(offset: _selectedDayIndex);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba a mentés során: $e'), backgroundColor: Colors.red),
      );
    }
  }

  bool _isMatchLive(dynamic match) {
    final String status = (match.status ?? '').toString().toUpperCase();
    if (status.isEmpty || status == 'NS' || status == 'NOT STARTED' || status.contains(':')) return false;
    if (status == 'FT' || status == 'AET' || status == 'PEN' || status == 'FINISHED') return false;
    if (status.contains('POSTP') || status.contains('CANCL') || status.contains('CANC')) return false;
    return true;
  }

  bool _isMatchFinished(dynamic match) {
    final String status = (match.status ?? '').toString().toUpperCase();
    return status == 'FT' || status == 'AET' || status == 'PEN' || status == 'FINISHED';
  }

  bool _isMatchUpcoming(dynamic match) {
    final String status = (match.status ?? '').toString().toUpperCase();
    return status == 'NS' || status == 'NOT STARTED' || status.contains(':') || status.isEmpty;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _apiKeyController.dispose();
    _matchSearchController.dispose();
    _leagueSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('StatPal Élő & Ligák PRO', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_showSettings ? Icons.close : Icons.vpn_key, color: Colors.amber),
              tooltip: 'API Kulcs Beállítása',
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: 'Élő Meccsek'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Ligák & Tabellák'),
            ],
          ),
        ),
        body: Consumer<StatPalProvider>(
          builder: (context, provider, child) {
            final List<Map<String, dynamic>> filteredLeagueGroups = [];

            for (var rawLeague in provider.rawLiveMatchesGroups) {
              final rawLeagueName = rawLeague['name']?.toString() ?? 'Ismeretlen Liga';
              final leagueCountry = rawLeague['country']?.toString() ?? '';
              final leagueId = rawLeague['id']?.toString() ?? '';
              final matchesList = rawLeague['match'];

              if (matchesList is! List) continue;

              final displayHeader = StatPalHelper.formatLeagueHeader(leagueCountry, rawLeagueName);

              // Szigorú szűrés alkalmazása
              if (!StatPalHelper.isAllowedLeague(displayHeader)) {
                continue;
              }

              final List<StatMatch> matchedMeccsek = [];

              for (var mJson in matchesList) {
                final matchObj = StatMatch.fromJson(mJson);
                
                final home = matchObj.home.name.toLowerCase();
                final away = matchObj.away.name.toLowerCase();
                final matchesSearch = _matchSearchQuery.isEmpty || 
                    home.contains(_matchSearchQuery) || 
                    away.contains(_matchSearchQuery);

                if (!matchesSearch) continue;

                final bool isLive = _isMatchLive(matchObj);
                final bool isFinished = _isMatchFinished(matchObj);
                final bool isUpcoming = _isMatchUpcoming(matchObj);
                final bool isFav = _favoriteMatchIds.contains(matchObj.id);

                bool passesFilter = true;
                if (_matchFilter == 'live') {
                  passesFilter = isLive;
                } else if (_matchFilter == 'upcoming') {
                  passesFilter = isUpcoming;
                } else if (_matchFilter == 'finished') {
                  passesFilter = isFinished;
                } else if (_matchFilter == 'favorites') {
                  passesFilter = isFav;
                }

                if (passesFilter) {
                  matchedMeccsek.add(matchObj);
                }
              }

              if (matchedMeccsek.isNotEmpty) {
                matchedMeccsek.sort((a, b) => a.time.compareTo(b.time));
                filteredLeagueGroups.add({
                  'id': leagueId,
                  'name': displayHeader,
                  'matches': matchedMeccsek,
                });
              }
            }

            final filteredLeagues = provider.leagues.where((league) {
              final translatedName = StatPalHelper.formatLeagueHeader(league.country, league.name);
              if (!StatPalHelper.isAllowedLeague(translatedName)) return false;

              if (_leagueSearchQuery.isEmpty) return true;
              return translatedName.toLowerCase().contains(_leagueSearchQuery) ||
                     league.name.toLowerCase().contains(_leagueSearchQuery);
            }).toList();

            return Column(
              children: [
                if (_showSettings || !_hasKey)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      border: Border(bottom: BorderSide(color: colors.outline.withValues(alpha: 0.2))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('StatPal API Kulcs szükséges a lekérdezéshez', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Kulcs beillesztése',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => _saveApiKey(provider),
                            icon: const Icon(Icons.save),
                            label: const Text('Mentés és Adatok Lekérése'),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: TabBarView(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _matchSearchController,
                                        decoration: InputDecoration(
                                          hintText: 'Keresés csapatra...',
                                          prefixIcon: const Icon(Icons.search),
                                          suffixIcon: _matchSearchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () => _matchSearchController.clear(),
                                                )
                                              : null,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(_allExpanded ? Icons.unfold_less : Icons.unfold_more, color: Colors.amber),
                                      tooltip: _allExpanded ? 'Összes összecsukása' : 'Összes kibontása',
                                      onPressed: () {
                                        setState(() {
                                          _allExpanded = !_allExpanded;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DaySelector(
                                  selectedIndex: _selectedDayIndex,
                                  onChanged: (int index) {
                                    if (_selectedDayIndex == index) return;
                                    setState(() {
                                      _selectedDayIndex = index;
                                    });
                                    provider.loadInitialData(offset: index);
                                  },
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Összes'),
                                        selected: _matchFilter == 'all',
                                        onSelected: (_) => setState(() => _matchFilter = 'all'),
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        label: const Text('Kedvencek ⭐'),
                                        selected: _matchFilter == 'favorites',
                                        onSelected: (_) => setState(() => _matchFilter = 'favorites'),
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        label: const Text('Csak Élő 🔴'),
                                        selected: _matchFilter == 'live',
                                        onSelected: (_) => setState(() => _matchFilter = 'live'),
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        label: const Text('Következő ⏰'),
                                        selected: _matchFilter == 'upcoming',
                                        onSelected: (_) => setState(() => _matchFilter = 'upcoming'),
                                      ),
                                      const SizedBox(width: 6),
                                      ChoiceChip(
                                        label: const Text('Lejárt (FT) ✔️'),
                                        selected: _matchFilter == 'finished',
                                        onSelected: (_) => setState(() => _matchFilter = 'finished'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: provider.isLoading && provider.rawLiveMatchesGroups.isEmpty
                                ? const Center(child: CircularProgressIndicator())
                                : filteredLeagueGroups.isEmpty
                                    ? const Center(child: Text('Nincs a megadott listának megfelelő mérkőzés.', style: TextStyle(fontSize: 15)))
                                    : RefreshIndicator(
                                        onRefresh: () async => provider.loadInitialData(offset: _selectedDayIndex),
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          itemCount: filteredLeagueGroups.length,
                                          itemBuilder: (context, groupIndex) {
                                            final leagueGroup = filteredLeagueGroups[groupIndex];
                                            final displayHeader = leagueGroup['name'] as String;
                                            final List<StatMatch> matches = leagueGroup['matches'] as List<StatMatch>;

                                            return Card(
                                              margin: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              child: ExpansionTile(
                                                key: Key('${leagueGroup['id']}_$_allExpanded'),
                                                initiallyExpanded: _allExpanded,
                                                title: Row(
                                                  children: [
                                                    const Icon(Icons.sports_soccer, size: 16, color: Colors.amber),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        displayHeader,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                children: matches.map((matchItem) {
                                                  final bool isLive = _isMatchLive(matchItem);
                                                  final bool isUpcoming = _isMatchUpcoming(matchItem);
                                                  final String translatedStatus = StatPalHelper.translateStatus(matchItem.status);
                                                  final String correctedTime = StatPalHelper.formatMatchTime(matchItem.time);
                                                  final bool isFav = _favoriteMatchIds.contains(matchItem.id);

                                                  return InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => MatchDetailScreen(match: matchItem),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                                      child: Row(
                                                        children: [
                                                          InkWell(
                                                            onTap: () => _toggleFavorite(matchItem.id),
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(right: 8.0),
                                                              child: Icon(
                                                                isFav ? Icons.star : Icons.star_border,
                                                                color: isFav ? Colors.amber : Colors.grey,
                                                                size: 20,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 65,
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    if (isLive)
                                                                      Container(
                                                                        width: 7,
                                                                        height: 7,
                                                                        margin: const EdgeInsets.only(right: 4),
                                                                        decoration: const BoxDecoration(
                                                                          color: Colors.red,
                                                                          shape: BoxShape.circle,
                                                                        ),
                                                                      ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        isUpcoming ? 'Kezdés' : translatedStatus,
                                                                        style: TextStyle(
                                                                          color: isLive ? Colors.redAccent : Colors.grey,
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 12,
                                                                        ),
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  correctedTime,
                                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const VerticalDivider(width: 15),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  matchItem.home.name,
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.onSurface),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  matchItem.away.name,
                                                                  style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.85)),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          isUpcoming
                                                              ? Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.amber.withValues(alpha: 0.15),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                  child: Text(
                                                                    correctedTime,
                                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                                                                  ),
                                                                )
                                                              : Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                                  children: [
                                                                    Text('${matchItem.home.goals ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                    const SizedBox(height: 4),
                                                                    Text('${matchItem.away.goals ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                  ],
                                                                ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextField(
                              controller: _leagueSearchController,
                              decoration: InputDecoration(
                                hintText: 'Keresés ligára vagy országra...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _leagueSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () => _leagueSearchController.clear(),
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                            ),
                          ),
                          Expanded(
                            child: filteredLeagues.isEmpty
                                ? const Center(child: Text('Nincs a keresésnek megfelelő liga.', style: TextStyle(fontSize: 15)))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    itemCount: filteredLeagues.length,
                                    itemBuilder: (context, index) {
                                      final league = filteredLeagues[index];
                                      final translatedName = StatPalHelper.formatLeagueHeader(league.country, league.name);
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.emoji_events, color: Colors.amber),
                                          ),
                                          title: Text(translatedName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('Eredeti: ${league.name}'),
                                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                          onTap: () async {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => const Center(child: CircularProgressIndicator()),
                                            );

                                            await provider.loadStandings(league.id);

                                            if (!context.mounted) return;
                                            Navigator.pop(context);

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => LeagueStandingsScreen(
                                                  leagueName: translatedName,
                                                  standings: provider.standings,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LeagueStandingsScreen extends StatelessWidget {
  final String leagueName;
  final List<StatStandingTeam> standings;

  const LeagueStandingsScreen({
    super.key,
    required this.leagueName,
    required this.standings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(leagueName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: standings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      'Ehhez a ligához ($leagueName) jelenleg nem érhető el tabella az API-n keresztül, vagy az adott idény adatai zártak.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Row(
                    children: [
                      SizedBox(width: 35, child: Text('Hely', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Csapat', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 45, child: Text('Mérk.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 45, child: Text('Gól', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 45, child: Text('Pont', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: standings.length,
                    itemBuilder: (context, index) {
                      final team = standings[index];
                      final int pos = int.tryParse(team.position.toString()) ?? (index + 1);
                      final int points = int.tryParse(team.points.toString()) ?? 0;
                      final int played = int.tryParse(team.gamesPlayed.toString()) ?? 0;
                      final String goals = '${team.goalsScored}:${team.goalsAllowed}';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 35,
                              child: Text(
                                '$pos.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: pos <= 3 ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                team.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                '$played',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                goals,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                '$points',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
