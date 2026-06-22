import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameController', () {
    test('inicia la partida en fase playing con equipos en cero', () {
      final c = GameController(botsEnabled: false);
      expect(c.phase, GamePhase.playing);
      expect(c.game.teams['A']!.score, 0);
      expect(c.game.teams['B']!.score, 0);
    });

    test('continueAfterRound no avanza si la ronda sigue activa', () {
      final c = GameController(botsEnabled: false);
      final before = c.game.roundNumber;
      c.continueAfterRound();
      expect(c.game.roundNumber, before);
    });

    test('botsEnabled=false deja la ronda con el jugador programado', () {
      final c = GameController(botsEnabled: false);
      final round = c.game.currentRound!;
      // Limpiamos manos y forzamos un escenario donde el local no sale.
      final useless = const DominoTile(0, 0);
      for (final p in round.players) {
        p.hand = [useless];
      }
      // Forzamos el inicio con el jugador 1.
      round.start(starterIndex: 1);
      // Si los bots estuvieran habilitados habrían actuado; con
      // botsEnabled=false el currentPlayer no cambia.
      expect(round.currentPlayerIndex, 1);
    });

    test('validMovesForLocal devuelve vacío si no es turno del local', () {
      final c = GameController(botsEnabled: false);
      final round = c.game.currentRound!;
      for (final p in round.players) {
        p.hand = [const DominoTile(0, 0)];
      }
      round.start(starterIndex: 1);
      expect(c.isLocalTurn, isFalse);
      expect(c.validMovesForLocal, isEmpty);
      expect(c.localCanPlay, isFalse);
    });

    test('playTile rechaza cuando no es turno del local', () {
      final c = GameController(botsEnabled: false);
      final round = c.game.currentRound!;
      for (final p in round.players) {
        p.hand = [const DominoTile(0, 0)];
      }
      round.start(starterIndex: 1);
      expect(c.playTile(const DominoTile(3, 4)), isFalse);
    });
  });
}
