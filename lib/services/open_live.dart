import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenF1LiveApi {
  static const String baseUrl = 'https://api.openf1.org/v1';

  /// Récupère le classement actuel (live) de la course en cours
  static Future<List<Map<String, dynamic>>> getLiveStandings() async {
    // 1. Récupérer la dernière course en cours
    final sessionsRes = await http.get(Uri.parse('$baseUrl/sessions'));
    final sessions = List<Map<String, dynamic>>.from(jsonDecode(sessionsRes.body));

    // On cherche la dernière session de type 'Race' déjà commencée
    final now = DateTime.now();
    final currentRace = sessions.lastWhere(
          (s) =>
      s['session_type'] == 'Race' &&
          DateTime.tryParse(s['date_start'])?.isBefore(now) == true &&
          DateTime.tryParse(s['date_end'])?.isAfter(now) == true,
      orElse: () => {},
    );

    if (currentRace.isEmpty) {
      return [];
    }

    final sessionKey = currentRace['session_key'];

    // 2. Récupérer la position live
    final posRes = await http.get(Uri.parse('$baseUrl/position?session_key=$sessionKey'));
    final positions = List<Map<String, dynamic>>.from(jsonDecode(posRes.body));

    // Si pas de données live
    if (positions.isEmpty) return [];

    // 3. Récupérer les infos pilotes
    final driversRes = await http.get(Uri.parse('$baseUrl/drivers'));
    final drivers = List<Map<String, dynamic>>.from(jsonDecode(driversRes.body));

    // 4. Construire le classement
    final standings = positions.map((pos) {
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

    // 5. Trier par position croissante
    standings.sort((a, b) => int.parse(a['position']).compareTo(int.parse(b['position'])));

    return standings;
  }
}
