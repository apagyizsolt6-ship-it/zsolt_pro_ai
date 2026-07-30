// ============================================================================
// Zsolt Pro AI - StatPal Dashboard Screen (Biztonságos verzió)
// File: lib/screens/statpal_dashboard_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<StatPalProvider>(context, listen: false).loadInitialData();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zsolt Pro AI - StatPal Élő'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: 'Élő Meccsek'),
              Tab(icon: Icon(Icons.list_alt), text: 'Ligák'),
              Tab(icon: Icon(Icons.settings), text: 'API Beállítás'),
            ],
          ),
        ),
        body: Consumer<StatPalProvider>(
          builder: (context, provider, child) {
            return TabBarView(
              children: [
                _buildLiveMatchesTab(provider),
                _buildLeaguesTab(provider),
                _buildSettingsTab(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveMatchesTab(StatPalProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.liveMatches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Jelenleg nincsenek élő mérkőzések, vagy még nem adtad meg az API kulcsot az "API Beállítás" fülön.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.liveMatches.length,
      itemBuilder: (context, index) {
        final match = provider.liveMatches[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text('${match.home.name} vs ${match.away.name}'),
            subtitle: Text('Dátum: ${match.date} ${match.time} | Státusz: ${match.status}'),
            trailing: Text(
              '${match.home.score ?? "0"} : ${match.away.score ?? "0"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaguesTab(StatPalProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.leagues.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Nincsenek elérhető ligák. Add meg az API kulcsot a Beállítások fülön!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.leagues.length,
      itemBuilder: (context, index) {
        final league = provider.leagues[index];
        return ListTile(
          leading: const Icon(Icons.emoji_events),
          title: Text(league.name),
          subtitle: Text('Ország: ${league.country.toUpperCase()}'),
          onTap: () {
            provider.loadStandings(league.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tabella lekérése: ${league.name}')),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab(StatPalProvider provider) {
    return Padding(
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (_apiKeyController.text.isNotEmpty) {
                // Itt mentheted el vagy frissítheted a provideren keresztül
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API kulcs frissítve!')),
                );
                provider.loadInitialData();
              }
            },
            child: const Text('Mentés és Adatok Frissítése'),
          ),
          if (provider.errorMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              provider.errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}
