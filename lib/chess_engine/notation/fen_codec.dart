import '../../core/result.dart';
import '../board/position.dart';
import '../errors/chess_engine_error.dart';
import '../model/castling_rights.dart';
import '../model/color.dart';
import '../model/piece.dart';
import '../model/piece_type.dart';
import '../model/square.dart';

class FenCodec {
  const FenCodec();

  static const String startingPositionFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  /// Parses [fen]. Returns [InvalidFenError] for a syntax problem (wrong
  /// field count, malformed piece placement, bad castling/en-passant/
  /// counter fields) and [InvalidChessPositionError] for a FEN that is
  /// syntactically well-formed but describes an impossible chess position
  /// (see [_validateSemantics] for exactly which invariants are checked
  /// and, just as importantly, which are deliberately NOT checked).
  Result<Position, ChessEngineError> parse(String fen) {
    final fields = fen.trim().split(RegExp(r'\s+'));
    if (fields.length != 6) {
      return Result.err(
        InvalidFenError(fen, 'expected 6 space-separated fields, got ${fields.length}'),
      );
    }
    final placementResult = _parsePlacement(fen, fields[0]);
    if (placementResult.isErr) {
      return Result.err(placementResult.errorOrNull!);
    }
    final board = placementResult.valueOrNull!;

    final semanticError = _validateSemantics(fen, board);
    if (semanticError != null) {
      return Result.err(semanticError);
    }

    final Color sideToMove;
    if (fields[1] == 'w') {
      sideToMove = Color.white;
    } else if (fields[1] == 'b') {
      sideToMove = Color.black;
    } else {
      return Result.err(InvalidFenError(fen, 'active color must be "w" or "b"'));
    }

    final castlingResult = _parseCastling(fen, fields[2]);
    if (castlingResult.isErr) return Result.err(castlingResult.errorOrNull!);

    final epResult = _parseEnPassant(fen, fields[3]);
    if (epResult.isErr) return Result.err(epResult.errorOrNull!);

    final halfmove = int.tryParse(fields[4]);
    if (halfmove == null || halfmove < 0) {
      return Result.err(InvalidFenError(fen, 'halfmove clock must be a non-negative integer'));
    }

    final fullmove = int.tryParse(fields[5]);
    if (fullmove == null || fullmove < 1) {
      return Result.err(InvalidFenError(fen, 'fullmove number must be a positive integer'));
    }

    return Result.ok(
      Position(
        board: board,
        sideToMove: sideToMove,
        castlingRights: castlingResult.valueOrNull!,
        enPassantTarget: epResult.valueOrNull,
        halfmoveClock: halfmove,
        fullmoveNumber: fullmove,
      ),
    );
  }

  Result<List<Piece?>, InvalidFenError> _parsePlacement(
    String fen,
    String placement,
  ) {
    final ranks = placement.split('/');
    if (ranks.length != 8) {
      return Result.err(
        InvalidFenError(fen, 'piece placement must have 8 ranks, got ${ranks.length}'),
      );
    }
    final board = List<Piece?>.filled(64, null);
    for (var rankIndex = 0; rankIndex < 8; rankIndex++) {
      final rank = 7 - rankIndex;
      var file = 0;
      for (final char in ranks[rankIndex].split('')) {
        final digit = int.tryParse(char);
        if (digit != null) {
          if (digit < 1 || digit > 8) {
            return Result.err(InvalidFenError(fen, 'invalid empty-square count "$char"'));
          }
          file += digit;
        } else {
          if (!'pnbrqkPNBRQK'.contains(char)) {
            return Result.err(InvalidFenError(fen, 'invalid piece letter "$char"'));
          }
          if (file > 7) {
            return Result.err(InvalidFenError(fen, 'rank ${rank + 1} has more than 8 squares'));
          }
          final color = char == char.toUpperCase() ? Color.white : Color.black;
          board[Square(file, rank).index] = Piece(
            color,
            PieceType.fromFenLetter(char),
          );
          file += 1;
        }
      }
      if (file != 8) {
        return Result.err(
          InvalidFenError(fen, 'rank ${rank + 1} does not sum to 8 squares (got $file)'),
        );
      }
    }
    return Result.ok(board);
  }

  Result<CastlingRights, InvalidFenError> _parseCastling(
    String fen,
    String castling,
  ) {
    if (castling == '-') return const Result.ok(CastlingRights.none);
    if (!RegExp(r'^[KQkq]+$').hasMatch(castling) ||
        castling.split('').toSet().length != castling.length) {
      return Result.err(InvalidFenError(fen, 'invalid castling availability field'));
    }
    return Result.ok(
      CastlingRights(
        whiteKingside: castling.contains('K'),
        whiteQueenside: castling.contains('Q'),
        blackKingside: castling.contains('k'),
        blackQueenside: castling.contains('q'),
      ),
    );
  }

  /// Minimum semantic validation so a syntactically valid FEN cannot
  /// describe an obviously corrupt position. Deliberately narrow:
  ///
  /// Checked (cheap, unambiguous, never rejects a real chess position):
  /// - exactly one white king and exactly one black king
  /// - no pawn on rank 1 or rank 8 (pawns promote before reaching the
  ///   back rank; a pawn there cannot arise from legal play)
  ///
  /// Deliberately NOT checked: castling-rights consistency with actual
  /// king/rook placement (e.g. "K" recorded when no rook sits on h1).
  /// Real FEN sources occasionally carry stale or hand-edited castling
  /// fields for otherwise-valid study/puzzle positions; rejecting those
  /// would make this parser more fragile than useful. If this is ever
  /// tightened, it belongs in its own ADR entry, not folded in silently.
  ChessEngineError? _validateSemantics(String fen, List<Piece?> board) {
    var whiteKings = 0;
    var blackKings = 0;
    for (final piece in board) {
      if (piece?.type == PieceType.king) {
        if (piece!.color == Color.white) {
          whiteKings++;
        } else {
          blackKings++;
        }
      }
    }
    if (whiteKings != 1) {
      return InvalidChessPositionError(
        fen,
        'expected exactly one white king, found $whiteKings',
      );
    }
    if (blackKings != 1) {
      return InvalidChessPositionError(
        fen,
        'expected exactly one black king, found $blackKings',
      );
    }

    for (var file = 0; file < 8; file++) {
      if (board[Square(file, 0).index]?.type == PieceType.pawn) {
        return InvalidChessPositionError(fen, 'a pawn cannot be on rank 1');
      }
      if (board[Square(file, 7).index]?.type == PieceType.pawn) {
        return InvalidChessPositionError(fen, 'a pawn cannot be on rank 8');
      }
    }

    return null;
  }

  Result<Square?, InvalidFenError> _parseEnPassant(String fen, String ep) {
    if (ep == '-') return const Result.ok(null);
    if (!RegExp(r'^[a-h][36]$').hasMatch(ep)) {
      return Result.err(InvalidFenError(fen, 'invalid en passant target square "$ep"'));
    }
    return Result.ok(Square.fromAlgebraic(ep));
  }

  String toFen(Position position) {
    final buffer = StringBuffer();
    for (var rank = 7; rank >= 0; rank--) {
      var emptyCount = 0;
      for (var file = 0; file < 8; file++) {
        final piece = position.pieceAt(Square(file, rank));
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          buffer.write(piece.fenLetter);
        }
      }
      if (emptyCount > 0) buffer.write(emptyCount);
      if (rank > 0) buffer.write('/');
    }
    buffer.write(' ');
    buffer.write(position.sideToMove == Color.white ? 'w' : 'b');
    buffer.write(' ');
    buffer.write(position.castlingRights.fen);
    buffer.write(' ');
    buffer.write(position.enPassantTarget?.algebraic ?? '-');
    buffer.write(' ');
    buffer.write(position.halfmoveClock);
    buffer.write(' ');
    buffer.write(position.fullmoveNumber);
    return buffer.toString();
  }
}
