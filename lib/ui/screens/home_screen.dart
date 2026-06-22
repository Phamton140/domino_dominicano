import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../theme.dart';
import 'game_screen.dart';

/// Pantalla de inicio. Botón para comenzar una nueva partida local.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dominó Dominicano')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino, size: 96, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Dominó Dominicano',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Partida local de 1 jugador contra 3 bots',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _startGame(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Nueva partida'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DominoTheme.tableGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    final controller = GameController();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
  }
}
