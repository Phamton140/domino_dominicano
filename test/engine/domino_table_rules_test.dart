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

  group('Reglas de la mesa de Dominó Dominicano', () {
    test('escenario del ejemplo: 6-5, 5-3, 3-3, 3-1, 1-4', () {
      final layout = BoardLayout(
        moves: [
          mk(const DominoTile(6, 5), BoardSide.right),
          mk(const DominoTile(5, 3), BoardSide.right),
          mk(const DominoTile(3, 3), BoardSide.right),
          mk(const DominoTile(3, 1), BoardSide.right),
          mk(const DominoTile(1, 4), BoardSide.right),
        ],
        starterPosition: PlayerPosition.bottom,
        squareSize: 26.0,
        // Mesa grande para que la cadena crezca sin pivotar.
        tableBounds: const Rect.fromLTWH(0, 0, 800, 600),
        allowOverflow: true,
      );
      final gs = layout.compute();

      // Regla 4: las fichas no se solapan.
      for (int i = 0; i < gs.length; i++) {
        for (int j = i + 1; j < gs.length; j++) {
          expect(gs[i].overlaps(gs[j]), isFalse,
              reason: 'fichas $i y $j no deben solaparse');
        }
      }

      // Regla 8: el doble 3-3 debe ser perpendicular a la dirección
      // de crecimiento. Como la cadena creció en right, el doble es
      // vertical.
      final doble = gs[2];
      expect(doble.move.tile.isDouble, isTrue);
      expect(doble.orientation, TileOrientation.vertical,
          reason: 'El doble 3-3 debe ser perpendicular a la dirección right');
    });

    test('dobles siempre perpendiculares a la dirección de crecimiento', () {
      // 6-6 (doble, dirección right) → 6-3 → 3-3 (doble, sigue right)
      // → 3-1 → 1-2 → 2-2 (doble, sigue right)
      final layout = BoardLayout(
        moves: [
          mk(const DominoTile(6, 6), BoardSide.right),
          mk(const DominoTile(6, 3), BoardSide.right),
          mk(const DominoTile(3, 3), BoardSide.right),
          mk(const DominoTile(3, 1), BoardSide.right),
          mk(const DominoTile(1, 2), BoardSide.right),
          mk(const DominoTile(2, 2), BoardSide.right),
        ],
        starterPosition: PlayerPosition.bottom,
        squareSize: 26.0,
        tableBounds: const Rect.fromLTWH(0, 0, 1000, 600),
        allowOverflow: true,
      );
      final gs = layout.compute();

      // 6-6: dirección right → doble horizontal.
      expect(gs[0].orientation, TileOrientation.horizontal);
      // 6-3: ficha normal, dirección right → horizontal.
      expect(gs[1].orientation, TileOrientation.horizontal);
      // 3-3: doble, dirección right → perpendicular = vertical.
      expect(gs[2].orientation, TileOrientation.vertical);
      // 3-1: ficha normal, dirección right → horizontal.
      expect(gs[3].orientation, TileOrientation.horizontal);
      // 1-2: ficha normal, dirección right → horizontal.
      expect(gs[4].orientation, TileOrientation.horizontal);
      // 2-2: doble, dirección right → perpendicular = vertical.
      expect(gs[5].orientation, TileOrientation.vertical);
    });

    test('fichas después de doble siguen la dirección de crecimiento (NO el eje del doble)', () {
      // 6-6 (doble horizontal, dirección right) → 6-3 (dirección right)
      // → 3-3 (doble vertical) → 3-1 (debe ser horizontal, NO vertical)
      final layout = BoardLayout(
        moves: [
          mk(const DominoTile(6, 6), BoardSide.right),
          mk(const DominoTile(6, 3), BoardSide.right),
          mk(const DominoTile(3, 3), BoardSide.right),
          mk(const DominoTile(3, 1), BoardSide.right),
        ],
        starterPosition: PlayerPosition.bottom,
        squareSize: 26.0,
        tableBounds: const Rect.fromLTWH(0, 0, 1000, 600),
        allowOverflow: true,
      );
      final gs = layout.compute();

      // Después del doble vertical 3-3, la ficha 3-1 debe ser horizontal
      // (sigue la dirección right, NO hereda la vertical del doble).
      expect(gs[3].orientation, TileOrientation.horizontal,
          reason: 'La ficha después de un doble sigue la dirección de '
              'crecimiento, no el eje del doble');
    });

    test('cadena pivotada no tiene solapamientos (fichas anteriores no se mueven)', () {
      // Cadena larga que obliga a pivotar. Verifica que no haya
      // solapamiento, lo que confirma que las fichas anteriores al
      // pivote mantienen su posición y las nuevas se adaptan.
      final layout = BoardLayout(
        moves: [
          for (int i = 0; i < 10; i++)
            mk(DominoTile(6, 5), BoardSide.right),
        ],
        starterPosition: PlayerPosition.bottom,
        squareSize: 26.0,
        // Mesa pequeña que obliga a pivotar.
        tableBounds: const Rect.fromLTWH(0, 0, 200, 200),
        allowOverflow: true,
      );
      final gs = layout.compute();

      for (int i = 0; i < gs.length; i++) {
        for (int j = i + 1; j < gs.length; j++) {
          expect(gs[i].overlaps(gs[j]), isFalse,
              reason: 'fichas $i y $j no deben solaparse (fichas '
                  'anteriores no se mueven)');
        }
      }
    });

    test('no hay solapamiento en ninguna cadena', () {
      // Genera 5 cadenas aleatorias y verifica no overlap.
      for (int seed = 0; seed < 5; seed++) {
        final moves = <Move>[];
        final random = seed * 7 + 13;
        for (int i = 0; i < 10; i++) {
          final a = (i * 3 + random) % 7;
          final b = (i * 5 + random + 1) % 7;
          moves.add(mk(DominoTile(a, b), BoardSide.right));
        }
        final layout = BoardLayout(
          moves: moves,
          starterPosition: PlayerPosition.bottom,
          squareSize: 26.0,
          tableBounds: const Rect.fromLTWH(0, 0, 300, 300),
          allowOverflow: true,
        );
        final gs = layout.compute();
        for (int i = 0; i < gs.length; i++) {
          for (int j = i + 1; j < gs.length; j++) {
            expect(gs[i].overlaps(gs[j]), isFalse,
                reason: 'seed=$seed: fichas $i y $j no deben solaparse');
          }
        }
      }
    });
  });
}
