import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/widgets/domino_tile_widget.dart';
import 'package:domino_dominicano/ui/widgets/hand_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mano local: fichas tienen ancho < alto (vertical)', (tester) async {
    final player = Player(
      id: 'p0',
      name: 'Local',
      position: PlayerPosition.bottom,
      teamId: 'A',
    );
    final tiles = <DominoTile>[
      const DominoTile(6, 6),
      const DominoTile(5, 3),
      const DominoTile(0, 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 100,
            child: HandView(
              player: player,
              tiles: tiles,
              faceUp: true,
              squareSize: 30,
            ),
          ),
        ),
      ),
    );

    // Cada DominoTileWidget con orientación vertical debe medir
    // width = 30 y height = 60 (2*squareSize).
    final tileWidgets = tester.widgetList<DominoTileWidget>(
      find.byType(DominoTileWidget),
    );
    expect(tileWidgets, hasLength(3));
    for (final w in tileWidgets) {
      expect(w.orientation, TileOrientation.vertical,
          reason: 'La ficha debería estar en orientación vertical');
    }

    // Verificamos también el tamaño concreto del Container.
    for (final tw in tileWidgets) {
      final container = tester.widgetList<Container>(
        find.descendant(
          of: find.byWidget(tw),
          matching: find.byType(Container),
        ),
      ).first;
      final box = tester.renderObject<RenderBox>(find.byWidget(container));
      // Ficha vertical 1:2: ancho = squareSize, alto = 2*squareSize.
      expect(box.size.width, 30.0,
          reason: 'El ancho de la ficha vertical debe ser squareSize=30');
      expect(box.size.height, 60.0,
          reason: 'El alto de la ficha vertical debe ser 2*squareSize=60');
    }
  });
}
