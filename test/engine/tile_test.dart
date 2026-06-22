import 'package:flutter_test/flutter_test.dart';
import 'package:domino_dominicano/engine/models/tile.dart';

void main() {
  group('DominoTile', () {
    test('crea una ficha con dos valores', () {
      const tile = DominoTile(3, 4);
      expect(tile.left, 3);
      expect(tile.right, 4);
    });

    test('detecta dobles', () {
      expect(const DominoTile(5, 5).isDouble, true);
      expect(const DominoTile(5, 6).isDouble, false);
    });

    test('calcula el valor total', () {
      expect(const DominoTile(2, 4).totalValue, 6);
      expect(const DominoTile(6, 6).totalValue, 12);
    });

    test('swap invierte la ficha', () {
      const tile = DominoTile(2, 5);
      expect(tile.swapped, const DominoTile(5, 2));
    });

    test('matches detecta si contiene un valor', () {
      const tile = DominoTile(3, 4);
      expect(tile.matches(3), true);
      expect(tile.matches(4), true);
      expect(tile.matches(5), false);
    });

    test('getOtherEnd devuelve el extremo opuesto', () {
      const tile = DominoTile(3, 4);
      expect(tile.getOtherEnd(3), 4);
      expect(tile.getOtherEnd(4), 3);
    });

    test('getOtherEnd lanza error si no contiene el valor', () {
      const tile = DominoTile(3, 4);
      expect(() => tile.getOtherEnd(5), throwsArgumentError);
    });

    test('dos fichas con valores invertidos son iguales', () {
      expect(const DominoTile(3, 4), const DominoTile(4, 3));
      expect(const DominoTile(3, 4).hashCode,
          equals(const DominoTile(4, 3).hashCode));
    });

    test('doubleSix es la ficha 6-6', () {
      expect(DominoTile.doubleSix, const DominoTile(6, 6));
    });
  });
}
