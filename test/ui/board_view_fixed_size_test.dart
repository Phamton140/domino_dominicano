import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/widgets/board_view.dart';
import 'package:domino_dominicano/ui/widgets/domino_tile_widget.dart';
import 'package:flutter/material.dart';
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
      );

  /// Captura el squareSize de cada ficha renderizada dentro de un
  /// BoardView dado el conjunto de moves.
  List<double> _tileSquareSizes(WidgetTester tester) {
    return tester
        .widgetList<DominoTileWidget>(find.byType(DominoTileWidget))
        .map((w) => w.squareSize)
        .toList();
  }

  testWidgets('mesa: 1 ficha usa kBoardTileSquareSize', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: BoardView(
                moves: [mk(const DominoTile(6, 6), BoardSide.right)],
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );

    final sizes = _tileSquareSizes(tester);
    expect(sizes, hasLength(1));
    expect(sizes.first, kBoardTileSquareSize);
  });

  testWidgets('mesa: añadir fichas NO cambia el tamaño de las anteriores',
      (tester) async {
    final moves = <Move>[
      mk(const DominoTile(6, 6), BoardSide.right),
      mk(const DominoTile(6, 5), BoardSide.right),
      mk(const DominoTile(5, 4), BoardSide.right),
      mk(const DominoTile(4, 3), BoardSide.right),
      mk(const DominoTile(3, 2), BoardSide.right),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              height: 600,
              child: BoardView(
                moves: moves,
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );

    final sizes = _tileSquareSizes(tester);
    expect(sizes, hasLength(5));
    // TODAS las fichas tienen exactamente el mismo squareSize.
    for (final s in sizes) {
      expect(s, kBoardTileSquareSize,
          reason: 'Ninguna ficha debe cambiar de tamaño');
    }
  });

  testWidgets('mesa: las fichas son siempre 1:2 o 1:1 según orientación',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              height: 600,
              child: BoardView(
                moves: [
                  mk(const DominoTile(6, 6), BoardSide.right),
                  mk(const DominoTile(6, 5), BoardSide.right),
                ],
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );

    for (final w in tester.widgetList<DominoTileWidget>(find.byType(DominoTileWidget))) {
      if (w.orientation == TileOrientation.horizontal) {
        expect(w.squareSize * 2, w.orientation == TileOrientation.horizontal
            ? w.squareSize * 2
            : w.squareSize);
        // 2:1: ancho = 2*squareSize, alto = squareSize.
        expect(w.squareSize, kBoardTileSquareSize);
      } else {
        // 1:2: ancho = squareSize, alto = 2*squareSize.
        expect(w.squareSize, kBoardTileSquareSize);
      }
    }
  });
}
