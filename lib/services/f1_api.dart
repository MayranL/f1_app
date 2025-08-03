import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenF1Api {
  static const String baseUrl = 'https://api.openf1.org/v1';

  /// Récupère la grille de départ de la prochaine course
  static Future<List<Map<String, dynamic>>> getNextRaceGrid() async {
    // 1. Récupérer toutes les sessions
    final sessionsRes = await http.get(Uri.parse('$baseUrl/sessions'));
    final sessions = List<Map<String, dynamic>>.from(jsonDecode(sessionsRes.body));

    // 2. Trier les sessions par date
    sessions.sort((a, b) => a['date_start'].compareTo(b['date_start']));

    final now = DateTime.now();

    // 3. Chercher la prochaine course (ou retourner liste vide)
    final nextRace = sessions.firstWhere(
          (s) =>
      s['session_type'] == 'Race' &&
          DateTime.tryParse(s['date_start'])?.isAfter(now) == true,
      orElse: () => {},
    );

    if (nextRace.isEmpty) {
      return [];
    }

    // 4. Chercher la dernière qualif avant cette course
    final qualiSession = sessions.lastWhere(
          (s) =>
      s['session_type'] == 'Qualifying' &&
          DateTime.tryParse(s['date_end'])?.isBefore(DateTime.parse(nextRace['date_start'])) == true,
      orElse: () => {},
    );

    if (qualiSession.isEmpty) {
      return [];
    }

    // 5. Récupérer les tours de la qualif
    final lapsRes =
    await http.get(Uri.parse('$baseUrl/laps?session_key=${qualiSession['session_key']}'));
    final laps = List<Map<String, dynamic>>.from(jsonDecode(lapsRes.body));

    // 6. Filtrer uniquement les tours avec chrono
    final validLaps = laps.where((lap) => lap['lap_duration'] != null).toList();

    // 7. Meilleur tour par pilote
    final bestLapsByDriver = <int, Map<String, dynamic>>{};
    for (var lap in validLaps) {
      final driver = lap['driver_number'];
      final lapDuration = (lap['lap_duration'] as num).toDouble();

      if (!bestLapsByDriver.containsKey(driver) ||
          lapDuration <
              (bestLapsByDriver[driver]!['lap_duration'] as num).toDouble()) {
        bestLapsByDriver[driver] = lap;
      }
    }

    if (bestLapsByDriver.isEmpty) {
      return [];
    }

    // 8. Trier par meilleur temps croissant
    final grid = bestLapsByDriver.values.toList()
      ..sort((a, b) =>
          (a['lap_duration'] as num).compareTo((b['lap_duration'] as num)));

    // 9. Récupérer infos pilotes
    final driversRes = await http.get(Uri.parse('$baseUrl/drivers'));
    final drivers = List<Map<String, dynamic>>.from(jsonDecode(driversRes.body));

    return grid.asMap().entries.map((entry) {
      final pos = entry.key + 1;
      final lap = entry.value;
      final driverInfo = drivers.firstWhere(
            (d) => d['driver_number'] == lap['driver_number'],
        orElse: () => {
          'full_name': 'Unknown',
          'team_name': 'Unknown',
          'name_acronym': '',
        },
      );
      return {
        'position': pos.toString(),
        'driver': driverInfo['full_name'],
        'constructor': driverInfo['team_name'] ?? 'Unknown',
        'code': driverInfo['name_acronym'] ?? '',
      };
    }).toList();
  }
}
