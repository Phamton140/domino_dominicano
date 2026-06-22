import 'package:flutter/material.dart';

import '../../engine/models/tile.dart';
import '../../engine/board_layout.dart';
import '../theme.dart';

/// Dibuja una ficha de dominó en una posición y orientación concretas.
///
/// Si [tile] es null, dibuja el reverso (lomo) de la ficha. Esto se usa
/// para las manos de los oponentes donde no se muestran los valores.
///
/// Si [compact] es true, la ficha se renderiza con forma cuadrada (1:1)
/// con los dos valores apilados verticalmente, independientemente de la
/// orientación. Se usa en la mano local para que las fichas se vean más
/// "rellenas" sin la proporción 1:2 de una ficha real de dominó.
///
/// Si [swapped] es true, la ficha fue invertida por el motor para
/// conectar con el extremo abierto. En ese caso, los pips se dibujan
/// en el orden visual swap (left↔right).
class DominoTileWidget extends StatelessWidget {
  final DominoTile? tile;
  final TileOrientation orientation;
  final double squareSize;
  final bool highlighted;
  final bool dim;
  final bool compact;
  final bool swapped;

  const DominoTileWidget({
    super.key,
    required this.tile,
    required this.orientation,
    required this.squareSize,
    this.highlighted = false,
    this.dim = false,
    this.compact = false,
    this.swapped = false,
  });

  /// Constructor conveniente para dibujar la mano del jugador local
  /// con valores visibles.
  factory DominoTileWidget.face({
    Key? key,
    required DominoTile tile,
    required TileOrientation orientation,
    required double squareSize,
    bool highlighted = false,
    bool compact = false,
    bool swapped = false,
  }) {
    return DominoTileWidget(
      key: key,
      tile: tile,
      orientation: orientation,
      squareSize: squareSize,
      highlighted: highlighted,
      compact: compact,
      swapped: swapped,
    );
  }

  /// Constructor conveniente para dibujar el lomo de una ficha de un
  /// oponente (sin valores visibles).
  factory DominoTileWidget.back({
    Key? key,
    required TileOrientation orientation,
    required double squareSize,
    bool dim = false,
    bool compact = false,
  }) {
    return DominoTileWidget(
      key: key,
      tile: null,
      orientation: orientation,
      squareSize: squareSize,
      dim: dim,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w;
    final double h;
    if (compact) {
      // Modo compacto: ficha cuadrada 1:1 con valores apilados.
      final side = squareSize * 1.5;
      w = side;
      h = side;
    } else if (orientation == TileOrientation.horizontal) {
      w = squareSize * 2;
      h = squareSize;
    } else {
      w = squareSize;
      h = squareSize * 2;
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _faceColor(),
        border: Border.all(
          color: highlighted ? DominoTheme.selectedTile : DominoTheme.tileBorder,
          width: highlighted ? 2 : 0.5,
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
        left: swapped ? tile!.right : tile!.left,
        right: swapped ? tile!.left : tile!.right,
        squareSize: squareSize,
        orientation: orientation,
        compact: compact,
      ),
    );
  }

  Color _faceColor() {
    if (dim) return DominoTheme.opponentTileBack;
    if (tile == null) return DominoTheme.opponentTileBack;
    return DominoTheme.tileFace;
  }
}

/// Disposición de los puntos de un valor (0..6) sobre el espacio disponible.
///
/// En una ficha tradicional (mitad cuadrada) los pips se distribuyen en
/// una rejilla 3x3. En una mitad rectangular de la mano (compact), los
/// pips deben distribuirse en la dimensión **corta** para que la
/// distribución se centre vertical u horizontalmente según el espacio.
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
        // La rejilla 4x4 debe llenar ambas dimensiones. Usamos
        // dimensiones distintas para X e Y para que la rejilla se
        // estire y no queden huecos.
        final unitX = w / 4;
        final unitY = h / 4;
        // El tamaño del pip se basa en la unidad menor para que no se
        // corten, pero los centros se calculan con cada unidad.
        final pipSize = (unitX < unitY ? unitX : unitY) * 0.7;
        return Stack(
          children: pips.map((p) {
            final dx = p.x(unitX);
            final dy = p.y(unitY);
            return Positioned(
              left: dx - pipSize / 2,
              top: dy - pipSize / 2,
              width: pipSize,
              height: pipSize,
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
  final bool compact;

  const _PipsLayout({
    required this.left,
    required this.right,
    required this.squareSize,
    required this.orientation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Modo compacto: siempre columna (cuadrada con valores apilados).
    if (compact) {
      return Column(
        children: [
          Expanded(
            child: _PipLayout(
              value: left,
              size: squareSize,
            ),
          ),
          Container(
            height: 1.5,
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

    // Ficha vertical (1:2): los dos valores se apilan en columna,
    // separados por una línea horizontal.
    if (orientation == TileOrientation.vertical) {
      return Column(
        children: [
          Expanded(
            child: _PipLayout(
              value: left,
              size: squareSize,
            ),
          ),
          Container(
            height: 1.5,
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

    // Ficha horizontal (2:1): los dos valores se ponen en fila,
    // separados por una línea vertical.
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
