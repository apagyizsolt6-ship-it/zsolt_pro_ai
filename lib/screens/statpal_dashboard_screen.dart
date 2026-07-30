// ============================================================================
// Zsolt Pro AI - StatPal Dashboard Screen (Biztosított Layout Verzió)
// File: lib/screens/statpal_dashboard_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/statpal_provider.dart';

class StatPalDashboardScreen extends StatefulWidget {
  const StatPalDashboardScreen({super.key});

  @override
  State<StatPalDashboardScreen> createState() => _StatPalDashboardScreenState();
}

class _StatPalDashboardScreenState extends State<StatPalDashboardScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<StatPalProvider>(context, listen: false).loadInitialData();
      } catch (_) {}
    });
  }

  Future<void> _loadSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('statpal_api_key') ?? '';
      if (savedKey.isNotEmpty && mounted) {
        setState(() {
          _apiKeyController.text = savedKey;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API kulcs sikeresen elmentve és frissítve!')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zsolt Pro AI - StatPal Vezérlő'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<StatPalProvider>(
          builder: (context, provider, child) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. API Beállítás kártya
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'StatPal API Kulcs Beállítása',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                            border: OutlineInputBorder(),
                            hintText: 'Írd be ide az API kulcsot...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _saveApiKey(provider),
                          icon: const Icon(Icons.save),
                          label: const Text('Mentés és Adatok Frissítése'),
                        ),
                        if (provider.errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            provider.errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Élő Meccsek szekció
                const Text(
                  'Élő Mérkőzések',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.liveMatches.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'Nincsenek élő mérkőzések, vagy még nem mentetted el az API kulcsot fent.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            children: provider.liveMatches.map((match) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text('${match.home.name} vs ${match.away.name}'),
                                  subtitle: Text('Státusz: ${match.status}'),
                                  trailing: Text(
                                    '${match.home.score ?? "0"} : ${match.away.score ?? "0"}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                const SizedBox(height: 20),

                // 3. Ligák szekció
                const Text(
                  'Elérhető Ligák',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                provider.leagues.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Nincsenek ligák betöltve.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        children: provider.leagues.map((league) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.emoji_events),
                              title: Text(league.name),
                              subtitle: Text('Ország: ${league.country.toUpperCase()}'),
                              onTap: () {
                                provider.loadStandings(league.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Tabella lekérése: ${league.name}')),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
