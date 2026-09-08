import '../board/position.dart';
import '../model/color.dart';
import '../model/piece_type.dart';
import '../model/square.dart';

const List<(int, int)> knightDeltas = [
  (1, 2), (2, 1), (2, -1), (1, -2),
  (-1, -2), (-2, -1), (-2, 1), (-1, 2),
];

const List<(int, int)> kingDeltas = [
  (1, 0), (1, 1), (0, 1), (-1, 1),
  (-1, 0), (-1, -1), (0, -1), (1, -1),
];

const List<(int, int)> bishopDirections = [
  (1, 1), (1, -1), (-1, 1), (-1, -1),
];

const List<(int, int)> rookDirections = [
  (1, 0), (-1, 0), (0, 1), (0, -1),
];

/// Returns true if [target] is attacked by any piece of [byColor] in
/// [position]. Used both for check detection and for validating that a
/// king does not castle through or into check.
bool isSquareAttacked(Position position, Square target, Color byColor) {
  final pawnDirection = byColor == Color.white ? 1 : -1;
  for (final df in [-1, 1]) {
    final candidate = target.offset(df, -pawnDirection);
    if (!candidate.isOnBoard) continue;
    final piece = position.pieceAt(candidate);
    if (piece != null &&
        piece.color == byColor &&
        piece.type == PieceType.pawn) {
      return true;
    }
  }

  for (final (df, dr) in knightDeltas) {
    final candidate = target.offset(df, dr);
    if (!candidate.isOnBoard) continue;
    final piece = position.pieceAt(candidate);
    if (piece != null &&
        piece.color == byColor &&
        piece.type == PieceType.knight) {
      return true;
    }
  }

  for (final (df, dr) in kingDeltas) {
    final candidate = target.offset(df, dr);
    if (!candidate.isOnBoard) continue;
    final piece = position.pieceAt(candidate);
    if (piece != null &&
        piece.color == byColor &&
        piece.type == PieceType.king) {
      return true;
    }
  }

  if (_slidingAttack(position, target, byColor, bishopDirections, const {
    PieceType.bishop,
    PieceType.queen,
  })) {
    return true;
  }
  if (_slidingAttack(position, target, byColor, rookDirections, const {
    PieceType.rook,
    PieceType.queen,
  })) {
    return true;
  }

  return false;
}

bool _slidingAttack(
  Position position,
  Square target,
  Color byColor,
  List<(int, int)> directions,
  Set<PieceType> attackingTypes,
) {
  for (final (df, dr) in directions) {
    var candidate = target.offset(df, dr);
    while (candidate.isOnBoard) {
      final piece = position.pieceAt(candidate);
      if (piece != null) {
        if (piece.color == byColor && attackingTypes.contains(piece.type)) {
          return true;
        }
        break;
      }
      candidate = candidate.offset(df, dr);
    }
  }
  return false;
}
