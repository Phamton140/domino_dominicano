import 'package:flutter_test/flutter_test.dart';
import 'package:domino_dominicano/engine/board.dart';
import 'package:domino_dominicano/engine/models/move.dart';
import 'package:domino_dominicano/engine/models/tile.dart';

void main() {
  group('Board', () {
    late Board board;

    setUp(() {
      board = Board();
    });

    test('inicia vacío con extremos en -1', () {
      expect(board.isEmpty, true);
      expect(board.leftEnd, -1);
      expect(board.rightEnd, -1);
      expect(board.endsAreEqual, false);
    });

    test('coloca la primera ficha', () {
      board.placeFirst(const DominoTile(6, 6));
      expect(board.isEmpty, false);
      expect(board.leftEnd, 6);
      expect(board.rightEnd, 6);
      expect(board.endsAreEqual, true);
    });

    test('coloca fichas por la derecha', () {
      board.placeFirst(const DominoTile(6, 6));
      board.placeOnRight(const DominoTile(6, 5));
      expect(board.rightEnd, 5);
      expect(board.leftEnd, 6);
    });

    test('coloca fichas por la izquierda', () {
      board.placeFirst(const DominoTile(6, 6));
      board.placeOnLeft(const DominoTile(6, 4));
      expect(board.leftEnd, 4);
      expect(board.rightEnd, 6);
    });

    test('la ficha se invierte automáticamente para coincidir', () {
      board.placeFirst(const DominoTile(6, 6));
      board.placeOnRight(const DominoTile(5, 6));
      // La ficha 5-6 debe quedar como 6-5 para coincidir, exponiendo 5 a la derecha.
      expect(board.rightEnd, 5);
    });

    test('doble punta fuerza jugada por la derecha', () {
      board.placeFirst(const DominoTile(6, 6));
      board.placeOnRight(const DominoTile(6, 4));
      // Extremos: izquierda 6, derecha 4. No son iguales.
      expect(board.endsAreEqual, false);
    });

    test('placeTile fuerza derecha en doble punta', () {
      board.placeFirst(const DominoTile(6, 6));
      final side = board.placeTile(const DominoTile(6, 3));
      expect(side, BoardSide.right);
      expect(board.rightEnd, 3);
    });

    test('placeTile elige el único lado válido', () {
      board.placeFirst(const DominoTile(6, 3));
      final side = board.placeTile(const DominoTile(3, 1));
      expect(side, BoardSide.right);
      expect(board.rightEnd, 1);
    });

    test('validSidesFor devuelve lista vacía si no encaja', () {
      board.placeFirst(const DominoTile(6, 6));
      expect(board.validSidesFor(const DominoTile(5, 4)), isEmpty);
    });

    test('validSidesFor devuelve solo derecha en doble punta', () {
      board.placeFirst(const DominoTile(6, 6));
      expect(board.validSidesFor(const DominoTile(6, 4)), [BoardSide.right]);
    });

    test('validSidesFor devuelve ambos lados cuando encaja en ambos extremos',
        () {
      board.placeFirst(const DominoTile(4, 3));
      board.placeOnRight(const DominoTile(3, 5));
      // Extremos: 4 y 5.
      expect(
        board.validSidesFor(const DominoTile(4, 5)),
        containsAll([BoardSide.left, BoardSide.right]),
      );
    });

    test('lanza error si se intenta colocar ficha inválida', () {
      board.placeFirst(const DominoTile(6, 6));
      expect(
        () => board.placeOnRight(const DominoTile(5, 4)),
        throwsStateError,
      );
    });

    test('lanza error si se intenta colocar primera ficha dos veces', () {
      board.placeFirst(const DominoTile(6, 6));
      expect(
        () => board.placeFirst(const DominoTile(5, 5)),
        throwsStateError,
      );
    });

    test('clear reinicia la mesa', () {
      board.placeFirst(const DominoTile(6, 6));
      board.clear();
      expect(board.isEmpty, true);
      expect(board.leftEnd, -1);
    });
  });
}
