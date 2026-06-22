import 'dart:io';
import 'dart:ui' as ui;

import 'package:domino_dominicano/engine/models/player.dart';
import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/theme.dart';
import 'package:domino_dominicano/ui/widgets/domino_tile_widget.dart';
import 'package:domino_dominicano/ui/widgets/hand_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captura mano local', (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      const DominoTile(2, 4),
    ];

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: DominoTheme.build(),
        home: Scaffold(
          backgroundColor: DominoTheme.tableBorder,
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 800,
                height: 120,
                child: HandView(
                  player: player,
                  tiles: tiles,
                  faceUp: true,
                  squareSize: 30,
                  isCurrentPlayer: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Dump de las dimensiones reales de cada ficha.
    final tileWidgets = tester.widgetList<DominoTileWidget>(
      find.byType(DominoTileWidget),
    );
    for (var i = 0; i < tileWidgets.length; i++) {
      final tw = tileWidgets.elementAt(i);
      final size = tester.getSize(find.byWidget(tw));
      // ignore: avoid_print
      print('TILE[$i] orient=${tw.orientation} size=$size');
    }

    // Captura PNG usando WidgetsBinding para evitar el cuelgue de toImage.
    final handle = tester.binding.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      final tmp = File(r'C:\Proyectos\domino_dominicano\build\hand_capture.png');
      await tmp.create(recursive: true);
      await tmp.writeAsBytes(bytes);
      // ignore: avoid_print
      print('PNG: ${tmp.path} (${bytes.length} bytes)');
    });
    await handle;

    expect(tileWidgets, isNotEmpty);
  });
}
