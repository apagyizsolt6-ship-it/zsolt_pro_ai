// ============================================================================
// Zsolt Pro AI - StatPal Dashboard Screen (Füles & Interaktív Verzió)
// File: lib/screens/statpal_dashboard_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/statpal_provider.dart';

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
          _showSettings = false; // Ha már van kulcs, ne mutassa alapból
        });
      } else {
        setState(() {
          _showSettings = true; // Ha nincs kulcs, nyissa meg a beállítást
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
        const SnackBar(content: Text('API kulcs sikeresen elmentve!')),
      );

      provider.loadInitialData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba a mentés során: $e')),
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
          title: const Text('StatPal Élő & Ligák'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_showSettings ? Icons.close : Icons.vpn_key),
              tooltip: 'API Kulcs Beállítása',
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: 'Élő Meccsek'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Ligák'),
            ],
          ),
        ),
        body: Consumer<StatPalProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Ha be van kapcsolva a beállítás panel, megjelenik felül lenyitva
                if (_showSettings || !_hasKey)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: colors.surfaceContainerHighest,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'StatPal API Kulcs szükséges',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _saveApiKey(provider),
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Kulcs Mentése'),
                        ),
                      ],
                    ),
                  ),

                // Fő tartalom fülekre szedve
                Expanded(
                  child: TabBarView(
                    children: [
                      // 1. Élő meccsek fül
                      provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.liveMatches.isEmpty
                              ? const Center(child: Text('Nincsenek élő mérkőzések.'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: provider.liveMatches.length,
                                  itemBuilder: (context, index) {
                                    final match = provider.liveMatches[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        title: Text(
                                          '${match.home.name} vs ${match.away.name}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text('Státusz: ${match.status}'),
                                        trailing: Text(
                                          '${match.home.score ?? "0"} : ${match.away.score ?? "0"}',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Kiválasztva: ${match.home.name} - ${match.away.name}')),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),

                      // 2. Ligák fül
                      provider.leagues.isEmpty
                          ? const Center(child: Text('Nincsenek elérhető ligák.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: provider.leagues.length,
                              itemBuilder: (context, index) {
                                final league = provider.leagues[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                                    title: Text(
                                      league.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('Ország: ${league.country.toUpperCase()}'),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () {
                                      provider.loadStandings(league.id);
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(league.name),
                                          content: const Text('Tabella lekérve! (Részletes nézet hamarosan)'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Bezár'),
                                            ),
                                          ],
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
