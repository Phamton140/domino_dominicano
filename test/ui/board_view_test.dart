import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/widgets/board_view.dart';
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

  testWidgets('renderiza sin errores con mesa vacía', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: BoardView(
              moves: [],
              starterPosition: PlayerPosition.bottom,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Esperando la primera ficha…'), findsOneWidget);
  });

  testWidgets('renderiza con varias fichas y encuentra los widgets',
      (tester) async {
    final moves = [
      mk(const DominoTile(6, 6), BoardSide.right),
      mk(const DominoTile(6, 5), BoardSide.right),
      mk(const DominoTile(5, 4), BoardSide.right),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: BoardView(
                moves: moves,
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );

    // Cada ficha se dibuja con un DominoTileWidget en la cara.
    expect(find.byType(BoardView), findsOneWidget);
  });
}
