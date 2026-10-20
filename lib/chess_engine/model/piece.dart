import 'color.dart';
import 'piece_type.dart';

class Piece {
  final Color color;
  final PieceType type;

  const Piece(this.color, this.type);

  String get fenLetter =>
      color == Color.white ? type.fenLetter.toUpperCase() : type.fenLetter;

  @override
  bool operator ==(Object other) =>
      other is Piece && other.color == color && other.type == type;

  @override
  int get hashCode => Object.hash(color, type);

  @override
  String toString() => fenLetter;
}
