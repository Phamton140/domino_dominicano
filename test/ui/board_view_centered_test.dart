import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/widgets/board_view.dart';
import 'package:domino_dominicano/ui/widgets/domino_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Move mk(DominoTile t, BoardSide side) => Move(
        player: Player(id: 'p0', name: 'p0', position: PlayerPosition.bottom, teamId: 'A'),
        tile: t,
        side: side,
        tileWasSwapped: false,
      );

  /// Devuelve el rect del BoardView (el área de juego fija).
  Rect boardViewRect(WidgetTester tester) {
    return tester.getRect(find.byType(BoardView));
  }

  /// Devuelve el rect de la primera ficha renderizada.
  Rect firstTileRect(WidgetTester tester) {
    final widgets =
        tester.widgetList<DominoTileWidget>(find.byType(DominoTileWidget));
    return tester.getRect(find.byWidget(widgets.first));
  }

  testWidgets('área de juego: tiene el mismo tamaño con/sin fichas',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: 400,
              child: BoardView(
                moves: const [],
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final emptyRect = boardViewRect(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: 400,
              child: BoardView(
                moves: [
                  mk(const DominoTile(6, 6), BoardSide.right),
                  mk(const DominoTile(6, 5), BoardSide.right),
                  mk(const DominoTile(5, 4), BoardSide.right),
                  mk(const DominoTile(4, 3), BoardSide.right),
                  mk(const DominoTile(3, 2), BoardSide.right),
                ],
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final fullRect = boardViewRect(tester);

    expect(emptyRect, fullRect,
        reason: 'El área de juego no debe cambiar de tamaño con las fichas');
  });

  testWidgets('primera ficha está en el centro del área de juego',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: 400,
              child: BoardView(
                moves: [
                  mk(const DominoTile(6, 6), BoardSide.right),
                  mk(const DominoTile(6, 5), BoardSide.right),
                  mk(const DominoTile(5, 4), BoardSide.right),
                  mk(const DominoTile(4, 3), BoardSide.right),
                  mk(const DominoTile(3, 2), BoardSide.right),
                ],
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boardRect = boardViewRect(tester);
    final firstRect = firstTileRect(tester);
    final boardCenter = boardRect.center;
    final firstCenter = firstRect.center;

    expect(
      (firstCenter.dx - boardCenter.dx).abs() < 3,
      isTrue,
      reason: 'Centro X de la primera ficha ($firstCenter) debe coincidir '
          'con el centro del área ($boardCenter)',
    );
    expect(
      (firstCenter.dy - boardCenter.dy).abs() < 3,
      isTrue,
      reason: 'Centro Y de la primera ficha ($firstCenter) debe coincidir '
          'con el centro del área ($boardCenter)',
    );
  });

  testWidgets('primera ficha en el centro con 1 sola ficha', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: BoardView(
                moves: [mk(const DominoTile(6, 6), BoardSide.right)],
                starterPosition: PlayerPosition.bottom,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boardRect = boardViewRect(tester);
    final firstRect = firstTileRect(tester);
    final boardCenter = boardRect.center;
    final firstCenter = firstRect.center;

    expect(
      (firstCenter.dx - boardCenter.dx).abs() < 3,
      isTrue,
    );
    expect(
      (firstCenter.dy - boardCenter.dy).abs() < 3,
      isTrue,
    );
  });
}
