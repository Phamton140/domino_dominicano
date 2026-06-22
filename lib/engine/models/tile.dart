/// Representa una ficha de dominó con dos caras.
///
/// En el dominó doble seis, cada cara tiene un valor entre 0 y 6.
/// Dos fichas con los mismos valores en orden inverso se consideran iguales
/// porque la orientación en la mano no importa.
class DominoTile {
  final int left;
  final int right;

  const DominoTile(this.left, this.right)
      : assert(left >= 0 && left <= 6),
        assert(right >= 0 && right <= 6);

  static const DominoTile doubleSix = DominoTile(6, 6);

  bool get isDouble => left == right;

  int get totalValue => left + right;

  /// Devuelve la ficha invertida.
  DominoTile get swapped => DominoTile(right, left);

  /// Indica si la ficha contiene el valor indicado en alguna de sus caras.
  bool matches(int value) => left == value || right == value;

  /// Devuelve el valor opuesto al indicado.
  ///
  /// Lanza un error si la ficha no contiene el valor.
  int getOtherEnd(int value) {
    if (left == value) return right;
    if (right == value) return left;
    throw ArgumentError('La ficha $this no contiene el valor $value');
  }

  @override
  String toString() => '[$left|$right]';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DominoTile) return false;
    return (left == other.left && right == other.right) ||
        (left == other.right && right == other.left);
  }

  @override
  int get hashCode => left.hashCode ^ right.hashCode;
}
