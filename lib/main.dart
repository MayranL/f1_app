import 'package:f1_app/screens/GridScreen.dart';
import 'package:f1_app/screens/LastResultsScreen.dart';
import 'package:f1_app/screens/LiveScreen.dart';
import 'package:f1_app/screens/SeasonStandingsScreen.dart';
import 'package:f1_app/screens/all_race_results_screen.dart';
import 'package:f1_app/screens/futuristic_next_race_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const F1App());
}

class F1App extends StatelessWidget {
  const F1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    GridScreen(),
    LiveScreen(),
    LastResultsScreen(),
    SeasonStandingsScreen(),
    AllRaceResultsScreen(),
    FuturisticNextRaceScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Grille'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Dernière'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Saison'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'Futur'),
        ],
      ),
    );
  }
}
