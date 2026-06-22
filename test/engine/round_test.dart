import 'package:flutter_test/flutter_test.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/round_result.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/engine/round.dart';

List<Player> _createPlayers() {
  return [
    Player(id: 'p0', name: 'Local', position: PlayerPosition.bottom, teamId: 'A'),
    Player(id: 'p1', name: 'Derecho', position: PlayerPosition.right, teamId: 'B'),
    Player(id: 'p2', name: 'Compañero', position: PlayerPosition.top, teamId: 'A'),
    Player(id: 'p3', name: 'Izquierdo', position: PlayerPosition.left, teamId: 'B'),
  ];
}

/// Crea una ronda con manos específicas. Las manos deben ser válidas
/// para el escenario que se quiere probar.
Round _createRoundWithHands(
  List<List<DominoTile>> hands, {
  int? starterIndex,
  bool firstRound = false,
}) {
  final players = _createPlayers();
  final round = Round(players: players);
  round.deal();

  for (int i = 0; i < 4; i++) {
    players[i].hand = List.of(hands[i]);
  }

  if (firstRound) {
    round.start();
  } else {
    round.start(starterIndex: starterIndex ?? 0);
  }

  return round;
}

/// Ficha inútil que no coincide con los extremos más comunes.
DominoTile get _useless => const DominoTile(0, 1);

void main() {
  group('Round', () {
    test('reparte 7 fichas a cada jugador', () {
      final players = _createPlayers();
      final round = Round(players: players);
      round.deal();

      for (final player in players) {
        expect(player.hand.length, 7);
      }
      expect(round.board.isEmpty, true);
    });

    test('la primera ronda inicia con el doble seis', () {
      final players = _createPlayers();
      final round = Round(players: players);
      round.deal();

      // Limpiamos manos y asignamos doble seis solo al jugador 2.
      for (final player in players) {
        player.hand = [_useless, _useless, _useless, _useless, _useless, _useless, _useless];
      }
      players[2].hand[0] = DominoTile.doubleSix;

      round.start();
      expect(round.currentPlayer.id, 'p2');
    });

    test('las rondas posteriores inician con el jugador indicado', () {
      final round = _createRoundWithHands(
        [for (var i = 0; i < 4; i++) [_useless]],
        starterIndex: 1,
      );
      expect(round.currentPlayer.id, 'p1');
    });

    test('el orden de turnos es antihorario', () {
      final round = _createRoundWithHands(
        [
          [DominoTile.doubleSix, _useless],
          [const DominoTile(6, 5), _useless],
          [const DominoTile(5, 4), _useless],
          [const DominoTile(4, 3), _useless],
        ],
        firstRound: true,
      );

      expect(round.currentPlayer.id, 'p0');
      round.playTile(DominoTile.doubleSix);
      expect(round.currentPlayer.id, 'p1');
      round.playTile(const DominoTile(6, 5));
      expect(round.currentPlayer.id, 'p2');
      round.playTile(const DominoTile(5, 4));
      expect(round.currentPlayer.id, 'p3');
    });

    test('doble punta fuerza a jugar por la derecha', () {
      // Secuencia: 6-6 | 6-5 | 5-6 → extremos 6 y 6
      final round = _createRoundWithHands(
        [
          [DominoTile.doubleSix, _useless],
          [const DominoTile(6, 5), _useless],
          [const DominoTile(5, 6), const DominoTile(6, 4)],
          [_useless, _useless],
        ],
        firstRound: true,
      );

      round.playTile(DominoTile.doubleSix); // p0
      round.playTile(const DominoTile(6, 5)); // p1, extremos 6,5
      round.playTile(const DominoTile(5, 6)); // p2, extremos 6,6

      expect(round.board.endsAreEqual, true);
      expect(round.board.rightEnd, 6);
    });

    test('cuando extremos son iguales solo se puede jugar por la derecha', () {
      final round = _createRoundWithHands(
        [
          [DominoTile.doubleSix, _useless],
          [const DominoTile(6, 5), _useless],
          [const DominoTile(5, 6), const DominoTile(6, 4)],
          [_useless, _useless],
        ],
        firstRound: true,
      );

      round.playTile(DominoTile.doubleSix);
      round.playTile(const DominoTile(6, 5));
      round.playTile(const DominoTile(5, 6));

      // p2 tiene 6-4. En doble punta solo debe poder jugar por la derecha.
      final moves = round.validMovesFor(2);
      expect(moves.length, 1);
      expect(moves.first.side, BoardSide.right);
    });

    group('Pases de salida', () {
      test('salida con doble, siguiente pasa, compañero juega => +30', () {
        final round = _createRoundWithHands(
          [
            [DominoTile.doubleSix, _useless],
            [_useless, _useless], // no puede jugar por 6
            [const DominoTile(6, 4), _useless], // compañero sí puede
            [_useless, _useless], // no puede jugar por 6
          ],
          firstRound: true,
        );

        round.playTile(DominoTile.doubleSix);
        round.pass();

        expect(round.pendingImmediateBonus, isNotNull);
        expect(round.pendingImmediateBonus!.points, 30);
        expect(round.pendingImmediateBonus!.teamId, 'A');
      });

      test('salida con doble, siguiente pasa, compañero pasa, cuarto juega => 0',
          () {
        final round = _createRoundWithHands(
          [
            [DominoTile.doubleSix, _useless],
            [_useless, _useless], // p1 pasa
            [_useless, _useless], // p2 pasa
            [const DominoTile(6, 4), _useless], // p3 puede
          ],
          firstRound: true,
        );

        round.playTile(DominoTile.doubleSix);
        round.pass();

        expect(round.pendingImmediateBonus, isNull);
      });

      test('salida con doble, todos pasan => +60', () {
        final round = _createRoundWithHands(
          [
            [DominoTile.doubleSix, _useless],
            [_useless, _useless],
            [_useless, _useless],
            [_useless, _useless],
          ],
          firstRound: true,
        );

        round.playTile(DominoTile.doubleSix);
        round.pass();

        expect(round.pendingImmediateBonus, isNotNull);
        expect(round.pendingImmediateBonus!.points, 60);
        expect(round.pendingImmediateBonus!.teamId, 'A');
      });

      test('salida con ficha normal, siguiente pasa => +60', () {
        final round = _createRoundWithHands(
          [
            [const DominoTile(5, 4), _useless],
            [_useless, _useless], // no tiene 5 ni 4
            [const DominoTile(5, 6), _useless],
            [_useless, _useless],
          ],
          starterIndex: 0,
        );

        round.playTile(const DominoTile(5, 4));
        round.pass();

        expect(round.pendingImmediateBonus, isNotNull);
        expect(round.pendingImmediateBonus!.points, 60);
        expect(round.pendingImmediateBonus!.teamId, 'A');
      });
    });

    group('Dominación y Capicúa', () {
      test('detecta dominación simple', () {
        final round = _createRoundWithHands(
          [
            [const DominoTile(5, 4), _useless],
            [const DominoTile(5, 6), _useless],
            [const DominoTile(4, 3)], // solo una ficha para dominar
            [_useless, _useless],
          ],
          starterIndex: 0,
        );

        // p0 juega 5-4. Extremos: 5, 4.
        round.playTile(const DominoTile(5, 4));
        // p1 juega 5-6. Extremos: 4, 6.
        round.playTile(const DominoTile(5, 6));
        // p2 juega 4-3 y domina.
        round.playTile(const DominoTile(4, 3));

        expect(round.isFinished, true);
        expect(round.result!.type, RoundEndType.domination);
        expect(round.result!.winningTeamId, 'A');
      });

      test('detecta capicúa cuando extremos son diferentes', () {
        final round = _createRoundWithHands(
          [
            [const DominoTile(4, 3), _useless],
            [const DominoTile(4, 5), _useless],
            [const DominoTile(3, 5)], // solo esta ficha para dominar
            [_useless, _useless],
          ],
          starterIndex: 0,
        );

        // p0 juega 4-3. Extremos: 4, 3.
        round.playTile(const DominoTile(4, 3));
        // p1 juega 4-5. Extremos: 3, 5.
        round.playTile(const DominoTile(4, 5));
        // p2 juega 3-5 y domina. Extremos antes eran 3 y 5.
        round.playTile(const DominoTile(3, 5));

        expect(round.isFinished, true);
        expect(round.result!.type, RoundEndType.capicua);
        expect(round.result!.winningTeamId, 'A');
      });
    });

    group('Tranque', () {
      test('resuelve tranque comparando manos del trancador y el siguiente', () {
        final round = _createRoundWithHands(
          [
            [DominoTile.doubleSix, _useless],
            [_useless, _useless],
            [_useless, _useless],
            [_useless, _useless],
          ],
          firstRound: true,
        );

        // p0 juega doble seis. Todos los demás pasan.
        round.playTile(DominoTile.doubleSix);
        round.pass(); // p1
        round.pass(); // p2
        round.pass(); // p3 → tranque detectado, p0 no puede jugar

        expect(round.isFinished, true);
        expect(round.result!.type, RoundEndType.tranque);
      });

      test('en empate de tranque gana quien provocó el tranque', () {
        final round = _createRoundWithHands(
          [
            [DominoTile.doubleSix, const DominoTile(0, 1)],
            [const DominoTile(0, 1), const DominoTile(2, 3)],
            [_useless, _useless],
            [_useless, _useless],
          ],
          firstRound: true,
        );

        round.playTile(DominoTile.doubleSix);
        round.pass();
        round.pass();
        round.pass();

        final trancador = round.players[0];
        final opponent = round.players[1];
        expect(trancador.handScore, 1);
        expect(opponent.handScore, 6);
        expect(round.result!.winningTeamId, trancador.teamId);
      });
    });

    group('Pase redondo', () {
      test('detecta pase redondo cuando el mismo jugador vuelve a jugar', () {
        // Configuración que evita pase de salida y genera pase redondo.
        final round = _createRoundWithHands(
          [
            [const DominoTile(5, 4), const DominoTile(4, 3)],
            [const DominoTile(4, 6), _useless],
            [_useless, _useless],
            [const DominoTile(5, 6), const DominoTile(6, 3)],
          ],
          starterIndex: 0,
        );

        // p0 juega 5-4. Extremos: 5, 4.
        round.playTile(const DominoTile(5, 4));
        // p1 juega 4-6. Extremos: 5, 6.
        round.playTile(const DominoTile(4, 6));
        // p2 pasa (no tiene 5 ni 6).
        round.pass();
        // p3 juega 5-6 por la izquierda para formar doble punta de 6.
        round.playTile(const DominoTile(5, 6), chosenSide: BoardSide.left);
        // p0 pasa (4-3 no tiene 6), p1 pasa, p2 pasa. Vuelve a p3, que tiene 6-3.
        round.pass();
        round.pass();
        round.pass();

        expect(round.currentPlayer.id, 'p3');
        expect(round.pendingImmediateBonus, isNotNull);
        expect(round.pendingImmediateBonus!.points, 30);
        expect(round.pendingImmediateBonus!.teamId, 'B');
      });
    });
  });
}
