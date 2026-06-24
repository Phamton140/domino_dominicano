import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/widgets/domino_tile_widget.dart';
import 'package:domino_dominicano/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DominoTileWidget', () {
    testWidgets('renderiza con el color de cara correcto', (tester) async {
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
                squareSize: 40,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
      expect(widget.tile, isNotNull);
      expect(widget.tile!.left, 3);
      expect(widget.tile!.right, 5);
    });

    testWidgets('modo lomo con tile null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DominoTileWidget(
                tile: null,
                orientation: TileOrientation.horizontal,
                connectedEdge: ConnectedEdge.left,
                connectedValue: 0,
                freeValue: 0,
                squareSize: 40,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
      expect(widget.tile, isNull);
      expect(widget.dim, isFalse);
    });

    testWidgets('destaca cuando highlighted es true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DominoTileWidget(
                tile: DominoTile(0, 0),
                orientation: TileOrientation.horizontal,
                connectedEdge: ConnectedEdge.left,
                connectedValue: 0,
                freeValue: 0,
                squareSize: 40,
                highlighted: true,
              ),
            ),
          ),
        ),
      );

      final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
      expect(widget.highlighted, isTrue);
    });
  });

  // Smoke test del theme: importado para verificar que se compila.
  test('DominoTheme tiene colores no nulos', () {
    expect(DominoTheme.tileFace, isA<Color>());
    expect(DominoTheme.tableGreen, isA<Color>());
  });
}
