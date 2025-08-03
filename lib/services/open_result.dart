import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenF1ResultsApi {
  static const String baseUrl = 'https://api.openf1.org/v1';

  /// Récupère le classement final de la dernière course terminée
  static Future<List<Map<String, dynamic>>> getLastRaceResults() async {
    // 1. Récupérer toutes les sessions
    final sessionsRes = await http.get(Uri.parse('$baseUrl/sessions'));
    final sessions = List<Map<String, dynamic>>.from(jsonDecode(sessionsRes.body));

    // 2. Chercher la dernière course terminée
    final now = DateTime.now();
    final lastRace = sessions.lastWhere(
          (s) =>
      s['session_type'] == 'Race' &&
          DateTime.tryParse(s['date_end'])?.isBefore(now) == true,
      orElse: () => {},
    );

    if (lastRace.isEmpty) {
      return [];
    }

    final sessionKey = lastRace['session_key'];

    // 3. Récupérer les positions finales
    final posRes = await http.get(Uri.parse('$baseUrl/position?session_key=$sessionKey'));
    final positions = List<Map<String, dynamic>>.from(jsonDecode(posRes.body));

    if (positions.isEmpty) return [];

    // 4. Filtrer la dernière position connue par pilote
    final latestPositionsByDriver = <int, Map<String, dynamic>>{};
    for (var pos in positions) {
      final driver = pos['driver_number'];
      // On prend la dernière position connue
      latestPositionsByDriver[driver] = pos;
    }

    // 5. Récupérer infos pilotes
    final driversRes = await http.get(Uri.parse('$baseUrl/drivers'));
    final drivers = List<Map<String, dynamic>>.from(jsonDecode(driversRes.body));

    // 6. Construire la liste finale triée par position
    final results = latestPositionsByDriver.values.toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    return results.map((pos) {
      final driverInfo = drivers.firstWhere(
            (d) => d['driver_number'] == pos['driver_number'],
        orElse: () => {'full_name': 'Unknown', 'team_name': 'Unknown', 'name_acronym': ''},
      );
      return {
        'position': pos['position'].toString(),
        'driver': driverInfo['full_name'],
        'constructor': driverInfo['team_name'] ?? 'Unknown',
        'code': driverInfo['name_acronym'] ?? '',
      };
    }).toList();
  }
}
