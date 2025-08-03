import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenF1ChampionshipApi {
  static const String baseUrl = 'https://api.openf1.org/v1';

  /// Tableau officiel de points F1 2024/2025 (sans Sprint)
  static const List<int> pointsTable = [
    25, 18, 15, 12, 10, 8, 6, 4, 2, 1
  ];

  static Future<List<Map<String, dynamic>>> getSeasonStandings() async {
    // 1. Récupérer toutes les sessions de la saison
    final sessionsRes = await http.get(Uri.parse('$baseUrl/sessions'));
    final sessions = List<Map<String, dynamic>>.from(jsonDecode(sessionsRes.body));

    final now = DateTime.now();
    // Filtrer sur les courses terminées cette saison
    final finishedRaces = sessions.where((s) {
      final isRace = s['session_type'] == 'Race';
      final endDate = DateTime.tryParse(s['date_end']);
      final startDate = DateTime.tryParse(s['date_start']);
      // Filtrer sur l'année en cours
      return isRace &&
          endDate != null &&
          endDate.isBefore(now) &&
          startDate != null &&
          startDate.year == now.year;
    }).toList();

    if (finishedRaces.isEmpty) return [];

    // 2. Charger infos pilotes
    final driversRes = await http.get(Uri.parse('$baseUrl/drivers'));
    final drivers = List<Map<String, dynamic>>.from(jsonDecode(driversRes.body));

    // 3. Dictionnaire pour cumuler points
    final Map<int, Map<String, dynamic>> standings = {};

    // 4. Pour chaque course, récupérer le classement final
    for (var race in finishedRaces) {
      final sessionKey = race['session_key'];
      final posRes = await http.get(Uri.parse('$baseUrl/position?session_key=$sessionKey'));
      final positions = List<Map<String, dynamic>>.from(jsonDecode(posRes.body));

      if (positions.isEmpty) continue;

      // Dernière position connue pour chaque pilote
      final latestPos = <int, Map<String, dynamic>>{};
      for (var pos in positions) {
        latestPos[pos['driver_number']] = pos;
      }

      // Trier par position croissante
      final raceResults = latestPos.values.toList()
        ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

      for (int i = 0; i < raceResults.length; i++) {
        final driverNum = raceResults[i]['driver_number'] as int;
        final position = raceResults[i]['position'] as int;
        final points = (position <= pointsTable.length) ? pointsTable[position - 1] : 0;

        // Initialiser le pilote si absent
        standings.putIfAbsent(driverNum, () {
          final driverInfo = drivers.firstWhere(
                (d) => d['driver_number'] == driverNum,
            orElse: () => {
              'full_name': 'Unknown',
              'team_name': 'Unknown',
              'name_acronym': '',
            },
          );
          return {
            'driver': driverInfo['full_name'],
            'constructor': driverInfo['team_name'],
            'code': driverInfo['name_acronym'],
            'points': 0,
          };
        });

        standings[driverNum]!['points'] += points;
      }
    }

    // 5. Retourner le classement trié par points décroissants
    final sortedStandings = standings.values.toList()
      ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

    return sortedStandings.asMap().entries.map((entry) {
      final pos = entry.key + 1;
      final driver = entry.value;
      return {
        'position': pos.toString(),
        'driver': driver['driver'],
        'constructor': driver['constructor'],
        'code': driver['code'],
        'points': driver['points'].toString(),
      };
    }).toList();
  }
}
