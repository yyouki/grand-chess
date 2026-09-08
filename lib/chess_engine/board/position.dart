import '../model/castling_rights.dart';
import '../model/color.dart';
import '../model/piece.dart';
import '../model/piece_type.dart';
import '../model/square.dart';
import '../move/move.dart';

class Position {
  final List<Piece?> _board;
  final Color sideToMove;
  final CastlingRights castlingRights;
  final Square? enPassantTarget;
  final int halfmoveClock;
  final int fullmoveNumber;

  Position({
    required List<Piece?> board,
    required this.sideToMove,
    required this.castlingRights,
    required this.enPassantTarget,
    required this.halfmoveClock,
    required this.fullmoveNumber,
  }) : _board = List.unmodifiable(board);

  factory Position.initial() {
    final board = List<Piece?>.filled(64, null);
    const backRank = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];
    for (var file = 0; file < 8; file++) {
      board[Square(file, 0).index] = Piece(Color.white, backRank[file]);
      board[Square(file, 1).index] = const Piece(Color.white, PieceType.pawn);
      board[Square(file, 6).index] = const Piece(Color.black, PieceType.pawn);
      board[Square(file, 7).index] = Piece(Color.black, backRank[file]);
    }
    return Position(
      board: board,
      sideToMove: Color.white,
      castlingRights: CastlingRights.standard,
      enPassantTarget: null,
      halfmoveClock: 0,
      fullmoveNumber: 1,
    );
  }

  Piece? pieceAt(Square square) => _board[square.index];

  Iterable<MapEntry<Square, Piece>> get occupiedSquares sync* {
    for (var i = 0; i < 64; i++) {
      final piece = _board[i];
      if (piece != null) {
        yield MapEntry(Square.fromIndex(i), piece);
      }
    }
  }

  Square? findKing(Color color) {
    for (final entry in occupiedSquares) {
      if (entry.value.color == color && entry.value.type == PieceType.king) {
        return entry.key;
      }
    }
    return null;
  }

  /// Applies [move] and returns a brand-new [Position]. The original
  /// position is never mutated. Assumes [move] is at least pseudo-legal
  /// for the piece on [Move.from] — legality (king safety) is checked by
  /// the move generator before a move is offered to callers.
  ///
  /// For [Move.isEnPassant] specifically: this method trusts that the
  /// square it clears actually holds the opposing pawn being captured. It
  /// does not re-verify that here, deliberately — the move generator is
  /// the single place responsible for only ever producing an en-passant move
  /// when that pawn is genuinely present, and duplicating the check here
  /// would just be re-validating a fact the trusted caller has already
  /// established, in a method whose entire contract is "trusts its
  /// caller". Reviewed and kept unchanged rather than overlooked.
  Position applyMove(Move move) {
    final board = List<Piece?>.of(_board);
    final movingPiece = board[move.from.index]!;

    if (move.isEnPassant) {
      final capturedPawnSquare = Square(move.to.file, move.from.rank);
      board[capturedPawnSquare.index] = null;
    }

    board[move.from.index] = null;
    board[move.to.index] = move.promotion != null
        ? Piece(sideToMove, move.promotion!)
        : movingPiece;

    if (move.isCastleKingside) {
      final rank = move.from.rank;
      board[Square(5, rank).index] = board[Square(7, rank).index];
      board[Square(7, rank).index] = null;
    } else if (move.isCastleQueenside) {
      final rank = move.from.rank;
      board[Square(3, rank).index] = board[Square(0, rank).index];
      board[Square(0, rank).index] = null;
    }

    final newEnPassantTarget = move.isDoublePawnPush
        ? Square(move.from.file, (move.from.rank + move.to.rank) ~/ 2)
        : null;

    var newCastling = castlingRights;
    if (movingPiece.type == PieceType.king) {
      newCastling = sideToMove == Color.white
          ? newCastling.copyWith(whiteKingside: false, whiteQueenside: false)
          : newCastling.copyWith(blackKingside: false, blackQueenside: false);
    }
    newCastling = _clearCastlingRightsForSquare(newCastling, move.from);
    newCastling = _clearCastlingRightsForSquare(newCastling, move.to);

    final isPawnMove = movingPiece.type == PieceType.pawn;
    final newHalfmove = (isPawnMove || move.isCapture || move.isEnPassant)
        ? 0
        : halfmoveClock + 1;

    final newFullmove = sideToMove == Color.black
        ? fullmoveNumber + 1
        : fullmoveNumber;

    return Position(
      board: board,
      sideToMove: sideToMove.opponent,
      castlingRights: newCastling,
      enPassantTarget: newEnPassantTarget,
      halfmoveClock: newHalfmove,
      fullmoveNumber: newFullmove,
    );
  }

  CastlingRights _clearCastlingRightsForSquare(
    CastlingRights rights,
    Square square,
  ) {
    if (square == const Square(0, 0)) return rights.copyWith(whiteQueenside: false);
    if (square == const Square(7, 0)) return rights.copyWith(whiteKingside: false);
    if (square == const Square(0, 7)) return rights.copyWith(blackQueenside: false);
    if (square == const Square(7, 7)) return rights.copyWith(blackKingside: false);
    return rights;
  }

  /// A canonical string key capturing exactly the state that defines
  /// whether two positions are "the same" for threefold-repetition
  /// purposes: piece placement, side to move, castling rights, and en
  /// passant target — but NOT the halfmove/fullmove counters, which
  /// always differ between otherwise-identical positions.
  ///
  /// The en passant target should only be passed when it currently
  /// represents a genuinely available capture (a pawn of the side to move
  /// actually attacks it) — callers determine that and pass `null`
  /// otherwise, since an en passant target square that no pawn can
  /// currently use does not make the position distinguishable under FIDE
  /// rules.
  String repetitionKey(Square? relevantEnPassantTarget) {
    final buffer = StringBuffer();
    for (var i = 0; i < 64; i++) {
      buffer.write(_board[i]?.fenLetter ?? '.');
    }
    buffer.write(' ');
    buffer.write(sideToMove == Color.white ? 'w' : 'b');
    buffer.write(' ');
    buffer.write(castlingRights.fen);
    buffer.write(' ');
    buffer.write(relevantEnPassantTarget?.algebraic ?? '-');
    return buffer.toString();
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var rank = 7; rank >= 0; rank--) {
      for (var file = 0; file < 8; file++) {
        final piece = _board[Square(file, rank).index];
        buffer.write(piece?.fenLetter ?? '.');
        buffer.write(' ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
