import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/next_race.dart';

class FuturisticNextRaceScreen extends StatefulWidget {
  const FuturisticNextRaceScreen({super.key});

  @override
  State<FuturisticNextRaceScreen> createState() => _FuturisticNextRaceScreenState();
}

class _FuturisticNextRaceScreenState extends State<FuturisticNextRaceScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>?> _futureNextRace;
  late AnimationController _controller;
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _futureNextRace = OpenF1NextRaceApi.getNextOrCurrentRace();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime target) {
    _remaining = target.difference(DateTime.now());
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newRemaining = target.difference(DateTime.now());
      if (newRemaining.isNegative) {
        _countdownTimer?.cancel();
        setState(() {
          _remaining = Duration.zero;
        });
      } else {
        setState(() {
          _remaining = newRemaining;
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _futureNextRace,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
                child: Text('Aucune course à venir',
                    style: TextStyle(color: Colors.white, fontSize: 24)));
          }

          final race = snapshot.data!;
          final isStarted = race['isStarted'] as bool;
          final dateStart = race['dateStart'] as DateTime?;
          final bgImage = race['image'] as String;

          if (!isStarted && dateStart != null) {
            _startCountdown(dateStart);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Fond du circuit
/*
              Image.network(
                bgImage,
                fit: BoxFit.cover,
              ),
*/
              // Effet néon animé
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.3),
                          Colors.orange.withOpacity(1),
                          Colors.black.withOpacity(1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 2 * math.pi),
                      ),
                    ),
                    foregroundDecoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                    ),
                  );
                },
              ),
              // Carte centrale
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, color: Colors.redAccent, size: 60),
                      const SizedBox(height: 20),
                      Text(
                        race['status'],
                        style: TextStyle(
                            color: Colors.redAccent.shade100,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        race['raceName'],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        race['circuit'],
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      if (!isStarted && _remaining != null)
                        Text(
                          "Départ dans ${_formatDuration(_remaining!)}",
                          style: const TextStyle(color: Colors.redAccent, fontSize: 22),
                        ),
                      if (isStarted)
                        const Text(
                          "La course est en cours !",
                          style: TextStyle(color: Colors.green, fontSize: 22),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
