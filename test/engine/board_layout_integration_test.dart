import 'dart:math';
import 'dart:ui';

import 'package:domino_dominicano/engine/board.dart';
import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/engine/round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Player> makePlayers() {
    return [
      Player(id: 'p0', name: 'Local', position: PlayerPosition.bottom, teamId: 'A'),
      Player(id: 'p1', name: 'Derecho', position: PlayerPosition.right, teamId: 'B'),
      Player(id: 'p2', name: 'Compañero', position: PlayerPosition.top, teamId: 'A'),
      Player(id: 'p3', name: 'Izquierdo', position: PlayerPosition.left, teamId: 'B'),
    ];
  }

  test('Round + BoardLayout: layout geométrico coherente tras varias jugadas', () {
    final players = makePlayers();
    final round = Round(players: players);
    round.deal();

    // Forzamos manos deterministas con una cadena larga que se ramifica.
    players[0].hand = [DominoTile(6, 6), DominoTile(6, 5), DominoTile(5, 4)];
    players[1].hand = [DominoTile(6, 4), DominoTile(4, 3), DominoTile(3, 2)];
    players[2].hand = [DominoTile(0, 0), DominoTile(0, 1), DominoTile(1, 2)];
    players[3].hand = [DominoTile(2, 1), DominoTile(1, 0), DominoTile(0, 5)];

    round.start(starterIndex: 0);

    // Jugamos varias rondas hasta agotar las manos o terminar.
    int safety = 30;
    while (!round.isFinished && safety-- > 0) {
      final moves = round.validMovesFor(round.currentPlayerIndex);
      if (moves.isEmpty) {
        round.pass();
      } else {
        // Elige la primera ficha jugable (puede ser cualquiera).
        round.playTile(moves.first.tile, chosenSide: moves.first.side);
      }
    }

    final moves = round.movesHistory;
    expect(moves, isNotEmpty);

    final layout = BoardLayout(
      moves: moves,
      starterPosition: PlayerPosition.bottom,
      squareSize: 40.0,
      tableBounds: const Rect.fromLTWH(0, 0, 600, 600),
    );

    final geometries = layout.compute();
    expect(geometries, hasLength(moves.length));

    // Sin solapamiento y todas las fichas dentro de la mesa.
    const table = Rect.fromLTWH(0, 0, 600, 600);
    for (int i = 0; i < geometries.length; i++) {
      final g = geometries[i];
      expect(
        g.bounds.left >= table.left &&
            g.bounds.right <= table.right &&
            g.bounds.top >= table.top &&
            g.bounds.bottom <= table.bottom,
        isTrue,
        reason: 'ficha ${g.move.tile} fuera de mesa: ${g.bounds}',
      );
      for (int j = i + 1; j < geometries.length; j++) {
        expect(
          g.overlaps(geometries[j]),
          isFalse,
          reason: 'fichas $i y $j se solapan',
        );
      }
    }
  });

  test('Board y BoardLayout producen los mismos centros para el primer movimiento', () {
    final board = Board();
    board.placeFirst(DominoTile(6, 6));
    board.placeOnRight(DominoTile(6, 5));

    // El Move del Round para esa jugada, construido a mano.
    final player = Player(
      id: 'p0',
      name: 'Local',
      position: PlayerPosition.bottom,
      teamId: 'A',
    );
    final move1 = Move(
      player: player,
      tile: DominoTile(6, 6),
      side: BoardSide.right,
      tileWasSwapped: false,
    );
    final move2 = Move(
      player: player,
      tile: DominoTile(6, 5),
      side: BoardSide.right,
      tileWasSwapped: false,
    );

    final layout = BoardLayout(
      moves: [move1, move2],
      starterPosition: PlayerPosition.bottom,
      squareSize: 40.0,
      tableBounds: const Rect.fromLTWH(0, 0, 600, 600),
    );
    final gs = layout.compute();
    expect(gs, hasLength(2));
    // La primera ficha debe estar en el centro de la mesa.
    expect(gs[0].center.dx, closeTo(300, 1));
    expect(gs[0].center.dy, closeTo(300, 1));
  });

  test('stress: ronda larga aleatoria no produce solapes (mesa amplia)', () {
    final players = makePlayers();
    final round = Round(players: players, random: Random(42));
    round.deal();
    round.start(); // primera ronda: doble seis

    int safety = 50;
    while (!round.isFinished && safety-- > 0) {
      final moves = round.validMovesFor(round.currentPlayerIndex);
      if (moves.isEmpty) {
        round.pass();
      } else {
        round.playTile(moves.first.tile, chosenSide: moves.first.side);
      }
    }

    final moves = round.movesHistory;
    if (moves.isEmpty) return; // puede que el doble seis no haya salido

    // Mesa suficientemente grande: 2000x2000 con squareSize=40 admite
    // una ronda completa de 28 fichas sin necesidad de backtracking.
    final layout = BoardLayout(
      moves: moves,
      starterPosition: PlayerPosition.bottom,
      squareSize: 40.0,
      tableBounds: const Rect.fromLTWH(0, 0, 2000, 2000),
    );

    final geometries = layout.compute();
    expect(geometries, hasLength(moves.length));

    for (int i = 0; i < geometries.length; i++) {
      for (int j = i + 1; j < geometries.length; j++) {
        expect(geometries[i].overlaps(geometries[j]), isFalse);
      }
    }
  });
}
