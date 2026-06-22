import 'package:flutter/material.dart';

import '../../engine/board_layout.dart';
import '../../engine/models/move.dart';
import '../../engine/models/player.dart';
import 'domino_tile_widget.dart';
import '../theme.dart';

/// Vista de la mesa de dominó.
///
/// Recibe los [moves] de la ronda actual y el [starterPosition] y dibuja
/// cada ficha en su posición calculada por [BoardLayout]. El widget
/// encuentra automáticamente el [squareSize] que hace que la cadena
/// completa quepa en el área disponible.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return _BoardPainter(
          moves: moves,
          starterPosition: starterPosition,
          availableSize: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _BoardPainter extends StatelessWidget {
  final List<Move> moves;
  final PlayerPosition starterPosition;
  final Size availableSize;

  const _BoardPainter({
    required this.moves,
    required this.starterPosition,
    required this.availableSize,
  });

  @override
  Widget build(BuildContext context) {
    // Búsqueda binaria del mayor squareSize que haga que la cadena quepa.
    double lo = 4;
    double hi = 200;
    double? best;

    for (int i = 0; i < 20; i++) {
      final mid = (lo + hi) / 2;
      if (_fits(mid)) {
        best = mid;
        lo = mid;
      } else {
        hi = mid;
      }
      if (hi - lo < 0.5) break;
    }

    final squareSize = best ?? 20.0;
    return _drawWith(squareSize);
  }

  bool _fits(double squareSize) {
    final layout = BoardLayout(
      moves: moves,
      starterPosition: starterPosition,
      squareSize: squareSize,
      tableBounds: Rect.fromLTWH(0, 0, availableSize.width, availableSize.height),
    );
    try {
      final gs = layout.compute();
      final b = _unionBounds(gs);
      return b.width <= availableSize.width && b.height <= availableSize.height;
    } on StateError {
      return false;
    }
  }

  Widget _drawWith(double squareSize) {
    final layout = BoardLayout(
      moves: moves,
      starterPosition: starterPosition,
      squareSize: squareSize,
      tableBounds: Rect.fromLTWH(0, 0, availableSize.width, availableSize.height),
    );
    final geometries = layout.compute();
    final bounds = _unionBounds(geometries);

    return Center(
      child: SizedBox(
        width: bounds.width,
        height: bounds.height,
        child: Stack(
          children: [
            // El tapete se extiende a la cadena dejando un pequeño margen.
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: DominoTheme.tableGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DominoTheme.tableBorder,
                    width: 2,
                  ),
                ),
              ),
            ),
            for (final g in geometries)
              Positioned(
                left: g.center.dx - g.width / 2 - bounds.left,
                top: g.center.dy - g.height / 2 - bounds.top,
                width: g.width,
                height: g.height,
                child: DominoTileWidget.face(
                  tile: g.move.tile,
                  orientation: g.orientation,
                  squareSize: g.squareSize,
                ),
              ),
          ],
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
