import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenF1NextRaceApi {
  static const String baseUrl = 'https://api.openf1.org/v1';

  static Future<Map<String, dynamic>?> getNextOrCurrentRace() async {
    final response = await http.get(Uri.parse('$baseUrl/sessions'));
    final List<dynamic> sessions = jsonDecode(response.body);

    final now = DateTime.now().toUtc();

    // Trier par date de début
    sessions.sort((a, b) => a['date_start'].compareTo(b['date_start']));

    // Chercher la première course non terminée
    final race = sessions.cast<Map<String, dynamic>>().firstWhere(
          (s) {
        if (s['session_type'] != 'Race') return false;
        final start = DateTime.tryParse(s['date_start'])?.toUtc();
        final end = DateTime.tryParse(s['date_end'])?.toUtc();
        // Debug log
        print("Course détectée: ${s['country_name']} start=$start end=$end now=$now");
        return end != null && end.isAfter(now);
      },
      orElse: () => {},
    );

    if (race.isEmpty) return null;

    final start = DateTime.tryParse(race['date_start'])?.toUtc();
    final end = DateTime.tryParse(race['date_end'])?.toUtc();

    final status = (start != null && now.isAfter(start)) ? "Course en cours" : "Prochaine course";

    return {
      'status': status,
      'raceName': race['country_name'] ?? 'Course inconnue',
      'circuit': race['location'] ?? 'Circuit inconnu',
      'dateStart': start?.toLocal(),
      'image': 'https://i.imgur.com/Xx1Hh0H.jpeg',
      'isStarted': start != null && now.isAfter(start),
    };
  }
}
