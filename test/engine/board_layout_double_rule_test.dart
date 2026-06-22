import 'dart:ui';

import 'package:domino_dominicano/engine/board_layout.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Move mk(DominoTile t, BoardSide side, {bool swapped = false}) => Move(
        player: Player(
          id: 'p0',
          name: 'p0',
          position: PlayerPosition.bottom,
          teamId: 'A',
        ),
        tile: t,
        side: side,
        tileWasSwapped: swapped,
      );

  group('regla perpendicular a dobles', () {
    test('local+doble sale horizontal; doble siguiente va vertical', () {
      final layout = BoardLayout(
        moves: [
          mk(const DominoTile(6, 6), BoardSide.right), // doble, local → horizontal
          mk(const DominoTile(6, 3), BoardSide.right), // normal, sigue dirección right → horizontal
          mk(const DominoTile(3, 3), BoardSide.right), // doble, perpendicular al anterior → vertical
        ],
        starterPosition: PlayerPosition.bottom,
        squareSize: 30,
        tableBounds: const Rect.fromLTWH(0, 0, 1000, 1000),
      );
      final gs = layout.compute();
      expect(gs[0].orientation, TileOrientation.horizontal);
      expect(gs[1].orientation, TileOrientation.horizontal);
      expect(gs[2].orientation, TileOrientation.vertical);
    });

    test('adversario+doble sale vertical; doble siguiente va horizontal', () {
      final layout = BoardLayout(
        moves: [
          mk(const DominoTile(6, 6), BoardSide.right), // doble, adversario → vertical
          mk(const DominoTile(6, 3), BoardSide.right), // normal, sigue dirección right → horizontal
          mk(const DominoTile(3, 3), BoardSide.right), // doble, perpendicular al anterior → vertical
        ],
        starterPosition: PlayerPosition.right,
        squareSize: 30,
        tableBounds: const Rect.fromLTWH(0, 0, 1000, 1000),
      );
      final gs = layout.compute();
      expect(gs[0].orientation, TileOrientation.vertical);
      expect(gs[1].orientation, TileOrientation.horizontal);
      expect(gs[2].orientation, TileOrientation.vertical);
    });
  });
}
