import 'package:flutter/material.dart';

import '../services/open_live.dart';


class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  late Future<List<Map<String, dynamic>>> _futureLive;

  @override
  void initState() {
    super.initState();
    _futureLive = OpenF1LiveApi.getLiveStandings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement en direct'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureLive,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Aucun classement disponible pour le moment',
                    style: TextStyle(color: Colors.white)));
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