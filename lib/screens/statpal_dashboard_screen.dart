// ============================================================================
// Zsolt Pro AI - StatPal Dashboard Screen (Teljes javított fájl)
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

class _StatPalDashboardScreenState extends State<StatPalDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatPalProvider>(context, listen: false).loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StatPalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zsolt Pro AI - StatPal Élő'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sports_soccer), text: 'Élő Meccsek'),
            Tab(icon: Icon(Icons.list_alt), text: 'Ligák'),
            Tab(icon: Icon(Icons.settings), text: 'API Beállítás'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLiveMatchesTab(provider),
                _buildLeaguesTab(provider),
                _buildSettingsTab(provider),
              ],
            ),
    );
  }

  Widget _buildLiveMatchesTab(StatPalProvider provider) {
    if (provider.liveMatches.isEmpty) {
      const message = 'Jelenleg nincsenek élő mérkőzések vagy nincs beállítva az API kulcs.';
      return const Center(child: Text(message));
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
    if (provider.leagues.isEmpty) {
      return const Center(child: Text('Nincsenek elérhető ligák. Ellenőrizd az API kulcsot!'));
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
