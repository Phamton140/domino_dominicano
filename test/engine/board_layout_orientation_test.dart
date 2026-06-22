import 'dart:ui';

import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Move mk(DominoTile t, BoardSide side) => Move(
        player: Player(id: 'p0', name: 'p0', position: PlayerPosition.bottom, teamId: 'A'),
        tile: t,
        side: side,
        tileWasSwapped: false,
      );

  test('mesa portrait: el tableBounds es más alto que ancho', () {
    // El juego está diseñado para pantalla vertical (portrait).
    // El área de juego típica es 320x500 o similar: más alta que
    // ancha. La cadena debe crecer principalmente en Y (vertical)
    // antes de verse forzada a pivotar.
    final layout = BoardLayout(
      moves: [
        mk(const DominoTile(6, 6), BoardSide.right),
        for (int i = 0; i < 10; i++)
          mk(const DominoTile(6, 5), BoardSide.right),
      ],
      starterPosition: PlayerPosition.bottom,
      squareSize: 26.0,
      // Mesa alta y estrecha: 300x800.
      tableBounds: const Rect.fromLTWH(0, 0, 300, 800),
      allowOverflow: true,
    );
    final geometries = layout.compute();

    // La cadena debe caber en el área.
    for (final g in geometries) {
      final b = g.bounds;
      expect(b.left, lessThanOrEqualTo(300));
      expect(b.right, lessThanOrEqualTo(300));
      expect(b.top, lessThanOrEqualTo(800));
      expect(b.bottom, lessThanOrEqualTo(800));
    }

    // Como el área es más alta que ancha, la cadena debe crecer
    // principalmente en Y. La primera ficha está en (150, 400).
    // Las siguientes se colocan hacia abajo (pivotando a up) porque
    // el ancho se agota antes que el alto.
    final firstY = geometries.first.center.dy;
    int consecutiveSameY = 0;
    for (final g in geometries) {
      if ((g.center.dy - firstY).abs() < 1) {
        consecutiveSameY++;
      } else {
        break;
      }
    }
    // Con 300px de ancho y 52px por ficha, caben ~5 fichas en
    // horizontal. Después la cadena pivota a up/down.
    expect(consecutiveSameY, greaterThanOrEqualTo(3),
        reason: 'La cadena debe crecer en X mientras haya espacio, '
            'luego pivota a vertical para usar el alto disponible');
  });

  test('mesa landscape: la cadena se adapta al área más ancha', () {
    // Aunque el juego está diseñado para portrait, validamos que
    // el algoritmo también funciona en landscape. La cadena debe
    // crecer principalmente en X.
    final layout = BoardLayout(
      moves: [
        mk(const DominoTile(6, 6), BoardSide.right),
        for (int i = 0; i < 10; i++)
          mk(const DominoTile(6, 5), BoardSide.right),
      ],
      starterPosition: PlayerPosition.bottom,
      squareSize: 26.0,
      tableBounds: const Rect.fromLTWH(0, 0, 800, 300),
      allowOverflow: true,
    );
    final geometries = layout.compute();

    for (final g in geometries) {
      final b = g.bounds;
      expect(b.left, lessThanOrEqualTo(800));
      expect(b.right, lessThanOrEqualTo(800));
    }

    // Con 800px de ancho, caben más fichas en X antes de pivotar.
    final firstY = geometries.first.center.dy;
    int consecutiveSameY = 0;
    for (final g in geometries) {
      if ((g.center.dy - firstY).abs() < 1) {
        consecutiveSameY++;
      } else {
        break;
      }
    }
    expect(consecutiveSameY, greaterThanOrEqualTo(5),
        reason: 'En landscape la cadena debe crecer más en X');
  });
}
