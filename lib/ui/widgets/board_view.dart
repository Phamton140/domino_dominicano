import 'package:flutter/material.dart';

import '../../engine/board_layout.dart';
import '../../engine/models/move.dart';
import '../../engine/models/player.dart';
import 'domino_tile_widget.dart';
import '../theme.dart';

/// Tamaño lógico de una ficha en la mesa, en píxeles lógicos.
///
/// Es un valor FIJO: las fichas no cambian de tamaño ni al añadirse
/// nuevas fichas a la cadena ni al redimensionarse el área disponible.
/// La cámara virtual se desplaza sobre la cadena para que entre toda
/// en pantalla, pero las fichas conservan siempre sus dimensiones.
const double kBoardTileSquareSize = 26.0;

/// Vista de la mesa de dominó.
///
/// Recibe los [moves] de la ronda actual y el [starterPosition] y dibuja
/// cada ficha en su posición calculada por [BoardLayout] usando un
/// [kBoardTileSquareSize] constante. La cadena puede exceder el área
/// visible: en ese caso se centra dentro de un `SingleChildScrollView`
/// y el usuario puede hacer scroll/pinch para verla.
class BoardView extends StatelessWidget {
  final List<Move> moves;
  final PlayerPosition starterPosition;

  const BoardView({
    super.key,
    required this.moves,
    required this.starterPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const _EmptyBoard();
    }

    final layout = BoardLayout(
      moves: moves,
      starterPosition: starterPosition,
      squareSize: kBoardTileSquareSize,
      tableBounds: const Rect.fromLTWH(0, 0, 2000, 2000),
    );
    final geometries = layout.compute();

    final bounds = _unionBounds(geometries);
    const margin = 6.0;

    return Container(
      decoration: BoxDecoration(
        color: DominoTheme.tableGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DominoTheme.tableBorder, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InteractiveViewer(
          minScale: 0.4,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(200),
          child: SizedBox(
            width: bounds.width + margin * 2,
            height: bounds.height + margin * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final g in geometries)
                  Positioned(
                    left: g.center.dx - g.width / 2 - bounds.left + margin,
                    top: g.center.dy - g.height / 2 - bounds.top + margin,
                    width: g.width,
                    height: g.height,
                    child: DominoTileWidget.face(
                      tile: g.move.tile,
                      orientation: g.orientation,
                      squareSize: g.squareSize,
                      swapped: g.move.tileWasSwapped,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Rect _unionBounds(List<TileGeometry> geometries) {
    double left = double.infinity;
    double top = double.infinity;
    double right = -double.infinity;
    double bottom = -double.infinity;
    for (final g in geometries) {
      final b = g.bounds;
      if (b.left < left) left = b.left;
      if (b.top < top) top = b.top;
      if (b.right > right) right = b.right;
      if (b.bottom > bottom) bottom = b.bottom;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DominoTheme.tableGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DominoTheme.tableBorder, width: 2),
      ),
      child: const Center(
        child: Text(
          'Esperando la primera ficha…',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
    );
  }
}
