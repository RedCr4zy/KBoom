import 'package:flutter/material.dart';
import 'package:kboom/services/socket_service.dart';

class GameStatsPage extends StatefulWidget {
  const GameStatsPage({super.key});

  @override
  State<GameStatsPage> createState() => _GameStatsPageState();
}

class _GameStatsPageState extends State<GameStatsPage> {
  bool _isLoading = true;
  final List<dynamic> _stats = []; // Using dynamic as PlayerStats might not be defined yet
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() async {
    setState(() => _isLoading = true);

    // Demander stats au serveur
    socketService.sendJson({
      "type": "getGameSats"
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Placeholder(),
    );
  }
}
