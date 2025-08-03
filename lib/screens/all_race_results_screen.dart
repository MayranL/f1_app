import 'package:flutter/material.dart';
import '../services/race_results.dart';

class AllRaceResultsScreen extends StatefulWidget {
  const AllRaceResultsScreen({super.key});

  @override
  State<AllRaceResultsScreen> createState() => _AllRaceResultsScreenState();
}

class _AllRaceResultsScreenState extends State<AllRaceResultsScreen>
    with AutomaticKeepAliveClientMixin {

  late Future<List<Map<String, dynamic>>> _futureAllResults;

  @override
  void initState() {
    super.initState();
    _futureAllResults = OpenF1RaceResultsApi.getAllRaceResults();
  }

  // 1️⃣ Obligatoire pour activer la sauvegarde d’état
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 2️⃣ Obligatoire pour informer Flutter de garder l’état
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats par course'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureAllResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun résultat disponible', style: TextStyle(color: Colors.white)));
          }

          final races = snapshot.data!;
          return ListView.builder(
            itemCount: races.length,
            itemBuilder: (context, index) {
              final race = races[index];
              final results = race['results'] as List<Map<String, dynamic>>;

              return ExpansionTile(
                title: Text(race['raceName'], style: const TextStyle(color: Colors.white)),
                children: results.map((driver) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(driver['position'], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(driver['driver'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text(driver['constructor'], style: const TextStyle(color: Colors.grey)),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

