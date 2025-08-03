
import 'package:flutter/material.dart';

import '../services/openf1_championship.dart';

class SeasonStandingsScreen extends StatefulWidget {
  const SeasonStandingsScreen({super.key});

  @override
  State<SeasonStandingsScreen> createState() => _SeasonStandingsScreenState();
}

class _SeasonStandingsScreenState extends State<SeasonStandingsScreen> {
  late Future<List<Map<String, dynamic>>> _futureStandings;

  @override
  void initState() {
    super.initState();
    _futureStandings = OpenF1ChampionshipApi.getSeasonStandings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement Général'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureStandings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucun classement disponible pour la saison',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final standings = snapshot.data!;
          return ListView.builder(
            itemCount: standings.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final driver = standings[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text(driver['position'],
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(driver['driver'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${driver['constructor']} - ${driver['points']} pts',
                      style: const TextStyle(color: Colors.grey)),
                  trailing: Text(driver['code'],
                      style: const TextStyle(color: Colors.red, fontSize: 18)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
