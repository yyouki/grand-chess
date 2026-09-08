import '../model/color.dart';
import '../model/piece.dart';
import '../move/move.dart';

/// One played move plus everything a future PGN writer will need, so PGN
/// support can be added in Version 1.0 without re-deriving this
/// information from scratch or changing GameState's shape.
class MoveRecord {
  final Move move;
  final String san;
  final Color sideThatMoved;
  final Piece? capturedPiece;
  final int fullmoveNumberBeforeMove;
  final bool givesCheck;
  final bool givesCheckmate;

  const MoveRecord({
    required this.move,
    required this.san,
    required this.sideThatMoved,
    required this.capturedPiece,
    required this.fullmoveNumberBeforeMove,
    required this.givesCheck,
    required this.givesCheckmate,
  });

  @override
  String toString() => san;
}
