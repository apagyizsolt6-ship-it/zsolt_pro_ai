// ============================================================================
// Zsolt Pro AI - StatPal Dashboard Screen (Garanciális Zöld Build Verzió)
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
  bool _hasKey = false;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
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

  @override
  void dispose() {
    _apiKeyController.dispose();
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
                      provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.liveMatches.isEmpty
                              ? const Center(
                                  child: Text('Jelenleg nincsenek élő mérkőzések.', style: TextStyle(fontSize: 16)),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async => provider.loadInitialData(),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: provider.liveMatches.length,
                                    itemBuilder: (context, index) {
                                      final match = provider.liveMatches[index];
                                      final bool isLive = match.status != 'FT' && match.status != 'NS';
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                                                          match.status,
                                                          style: TextStyle(
                                                            color: isLive ? Colors.redAccent : Colors.grey,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
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
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: colors.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      match.away.name,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.normal,
                                                        fontSize: 14,
                                                        color: colors.onSurface.withValues(alpha: 0.85),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    match.home.score ?? '0',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    match.away.score ?? '0',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                      provider.leagues.isEmpty
                          ? const Center(child: Text('Nincsenek elérhető ligák.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: provider.leagues.length,
                              itemBuilder: (context, index) {
                                final league = provider.leagues[index];
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
          ? const Center(child: Text('Nincs elérhető tabella ehhez a ligához.'))
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
