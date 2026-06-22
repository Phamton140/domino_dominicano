import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/widgets/domino_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('swapped=true: los pips se dibujan en el orden visual swap',
      (tester) async {
    // Ficha 3|5 swap → se ve como 5|3 (5 a la izquierda, 3 a la derecha).
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DominoTileWidget(
              tile: DominoTile(3, 5),
              orientation: TileOrientation.horizontal,
              squareSize: 30,
              swapped: true,
            ),
          ),
        ),
      ),
    );

    final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
    expect(widget.swapped, isTrue);
    // El tile original sigue siendo 3|5.
    expect(widget.tile!.left, 3);
    expect(widget.tile!.right, 5);
  });

  testWidgets('swapped=false: pips en el orden natural de la ficha',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DominoTileWidget(
              tile: DominoTile(3, 5),
              orientation: TileOrientation.horizontal,
              squareSize: 30,
              swapped: false,
            ),
          ),
        ),
      ),
    );

    final widget = tester.widget<DominoTileWidget>(find.byType(DominoTileWidget));
    expect(widget.swapped, isFalse);
  });
}
