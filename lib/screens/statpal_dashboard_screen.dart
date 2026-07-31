// ============================================================================
// Zsolt Pro AI - StatPal Dashboard Screen (Véglegesen Javított PRO Verzió)
// File: lib/screens/statpal_dashboard_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/statpal_provider.dart';
import '../models/statpal_models.dart';

class StatPalDashboardScreen extends StatelessWidget {
  const StatPalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatPalProvider()..loadInitialData(),
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
  String _matchSearchQuery = '';
  String _leagueSearchQuery = '';
  String _matchFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
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

      provider.loadInitialData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba a mentés során: $e'), backgroundColor: Colors.red),
      );
    }
  }

  bool _isMatchLive(dynamic match) {
    final String status = (match.status ?? '').toString().toUpperCase();
    if (status.contains(':') || status == 'NS' || status == 'NOT STARTED' || status.isEmpty) {
      return false;
    }
    if (status == 'FT' || status == 'AET' || status == 'PEN' || status == 'FINISHED') {
      return false;
    }
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
            final filteredMatches = provider.liveMatches.where((match) {
              final home = match.home.name.toLowerCase();
              final away = match.away.name.toLowerCase();
              final matchesSearch = _matchSearchQuery.isEmpty || 
                  home.contains(_matchSearchQuery) || 
                  away.contains(_matchSearchQuery);

              if (!matchesSearch) return false;

              final bool isLive = _isMatchLive(match);
              final bool isFinished = _isMatchFinished(match);
              final bool isUpcoming = _isMatchUpcoming(match);

              if (_matchFilter == 'live') return isLive;
              if (_matchFilter == 'upcoming') return isUpcoming;
              if (_matchFilter == 'finished') return isFinished;
              return true;
            }).toList();

            filteredMatches.sort((a, b) {
              final timeA = (a.time ?? '').toString();
              final timeB = (b.time ?? '').toString();
              return timeA.compareTo(timeB);
            });

            final Map<String, List<dynamic>> groupedMatches = {
              'Zajló Élő Meccsek 🔴': filteredMatches.where((m) => _isMatchLive(m)).toList(),
              'Következő Mérkőzések ⏰': filteredMatches.where((m) => _isMatchUpcoming(m)).toList(),
              'Végeredmény / Lejárt Meccsek (FT) ✔️': filteredMatches.where((m) => _isMatchFinished(m)).toList(),
            };

            final filteredLeagues = provider.leagues.where((league) {
              if (_leagueSearchQuery.isEmpty) return true;
              return league.name.toLowerCase().contains(_leagueSearchQuery) ||
                     league.country.toLowerCase().contains(_leagueSearchQuery);
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
                            labelText: 'API Key beillesztése',
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
                                TextField(
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
                            child: provider.isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : filteredMatches.isEmpty
                                    ? const Center(child: Text('Nincs a feltételeknek megfelelő mérkőzés.', style: TextStyle(fontSize: 15)))
                                    : RefreshIndicator(
                                        onRefresh: () async => provider.loadInitialData(),
                                        child: ListView(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          children: groupedMatches.entries.map((entry) {
                                            final sectionTitle = entry.key;
                                            final matchesInGroup = entry.value;

                                            if (matchesInGroup.isEmpty) return const SizedBox.shrink();

                                            return Card(
                                              margin: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              child: ExpansionTile(
                                                initiallyExpanded: sectionTitle.contains('Élő') || sectionTitle.contains('Következő'),
                                                title: Text(
                                                  '$sectionTitle (${matchesInGroup.length})',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
                                                ),
                                                children: matchesInGroup.map((match) {
                                                  final bool isLive = _isMatchLive(match);
                                                  final bool isUpcoming = _isMatchUpcoming(match);
                                                  
                                                  return InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => MatchDetailScreen(match: match),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                                      child: Row(
                                                        children: [
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
                                                                    Text(
                                                                      isUpcoming ? 'Kezdés' : match.status,
                                                                      style: TextStyle(
                                                                        color: isLive ? Colors.redAccent : Colors.grey,
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  match.time,
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
                                                                  match.home.name,
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.onSurface),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  match.away.name,
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
                                                                    match.time,
                                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                                                                  ),
                                                                )
                                                              : Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                                  children: [
                                                                    Text('${match.home.goals}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                    const SizedBox(height: 4),
                                                                    Text('${match.away.goals}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                  ],
                                                                ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          }).toList(),
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
                                          title: Text(league.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('Ország: ${league.country.toUpperCase()}'),
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
                                                  leagueName: league.name,
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

class MatchDetailScreen extends StatelessWidget {
  final dynamic match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${match.home.name} vs ${match.away.name}', style: const TextStyle(fontSize: 14)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('Státusz: ${match.status} (${match.time})', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: Text(match.home.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Text('${match.home.goals} : ${match.away.goals}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
                        Expanded(child: Text(match.away.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Részletes AI statisztikák és esélyek hamarosan...', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
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
                      SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Csapat', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 50, child: Text('Pont', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
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

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$pos',
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
                              width: 50,
                              child: Text(
                                '$points',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
