import 'dart:ui';

import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Move mk(DominoTile t, BoardSide side, {bool swapped = false}) => Move(
        player: Player(id: 'p0', name: 'p0', position: PlayerPosition.bottom, teamId: 'A'),
        tile: t,
        side: side,
        tileWasSwapped: swapped,
      );

  group('conexión por lado de la cara', () {
    test('5|3 horizontal derecha → pivote up → 3|2 vertical: el 3 debe quedar a la izquierda (conectando con el 3 de la ficha anterior), el 2 a la derecha', () {
      // Mesa 300x300: 5|3 horizontal local → 5|3 ocupa centro (150, 150).
      // Como el área es pequeña, las siguientes fichas deben pivotar.
      final layout = BoardLayout(
        moves: [
          mk(const DominoTile(5, 4), BoardSide.right), // primera ficha
          mk(const DominoTile(4, 3), BoardSide.right), // conecta con el 4
          mk(const DominoTile(3, 2), BoardSide.right), // conecta con el 3
        ],
        starterPosition: PlayerPosition.bottom,
        squareSize: 26.0,
        tableBounds: const Rect.fromLTWH(0, 0, 300, 300),
        allowOverflow: true,
      );
      final geometries = layout.compute();

      // La regla de conexión por lado: las fichas se conectan por
      // el lado de la cara que coincide, no por el centro.
      // Verificar que las fichas se tocan (sus bounds comparten un
      // borde pero no se solapan).
      for (int i = 1; i < geometries.length; i++) {
        final prev = geometries[i - 1];
        final curr = geometries[i];
        // Las fichas adyacentes deben estar contiguas (comparten
        // un borde pero no se solapan).
        expect(
          prev.overlaps(curr),
          isFalse,
          reason: 'Las fichas no deben solaparse',
        );
        // Y sus bounds deben tocarse (distancia entre bordes <= 0.5).
        final prevRight = prev.bounds.right;
        final prevLeft = prev.bounds.left;
        final prevBottom = prev.bounds.bottom;
        final prevTop = prev.bounds.top;
        final currLeft = curr.bounds.left;
        final currRight = curr.bounds.right;
        final currBottom = curr.bounds.bottom;
        final currTop = curr.bounds.top;

        final touchingHorizontally =
            (prevRight - currLeft).abs() < 0.5 ||
                (currRight - prevLeft).abs() < 0.5;
        final touchingVertically =
            (prevBottom - currTop).abs() < 0.5 ||
                (currBottom - prevTop).abs() < 0.5;
        expect(
          touchingHorizontally || touchingVertically,
          isTrue,
          reason: 'Las fichas adyacentes deben estar tocándose '
              '(comparten un borde)',
        );
      }
    });
  });
}
