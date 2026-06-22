import 'dart:ui';

import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const double ss = 40.0;
  const Rect table = Rect.fromLTWH(0, 0, 400, 400);
  const Rect tinyTable = Rect.fromLTWH(0, 0, 80, 80);

  DominoTile t(int l, int r) => DominoTile(l, r);
  Player player(int id) => Player(
        id: 'p$id',
        name: 'p$id',
        position: PlayerPosition.bottom,
        teamId: 'A',
      );

  Move mk(DominoTile tile, BoardSide side, {bool swapped = false}) {
    return Move(
      player: player(0),
      tile: tile,
      side: side,
      tileWasSwapped: swapped,
    );
  }

  BoardLayout build(List<Move> moves, Rect bounds, {PlayerPosition starter = PlayerPosition.bottom}) {
    return BoardLayout(
      moves: moves,
      starterPosition: starter,
      squareSize: ss,
      tableBounds: bounds,
    );
  }

  group('BoardLayout', () {
    test('sin moves devuelve lista vacía', () {
      expect(build([], table).compute(), isEmpty);
    });

    test('primera ficha siempre se centra en la mesa', () {
      final gs = build([mk(t(3, 2), BoardSide.right)], table).compute();
      expect(gs, hasLength(1));
      expect(gs.first.center, table.center);
    });

    group('orientación de la primera ficha', () {
      test('local con doble → horizontal', () {
        final gs = build([mk(t(6, 6), BoardSide.right)], table).compute();
        expect(gs.first.orientation, TileOrientation.horizontal);
      });

      test('compañero con doble → horizontal', () {
        final gs = build(
          [mk(t(6, 6), BoardSide.right)],
          table,
          starter: PlayerPosition.top,
        ).compute();
        expect(gs.first.orientation, TileOrientation.horizontal);
      });

      test('adversario con doble → vertical', () {
        final gs = build(
          [mk(t(6, 6), BoardSide.right)],
          table,
          starter: PlayerPosition.right,
        ).compute();
        expect(gs.first.orientation, TileOrientation.vertical);
      });

      test('local con ficha normal → vertical', () {
        final gs = build([mk(t(5, 4), BoardSide.right)], table).compute();
        expect(gs.first.orientation, TileOrientation.vertical);
      });

      test('adversario con ficha normal → horizontal', () {
        final gs = build(
          [mk(t(5, 4), BoardSide.right)],
          table,
          starter: PlayerPosition.right,
        ).compute();
        expect(gs.first.orientation, TileOrientation.horizontal);
      });
    });

    group('cadena simple', () {
      test('segunda ficha a la derecha encaja pegada', () {
        final gs = build([
          mk(t(6, 6), BoardSide.right),
          mk(t(6, 5), BoardSide.right),
        ], table).compute();

        expect(gs, hasLength(2));
        // Distancia entre centros = 2*squareSize (ancho completo de la ficha).
        expect(gs[1].center.dx, gs[0].center.dx + 2 * ss);
        expect(gs[1].center.dy, gs[0].center.dy);
        expect(gs[1].overlaps(gs[0]), isFalse);
      });

      test('segunda ficha a la izquierda encaja pegada', () {
        final gs = build([
          mk(t(6, 6), BoardSide.right),
          mk(t(6, 4), BoardSide.left),
        ], table).compute();

        expect(gs, hasLength(2));
        expect(gs[1].center.dx, gs[0].center.dx - 2 * ss);
        expect(gs[1].center.dy, gs[0].center.dy);
        expect(gs[1].overlaps(gs[0]), isFalse);
      });
    });

    group('dobles perpendiculares', () {
      test('doble sobre ficha horizontal queda vertical', () {
        final gs = build([
          mk(t(6, 6), BoardSide.right),
          mk(t(6, 3), BoardSide.right),
          mk(t(3, 3), BoardSide.right),
        ], table).compute();

        expect(gs[0].orientation, TileOrientation.horizontal);
        expect(gs[1].orientation, TileOrientation.horizontal);
        expect(gs[2].orientation, TileOrientation.vertical);
      });

      test('doble sobre ficha vertical queda horizontal', () {
        final gs = build([
          mk(t(5, 4), BoardSide.right), // local+normal → vertical
          mk(t(4, 3), BoardSide.right), // normal sobre vertical hacia right → horizontal
          mk(t(3, 3), BoardSide.right), // doble sobre horizontal → vertical
        ], table).compute();

        expect(gs[0].orientation, TileOrientation.vertical);
        expect(gs[1].orientation, TileOrientation.horizontal);
        expect(gs[2].orientation, TileOrientation.vertical);
      });
    });

    group('crecimiento en Z', () {
      test('al chocar con el borde la cadena gira 90°', () {
        // Mesa pequeña que sólo permite 2 fichas en línea antes del borde.
        // Centro (200,200), 6-6 horizontal local: ocupa 160..240 en X.
        // La siguiente (6-5) sigue horizontal: centro 280, ocupa 240..320.
        // La siguiente (5-4) intentaría centro 360 → topRight X=400, en el
        // borde. La siguiente (4-3) ya no cabría sin girar.
        const zTable = Rect.fromLTWH(0, 0, 360, 360);
        final gs = build([
          mk(t(6, 6), BoardSide.right),
          mk(t(6, 5), BoardSide.right),
          mk(t(5, 4), BoardSide.right),
          mk(t(4, 3), BoardSide.right),
        ], zTable).compute();

        expect(gs, hasLength(4));
        // Las dos primeras se mantienen horizontales en la misma línea.
        expect(gs[0].center.dy, gs[1].center.dy);
        // La tercera o la cuarta ficha debe haber girado (estar en otra línea).
        final lastGrewHorizontal = gs[3].center.dy == gs[1].center.dy;
        expect(
          lastGrewHorizontal,
          isFalse,
          reason: 'Se esperaba que la cadena girara al llegar al borde derecho',
        );
      });
    });

    group('invariantes', () {
      test('ningún par de fichas se solapa', () {
        final gs = build([
          mk(t(6, 6), BoardSide.right),
          mk(t(6, 5), BoardSide.right),
          mk(t(5, 4), BoardSide.right),
          mk(t(4, 3), BoardSide.right),
          mk(t(3, 2), BoardSide.left),
        ], table).compute();

        for (int i = 0; i < gs.length; i++) {
          for (int j = i + 1; j < gs.length; j++) {
            expect(
              gs[i].overlaps(gs[j]),
              isFalse,
              reason: 'fichas $i y $j se solapan: '
                  '${gs[i].bounds} vs ${gs[j].bounds}',
            );
          }
        }
      });

      test('todas las fichas caben dentro de la mesa', () {
        final gs = build([
          mk(t(6, 6), BoardSide.right),
          mk(t(6, 5), BoardSide.right),
          mk(t(5, 4), BoardSide.right),
          mk(t(4, 3), BoardSide.left),
          mk(t(3, 2), BoardSide.left),
        ], table).compute();

        for (final g in gs) {
          expect(
            g.bounds.left >= table.left &&
                g.bounds.right <= table.right &&
                g.bounds.top >= table.top &&
                g.bounds.bottom <= table.bottom,
            isTrue,
            reason: 'ficha ${g.move.tile} fuera de mesa: ${g.bounds}',
          );
        }
      });
    });

    group('errores', () {
      test('lanza StateError si la mesa no tiene espacio tras 4 rotaciones', () {
        final layout = build([
          mk(t(6, 6), BoardSide.right),
          mk(t(6, 5), BoardSide.right),
          mk(t(5, 4), BoardSide.right),
          mk(t(4, 3), BoardSide.right),
          mk(t(3, 2), BoardSide.right),
        ], tinyTable);
        expect(layout.compute, throwsStateError);
      });
    });
  });
}
