import 'package:domino_dominicano/engine/models/tile.dart';
import 'package:domino_dominicano/ui/game_controller.dart';
import 'package:domino_dominicano/ui/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

GameController _buildController() {
  final c = GameController(botsEnabled: false);
  final round = c.game.currentRound!;
  // Damos al local 7 fichas: doble seis + 6 más.
  round.players[0].hand = [
    DominoTile.doubleSix,
    const DominoTile(0, 0),
    const DominoTile(0, 1),
    const DominoTile(1, 1),
    const DominoTile(2, 2),
    const DominoTile(3, 3),
    const DominoTile(4, 4),
  ];
  // Limpiamos el resto para que nadie más pueda jugar.
  for (int i = 1; i < 4; i++) {
    round.players[i].hand = List.filled(7, const DominoTile(5, 5));
  }
  // Forzamos al local como starter: el motor permite hacerlo en rondas
  // posteriores. Como la primera ronda exige doble seis, lo tenemos.
  round.start(starterIndex: 0);
  c.notifyListeners();
  return c;
}

void main() {
  testWidgets('GameScreen renderiza marcador y mesa vacía al inicio',
      (tester) async {
    final controller = _buildController();

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Dominó Dominicano'), findsOneWidget);
    expect(find.textContaining('Equipo A: 0'), findsOneWidget);
    expect(find.textContaining('Equipo B: 0'), findsOneWidget);
    expect(find.text('Esperando la primera ficha…'), findsOneWidget);
  });

  testWidgets('botón Jugar se habilita tras seleccionar una ficha jugable',
      (tester) async {
    final controller = _buildController();

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(controller: controller),
      ),
    );
    await tester.pump();

    final tileFinder = find.byWidgetPredicate((w) {
      if (w is! GestureDetector) return false;
      return w.onTap != null;
    });
    expect(tileFinder, findsWidgets);

    var playButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Jugar'),
    );
    expect(playButton.onPressed, isNull);

    await tester.tap(tileFinder.first);
    await tester.pump();

    playButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Jugar'),
    );
    expect(playButton.onPressed, isNotNull);
  });
}
