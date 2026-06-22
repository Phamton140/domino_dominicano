import 'package:flutter/material.dart';

import '../../engine/models/tile.dart';
import '../../engine/board_layout.dart';
import '../theme.dart';

/// Dibuja una ficha de dominó en una posición y orientación concretas.
///
/// Si [tile] es null, dibuja el reverso (lomo) de la ficha. Esto se usa
/// para las manos de los oponentes donde no se muestran los valores.
class DominoTileWidget extends StatelessWidget {
  final DominoTile? tile;
  final TileOrientation orientation;
  final double squareSize;
  final bool highlighted;
  final bool dim;

  const DominoTileWidget({
    super.key,
    required this.tile,
    required this.orientation,
    required this.squareSize,
    this.highlighted = false,
    this.dim = false,
  });

  /// Constructor conveniente para dibujar la mano del jugador local
  /// con valores visibles.
  factory DominoTileWidget.face({
    Key? key,
    required DominoTile tile,
    required TileOrientation orientation,
    required double squareSize,
    bool highlighted = false,
  }) {
    return DominoTileWidget(
      key: key,
      tile: tile,
      orientation: orientation,
      squareSize: squareSize,
      highlighted: highlighted,
    );
  }

  /// Constructor conveniente para dibujar el lomo de una ficha de un
  /// oponente (sin valores visibles).
  factory DominoTileWidget.back({
    Key? key,
    required TileOrientation orientation,
    required double squareSize,
    bool dim = false,
  }) {
    return DominoTileWidget(
      key: key,
      tile: null,
      orientation: orientation,
      squareSize: squareSize,
      dim: dim,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = orientation == TileOrientation.horizontal
        ? squareSize * 2
        : squareSize;
    final h = orientation == TileOrientation.horizontal
        ? squareSize
        : squareSize * 2;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _faceColor(),
        border: Border.all(
          color: highlighted ? DominoTheme.selectedTile : DominoTheme.tileBorder,
          width: highlighted ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(squareSize * 0.12),
        boxShadow: [
          if (!dim)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: tile == null ? const SizedBox.shrink() : _PipsLayout(
        left: tile!.left,
        right: tile!.right,
        squareSize: squareSize,
        orientation: orientation,
      ),
    );
  }

  Color _faceColor() {
    if (dim) return DominoTheme.opponentTileBack;
    if (tile == null) return DominoTheme.opponentTileBack;
    return DominoTheme.tileFace;
  }
}

/// Disposición de los puntos de un valor (0..6) sobre un cuadrado.
class _PipLayout extends StatelessWidget {
  final int value;
  final double size;

  const _PipLayout({required this.value, required this.size});

  static const _positions = <int, List<_PipPos>>{
    0: [],
    1: [_PipPos.center],
    2: [_PipPos.tl, _PipPos.br],
    3: [_PipPos.tl, _PipPos.center, _PipPos.br],
    4: [_PipPos.tl, _PipPos.tr, _PipPos.bl, _PipPos.br],
    5: [_PipPos.tl, _PipPos.tr, _PipPos.center, _PipPos.bl, _PipPos.br],
    6: [_PipPos.tl, _PipPos.tr, _PipPos.ml, _PipPos.bl, _PipPos.br, _PipPos.mr],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _positions[value] ?? const [];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final unit = (w < h ? w : h) / 4;
        return Stack(
          children: pips.map((p) {
            final dx = p.x(unit);
            final dy = p.y(unit);
            return Positioned(
              left: dx - unit * 0.4,
              top: dy - unit * 0.4,
              width: unit * 0.8,
              height: unit * 0.8,
              child: Container(
                decoration: const BoxDecoration(
                  color: DominoTheme.pipColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

enum _PipPos { tl, tr, ml, mr, bl, br, center }

extension on _PipPos {
  double x(double unit) {
    return switch (this) {
      _PipPos.tl || _PipPos.bl || _PipPos.ml => unit,
      _PipPos.center => unit * 2,
      _PipPos.tr || _PipPos.br || _PipPos.mr => unit * 3,
    };
  }

  double y(double unit) {
    return switch (this) {
      _PipPos.tl || _PipPos.tr => unit,
      _PipPos.ml || _PipPos.mr || _PipPos.center => unit * 2,
      _PipPos.bl || _PipPos.br => unit * 3,
    };
  }
}

/// Componente que dibuja las dos mitades de una ficha con su línea
/// divisoria central.
class _PipsLayout extends StatelessWidget {
  final int left;
  final int right;
  final double squareSize;
  final TileOrientation orientation;

  const _PipsLayout({
    required this.left,
    required this.right,
    required this.squareSize,
    required this.orientation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PipLayout(
            value: left,
            size: squareSize,
          ),
        ),
        Container(
          width: 1.5,
          color: DominoTheme.tileBorder,
        ),
        Expanded(
          child: _PipLayout(
            value: right,
            size: squareSize,
          ),
        ),
      ],
    );
  }
}
