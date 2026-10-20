import '../board/position.dart';
import '../model/game_status.dart';
import '../model/piece_type.dart';
import '../model/square.dart';
import 'attacks.dart';
import 'move_generator.dart';

/// Determines game-ending conditions from a position and its history.
///
/// Simplifications documented deliberately (see ADR): the fifty-move rule
/// is treated as an automatic draw at halfmove clock 100 rather than a
/// player-claimable one (there is no UI/player-interaction layer yet to
/// model a claim), and "insufficient material" covers only the
/// universally-recognized forced-draw material combinations (K v K, K+B v K,
/// K+N v K, K+B v K+B with same-colored bishops) — not the fully general
/// "dead position" problem, which is a much harder and rarer edge case.
class GameRules {
  const GameRules({this.moveGenerator = const MoveGenerator()});

  final MoveGenerator moveGenerator;

  bool isInCheck(Position position) {
    final kingSquare = position.findKing(position.sideToMove);
    if (kingSquare == null) return false;
    return isSquareAttacked(
      position,
      kingSquare,
      position.sideToMove.opponent,
    );
  }

  /// [history] must include every position reached so far in the game,
  /// in order, ending with [position] itself.
  GameStatus determineStatus(Position position, List<Position> history) {
    final legalMoves = moveGenerator.generateLegalMoves(position);
    if (legalMoves.isEmpty) {
      return isInCheck(position) ? GameStatus.checkmate : GameStatus.stalemate;
    }
    if (position.halfmoveClock >= 100) {
      return GameStatus.drawByFiftyMoveRule;
    }
    if (_repetitionCount(position, history) >= 3) {
      return GameStatus.drawByThreefoldRepetition;
    }
    if (_isInsufficientMaterial(position)) {
      return GameStatus.drawByInsufficientMaterial;
    }
    return GameStatus.ongoing;
  }

  int _repetitionCount(Position position, List<Position> history) {
    final key = position.repetitionKey(_relevantEnPassantTarget(position));
    var count = 0;
    for (final past in history) {
      final pastKey = past.repetitionKey(_relevantEnPassantTarget(past));
      if (pastKey == key) count++;
    }
    return count;
  }

  Square? _relevantEnPassantTarget(Position position) {
    return _hasLegalEnPassantCapture(position) ? position.enPassantTarget : null;
  }

  /// Whether a *legal* en passant capture is currently available — not
  /// merely whether a pawn is geometrically positioned to attempt one.
  /// A pawn can be geometrically positioned for en passant while the
  /// capture itself is illegal (e.g. it would expose the king to a pin
  /// along the rank once both the capturing pawn and the captured pawn
  /// leave it) — see ADR-010. Reuses [MoveGenerator]'s existing,
  /// perft-validated legality filtering rather than re-implementing
  /// king-safety checking here.
  bool _hasLegalEnPassantCapture(Position position) {
    if (position.enPassantTarget == null) return false;
    return moveGenerator
        .generateLegalMoves(position)
        .any((move) => move.isEnPassant);
  }

  bool _isInsufficientMaterial(Position position) {
    final pieces = position.occupiedSquares
        .where((e) => e.value.type != PieceType.king)
        .toList();

    if (pieces.isEmpty) return true; // K vs K

    if (pieces.length == 1) {
      final type = pieces.single.value.type;
      return type == PieceType.bishop || type == PieceType.knight;
    }

    if (pieces.length == 2 &&
        pieces.every((e) => e.value.type == PieceType.bishop) &&
        pieces[0].value.color != pieces[1].value.color) {
      final square0 = pieces[0].key;
      final square1 = pieces[1].key;
      final sameSquareColor =
          (square0.file + square0.rank) % 2 == (square1.file + square1.rank) % 2;
      return sameSquareColor;
    }

    return false;
  }
}
