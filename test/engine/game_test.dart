import 'package:flutter_test/flutter_test.dart';
import 'package:domino_dominicano/engine/game.dart';
import 'package:domino_dominicano/engine/models/tile.dart';

/// Ficha inútil que no coincide con los extremos más comunes.
DominoTile get _useless => const DominoTile(0, 1);

/// Reemplaza las manos de la ronda actual y fuerza un jugador inicial.
///
/// Útil para tests que necesitan escenarios deterministas sin depender
/// del reparto aleatorio.
void _forceHandsAndStarter(
  Game game,
  int starterIndex,
  List<List<DominoTile>> hands,
) {
  final round = game.currentRound!;
  for (int i = 0; i < 4; i++) {
    round.players[i].hand = List.of(hands[i]);
  }
  round.start(starterIndex: starterIndex);
}

void main() {
  group('Game', () {
    test('createLocalGame crea 4 jugadores y 2 equipos', () {
      final game = Game.createLocalGame();

      expect(game.players.length, 4);
      expect(game.teams.length, 2);
      expect(game.teams['A']!.playerIds, ['p0', 'p2']);
      expect(game.teams['B']!.playerIds, ['p1', 'p3']);
    });

    test('startNewGame inicia la partida y reparte fichas', () {
      final game = Game.createLocalGame();
      game.startNewGame();

      expect(game.status, GameStatus.inProgress);
      expect(game.roundNumber, 1);
      expect(game.currentRound, isNotNull);

      for (final player in game.players) {
        expect(player.hand.length, 7);
      }
    });

    test('la primera ronda la inicia quien tiene doble seis', () {
      final game = Game.createLocalGame();
      game.startNewGame();

      final starter = game.currentRound!.currentPlayer;
      expect(starter.hasTile(DominoTile.doubleSix), true);
    });

    test('applyPendingBonuses aplica bonificación de salida', () {
      final game = Game.createLocalGame();
      game.startNewGame();

      _forceHandsAndStarter(
        game,
        0,
        [
          [DominoTile.doubleSix, _useless],
          [_useless, _useless],
          [const DominoTile(6, 5), _useless],
          [_useless, _useless],
        ],
      );

      final round = game.currentRound!;
      round.playTile(DominoTile.doubleSix);
      round.pass();

      expect(round.pendingImmediateBonus, isNotNull);
      final teamId = round.pendingImmediateBonus!.teamId;
      game.applyPendingBonuses();

      expect(game.teams[teamId]!.score, 30);
    });

    test('la regla de los 170 bloquea bonos de pase', () {
      final game = Game.createLocalGame();
      game.startNewGame();
      game.teams['A']!.score = 170;

      _forceHandsAndStarter(
        game,
        0,
        [
          [DominoTile.doubleSix, _useless],
          [_useless, _useless],
          [const DominoTile(6, 5), _useless],
          [_useless, _useless],
        ],
      );

      final round = game.currentRound!;
      round.playTile(DominoTile.doubleSix);
      round.pass();

      game.applyPendingBonuses();

      expect(game.teams['A']!.score, 170);
    });

    test('applyRoundResult aplica puntos de dominación', () {
      final game = Game.createLocalGame();
      game.startNewGame();

      _forceHandsAndStarter(
        game,
        0,
        [
          [const DominoTile(5, 4), _useless],
          [const DominoTile(5, 6), _useless],
          [const DominoTile(4, 3)],
          [_useless, _useless],
        ],
      );

      final round = game.currentRound!;
      round.playTile(const DominoTile(5, 4));
      round.playTile(const DominoTile(5, 6));
      round.playTile(const DominoTile(4, 3));

      expect(round.isFinished, true);
      game.applyRoundResult();

      expect(game.teams[round.result!.winningTeamId]!.score,
          round.result!.pointsAwarded);
    });

    test('la partida termina al alcanzar 200 puntos', () {
      final game = Game.createLocalGame();
      game.startNewGame();
      game.teams['A']!.score = 190;

      _forceHandsAndStarter(
        game,
        0,
        [
          [const DominoTile(5, 4), _useless],
          [const DominoTile(5, 6), DominoTile.doubleSix],
          [const DominoTile(4, 3)],
          [_useless, _useless],
        ],
      );

      final round = game.currentRound!;
      round.playTile(const DominoTile(5, 4));
      round.playTile(const DominoTile(5, 6));
      round.playTile(const DominoTile(4, 3));

      game.applyRoundResult();

      expect(game.isFinished, true);
      expect(game.winnerTeamId, 'A');
    });

    test('startNextRound inicia con el ganador de la ronda anterior', () {
      final game = Game.createLocalGame();
      game.startNewGame();

      _forceHandsAndStarter(
        game,
        0,
        [
          [const DominoTile(5, 4), _useless],
          [const DominoTile(5, 6), _useless],
          [const DominoTile(4, 3)],
          [_useless, _useless],
        ],
      );

      final round = game.currentRound!;
      round.playTile(const DominoTile(5, 4));
      round.playTile(const DominoTile(5, 6));
      round.playTile(const DominoTile(4, 3));

      final winnerId = round.result!.nextRoundStarterPlayerId;
      game.applyRoundResult();
      game.startNextRound();

      expect(game.currentRound!.currentPlayer.id, winnerId);
    });
  });
}
