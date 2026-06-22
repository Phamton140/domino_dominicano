import 'dart:ui';

import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Move mk(DominoTile t, BoardSide side) => Move(
        player: Player(
          id: 'p0',
          name: 'p0',
          position: PlayerPosition.bottom,
          teamId: 'A',
        ),
        tile: t,
        side: side,
        tileWasSwapped: false,
      );

  group('primera ficha centrada en la mesa', () {
    test('una sola ficha está en el centro de la mesa', () {
      const table = Rect.fromLTWH(0, 0, 400, 400);
      final layout = BoardLayout(
        moves: [mk(const DominoTile(6, 6), BoardSide.right)],
        starterPosition: PlayerPosition.bottom,
        squareSize: 30,
        tableBounds: table,
      );
      final gs = layout.compute();
      expect(gs.first.center, table.center);
    });

    test('la primera ficha permanece en el centro tras añadir varias fichas', () {
      const table = Rect.fromLTWH(0, 0, 800, 600);
      final layout = BoardLayout(
        moves: [
          mk(const DominoTile(6, 6), BoardSide.right),
          mk(const DominoTile(6, 5), BoardSide.right),
          mk(const DominoTile(5, 4), BoardSide.right),
          mk(const DominoTile(4, 3), BoardSide.right),
          mk(const DominoTile(3, 2), BoardSide.right),
        ],
        starterPosition: PlayerPosition.bottom,
        squareSize: 30,
        tableBounds: table,
      );
      final gs = layout.compute();
      // La primera ficha SIEMPRE está en el centro, no importa lo que
      // se coloque después. Sirve como referencia visual para los
      // jugadores.
      expect(gs.first.center, table.center);
    });

    test('el centro de la primera ficha es independiente del tamaño de la mesa', () {
      final layout1 = BoardLayout(
        moves: [mk(const DominoTile(6, 6), BoardSide.right)],
        starterPosition: PlayerPosition.bottom,
        squareSize: 30,
        tableBounds: const Rect.fromLTWH(0, 0, 1000, 1000),
      );
      final layout2 = BoardLayout(
        moves: [mk(const DominoTile(6, 6), BoardSide.right)],
        starterPosition: PlayerPosition.bottom,
        squareSize: 30,
        tableBounds: const Rect.fromLTWH(0, 0, 500, 500),
      );
      expect(
        layout1.compute().first.center,
        const Offset(500, 500),
        reason: 'Mesa 1000x1000: centro debe ser (500, 500)',
      );
      expect(
        layout2.compute().first.center,
        const Offset(250, 250),
        reason: 'Mesa 500x500: centro debe ser (250, 250)',
      );
    });
  });
}
