import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/widgets/domino_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DominoTileWidget: renderizado por connectedEdge', () {
    testWidgets('horizontal, connectedEdge=left: connectedValue a la izquierda',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DominoTileWidget(
                tile: DominoTile(3, 5),
                orientation: TileOrientation.horizontal,
                connectedEdge: ConnectedEdge.left,
                connectedValue: 3,
                freeValue: 5,
                squareSize: 30,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
      expect(widget.connectedEdge, ConnectedEdge.left);
      expect(widget.connectedValue, 3);
      expect(widget.freeValue, 5);
    });

    testWidgets(
        'horizontal, connectedEdge=right: connectedValue a la derecha',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DominoTileWidget(
                tile: DominoTile(3, 5),
                orientation: TileOrientation.horizontal,
                connectedEdge: ConnectedEdge.right,
                connectedValue: 5,
                freeValue: 3,
                squareSize: 30,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
      expect(widget.connectedEdge, ConnectedEdge.right);
      expect(widget.connectedValue, 5);
      expect(widget.freeValue, 3);
    });

    testWidgets('vertical, connectedEdge=top: connectedValue arriba',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DominoTileWidget(
                tile: DominoTile(3, 5),
                orientation: TileOrientation.vertical,
                connectedEdge: ConnectedEdge.top,
                connectedValue: 3,
                freeValue: 5,
                squareSize: 30,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
      expect(widget.connectedEdge, ConnectedEdge.top);
      expect(widget.connectedValue, 3);
      expect(widget.freeValue, 5);
    });

    testWidgets('vertical, connectedEdge=bottom: connectedValue abajo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DominoTileWidget(
                tile: DominoTile(3, 5),
                orientation: TileOrientation.vertical,
                connectedEdge: ConnectedEdge.bottom,
                connectedValue: 5,
                freeValue: 3,
                squareSize: 30,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
      expect(widget.connectedEdge, ConnectedEdge.bottom);
      expect(widget.connectedValue, 5);
      expect(widget.freeValue, 3);
    });
  });
}
