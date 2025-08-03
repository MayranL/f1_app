
import 'package:flutter/material.dart';

import '../services/open_result.dart';

class LastResultsScreen extends StatefulWidget {
  const LastResultsScreen({super.key});

  @override
  State<LastResultsScreen> createState() => _LastResultsScreenState();
}

class _LastResultsScreenState extends State<LastResultsScreen> {
  late Future<List<Map<String, dynamic>>> _futureResults;

  @override
  void initState() {
    super.initState();
    _futureResults = OpenF1ResultsApi.getLastRaceResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats dernière course'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucun résultat disponible',
                  style: TextStyle(color: Colors.white)),
            );
          }

          final results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final driver = results[index];
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
                  subtitle: Text(driver['constructor'], style: const TextStyle(color: Colors.grey)),
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
