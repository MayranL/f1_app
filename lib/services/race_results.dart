import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenF1RaceResultsApi {
  static const String baseUrl = 'https://api.openf1.org/v1';

  /// Retourne toutes les courses terminées cette saison avec leurs résultats complets
  static Future<List<Map<String, dynamic>>> getAllRaceResults() async {
    final now = DateTime.now();

    // 1. Récupérer toutes les sessions
    final sessionsRes = await http.get(Uri.parse('$baseUrl/sessions'));
    final sessions = List<Map<String, dynamic>>.from(jsonDecode(sessionsRes.body));

    // 2. Filtrer les courses terminées de l'année en cours
    final finishedRaces = sessions.where((s) {
      final isRace = s['session_type'] == 'Race';
      final startDate = DateTime.tryParse(s['date_start']);
      final endDate = DateTime.tryParse(s['date_end']);
      return isRace && startDate != null && endDate != null &&
          endDate.isBefore(now) && startDate.year == now.year;
    }).toList();

    // 3. Trier par date (plus récentes en dernier)
    finishedRaces.sort((a, b) => DateTime.parse(a['date_start'])
        .compareTo(DateTime.parse(b['date_start'])));

    // 4. Charger infos pilotes
    final driversRes = await http.get(Uri.parse('$baseUrl/drivers'));
    final drivers = List<Map<String, dynamic>>.from(jsonDecode(driversRes.body));

    // 5. Pour chaque course, récupérer le classement final
    List<Map<String, dynamic>> allResults = [];

    for (var race in finishedRaces) {
      final sessionKey = race['session_key'];
      final raceName = race['country_name'] ?? 'Course inconnue';
      final raceDate = race['date_start'];

      // Récupérer positions
      final posRes = await http.get(Uri.parse('$baseUrl/position?session_key=$sessionKey'));
      final positions = List<Map<String, dynamic>>.from(jsonDecode(posRes.body));
      if (positions.isEmpty) continue;

      // Dernière position connue pour chaque pilote
      final latestPositionsByDriver = <int, Map<String, dynamic>>{};
      for (var pos in positions) {
        latestPositionsByDriver[pos['driver_number']] = pos;
      }

      // Construire le classement final
      final results = latestPositionsByDriver.values.toList()
        ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

      final raceResults = results.map((pos) {
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

      allResults.add({
        'raceName': raceName,
        'raceDate': raceDate,
        'results': raceResults,
      });
    }

    return allResults;
  }
}
