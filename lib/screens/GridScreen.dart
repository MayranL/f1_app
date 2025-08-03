
import 'package:flutter/material.dart';

import '../services/f1_api.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  late Future<List<Map<String, dynamic>>> _futureGrid;

  @override
  void initState() {
    super.initState();
    _futureGrid = OpenF1Api.getNextRaceGrid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grille de départ'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureGrid,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Aucune grille disponible pour le moment',
                    style: TextStyle(color: Colors.white)));
          }

          final grid = snapshot.data!;
          return ListView.builder(
            itemCount: grid.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final driver = grid[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text(driver['position'], style: const TextStyle(color: Colors.white)),
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