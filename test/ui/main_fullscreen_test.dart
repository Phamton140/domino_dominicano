import 'package:domino_dominicano/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la app arranca con un AnnotatedRegion de fullscreen',
      (tester) async {
    await tester.pumpWidget(const DominoDominicanoApp());
    await tester.pump();

    // La app debe usar AnnotatedRegion<SystemUiOverlayStyle> con
    // colores transparentes para evitar las barras del sistema.
    final annotated = find.byType(AnnotatedRegion<SystemUiOverlayStyle>);
    expect(annotated, findsWidgets,
        reason: 'La app debe envolver MaterialApp con AnnotatedRegion');
  });

  testWidgets('la app envuelve MaterialApp con AnnotatedRegion fullscreen',
      (tester) async {
    await tester.pumpWidget(const DominoDominicanoApp());
    await tester.pump();

    // Verificar que el AnnotatedRegion existe y está en el árbol.
    final regions = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
        .toList();
    expect(regions, isNotEmpty,
        reason: 'La app debe envolver MaterialApp con AnnotatedRegion');
  });
}
