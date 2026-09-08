import '../board/position.dart';
import '../model/color.dart';
import '../model/piece_type.dart';
import '../model/square.dart';
import '../move/move.dart';
import 'attacks.dart';

class MoveGenerator {
  const MoveGenerator();

  /// All legal moves for the side to move in [position]: pseudo-legal
  /// moves filtered down to those that do not leave the moving side's own
  /// king in check.
  ///
  /// Capturing the opposing king is explicitly excluded rather than
  /// assumed impossible. In a position reached only through this engine's
  /// own move application, it never arises — the move that would have
  /// exposed the king was already filtered out one ply earlier. But
  /// [Position] can also be constructed directly from an imported FEN
  /// (see the FEN codec's docs), whose semantic validation deliberately stops short
  /// of checking "is the side not to move currently in check" — a
  /// genuinely invalid position where the opponent's king looks
  /// capturable is reachable that way, and the explicit guard below is
  /// what stops it from ever surfacing as a legal move.
  List<Move> generateLegalMoves(Position position) {
    final legal = <Move>[];
    for (final move in generatePseudoLegalMoves(position)) {
      if (position.pieceAt(move.to)?.type == PieceType.king) continue;
      final resulting = position.applyMove(move);
      final kingSquare = resulting.findKing(position.sideToMove);
      if (kingSquare == null) continue;
      if (!isSquareAttacked(resulting, kingSquare, resulting.sideToMove)) {
        legal.add(move);
      }
    }
    return legal;
  }

  List<Move> generatePseudoLegalMoves(Position position) {
    final moves = <Move>[];
    final color = position.sideToMove;
    for (final entry in position.occupiedSquares) {
      if (entry.value.color != color) continue;
      switch (entry.value.type) {
        case PieceType.pawn:
          _generatePawnMoves(position, entry.key, color, moves);
        case PieceType.knight:
          _generateStepMoves(position, entry.key, color, knightDeltas, moves);
        case PieceType.bishop:
          _generateSlidingMoves(
            position,
            entry.key,
            color,
            bishopDirections,
            moves,
          );
        case PieceType.rook:
          _generateSlidingMoves(
            position,
            entry.key,
            color,
            rookDirections,
            moves,
          );
        case PieceType.queen:
          _generateSlidingMoves(
            position,
            entry.key,
            color,
            [...bishopDirections, ...rookDirections],
            moves,
          );
        case PieceType.king:
          _generateStepMoves(position, entry.key, color, kingDeltas, moves);
          _generateCastlingMoves(position, entry.key, color, moves);
      }
    }
    return moves;
  }

  void _generatePawnMoves(
    Position position,
    Square from,
    Color color,
    List<Move> moves,
  ) {
    final direction = color == Color.white ? 1 : -1;
    final startRank = color == Color.white ? 1 : 6;
    final promotionRank = color == Color.white ? 7 : 0;

    final oneForward = from.offset(0, direction);
    if (oneForward.isOnBoard && position.pieceAt(oneForward) == null) {
      _addPawnMove(from, oneForward, promotionRank, moves);
      if (from.rank == startRank) {
        final twoForward = from.offset(0, 2 * direction);
        if (position.pieceAt(twoForward) == null) {
          moves.add(Move(from: from, to: twoForward, isDoublePawnPush: true));
        }
      }
    }

    for (final df in [-1, 1]) {
      final target = from.offset(df, direction);
      if (!target.isOnBoard) continue;
      final occupant = position.pieceAt(target);
      if (occupant != null && occupant.color != color) {
        _addPawnMove(from, target, promotionRank, moves, isCapture: true);
      } else if (position.enPassantTarget == target &&
          _hasCapturablePawnFor(position, target, from.rank, color)) {
        moves.add(Move(from: from, to: target, isCapture: true, isEnPassant: true));
      }
    }
  }

  /// The en passant target square recorded in a [Position] (from FEN) may
  /// be stale — the parser deliberately does not cross-check it against
  /// actual piece placement (see FenCodec docs). Before offering an en
  /// passant capture, confirm the pawn it would actually remove is really
  /// there: same file as the target, same rank as the capturing pawn's
  /// origin, an opposing pawn — matching exactly what
  /// [Position.applyMove] removes for this move type.
  bool _hasCapturablePawnFor(
    Position position,
    Square target,
    int capturerRank,
    Color capturerColor,
  ) {
    final piece = position.pieceAt(Square(target.file, capturerRank));
    return piece != null &&
        piece.color != capturerColor &&
        piece.type == PieceType.pawn;
  }

  void _addPawnMove(
    Square from,
    Square to,
    int promotionRank,
    List<Move> moves, {
    bool isCapture = false,
  }) {
    if (to.rank == promotionRank) {
      for (final promo in const [
        PieceType.queen,
        PieceType.rook,
        PieceType.bishop,
        PieceType.knight,
      ]) {
        moves.add(
          Move(from: from, to: to, promotion: promo, isCapture: isCapture),
        );
      }
    } else {
      moves.add(Move(from: from, to: to, isCapture: isCapture));
    }
  }

  void _generateStepMoves(
    Position position,
    Square from,
    Color color,
    List<(int, int)> deltas,
    List<Move> moves,
  ) {
    for (final (df, dr) in deltas) {
      final target = from.offset(df, dr);
      if (!target.isOnBoard) continue;
      final occupant = position.pieceAt(target);
      if (occupant == null) {
        moves.add(Move(from: from, to: target));
      } else if (occupant.color != color) {
        moves.add(Move(from: from, to: target, isCapture: true));
      }
    }
  }

  void _generateSlidingMoves(
    Position position,
    Square from,
    Color color,
    List<(int, int)> directions,
    List<Move> moves,
  ) {
    for (final (df, dr) in directions) {
      var target = from.offset(df, dr);
      while (target.isOnBoard) {
        final occupant = position.pieceAt(target);
        if (occupant == null) {
          moves.add(Move(from: from, to: target));
        } else {
          if (occupant.color != color) {
            moves.add(Move(from: from, to: target, isCapture: true));
          }
          break;
        }
        target = target.offset(df, dr);
      }
    }
  }

  void _generateCastlingMoves(
    Position position,
    Square kingSquare,
    Color color,
    List<Move> moves,
  ) {
    final rank = color == Color.white ? 0 : 7;
    if (kingSquare != Square(4, rank)) return;
    final opponent = color.opponent;
    final rights = position.castlingRights;

    final canKingside = color == Color.white
        ? rights.whiteKingside
        : rights.blackKingside;
    if (canKingside && _hasRookAt(position, Square(7, rank), color)) {
      final f1 = Square(5, rank);
      final f2 = Square(6, rank);
      if (position.pieceAt(f1) == null &&
          position.pieceAt(f2) == null &&
          !isSquareAttacked(position, kingSquare, opponent) &&
          !isSquareAttacked(position, f1, opponent) &&
          !isSquareAttacked(position, f2, opponent)) {
        moves.add(
          Move(from: kingSquare, to: f2, isCastleKingside: true),
        );
      }
    }

    final canQueenside = color == Color.white
        ? rights.whiteQueenside
        : rights.blackQueenside;
    if (canQueenside && _hasRookAt(position, Square(0, rank), color)) {
      final d1 = Square(3, rank);
      final d2 = Square(2, rank);
      final d3 = Square(1, rank);
      if (position.pieceAt(d1) == null &&
          position.pieceAt(d2) == null &&
          position.pieceAt(d3) == null &&
          !isSquareAttacked(position, kingSquare, opponent) &&
          !isSquareAttacked(position, d1, opponent) &&
          !isSquareAttacked(position, d2, opponent)) {
        moves.add(
          Move(from: kingSquare, to: d2, isCastleQueenside: true),
        );
      }
    }
  }

  /// Castling rights recorded in a [Position] (from FEN) may be stale —
  /// the parser deliberately does not cross-check them against actual
  /// piece placement (see FenCodec docs). Move generation must not offer
  /// castling unless the rook it depends on is actually present and the
  /// right color, regardless of what the rights field claims.
  bool _hasRookAt(Position position, Square square, Color color) {
    final piece = position.pieceAt(square);
    return piece != null && piece.color == color && piece.type == PieceType.rook;
  }
}
