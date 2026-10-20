sealed class ChessEngineError {
  final String message;
  const ChessEngineError(this.message);

  @override
  String toString() => message;
}

class InvalidFenError extends ChessEngineError {
  final String fen;
  const InvalidFenError(this.fen, String reason)
    : super('Invalid FEN "$fen": $reason');
}

/// Distinct from [InvalidFenError]: the FEN string is syntactically
/// well-formed (six valid fields, correct piece-placement grammar) but
/// describes a position that cannot be a real chess position — e.g. no
/// king, two kings for one color, or a pawn on the first/last rank.
class InvalidChessPositionError extends ChessEngineError {
  final String fen;
  const InvalidChessPositionError(this.fen, String reason)
    : super('Syntactically valid but invalid chess position "$fen": $reason');
}

class InvalidSquareError extends ChessEngineError {
  final String input;
  const InvalidSquareError(this.input)
    : super('Invalid square: "$input"');
}

class IllegalMoveError extends ChessEngineError {
  const IllegalMoveError(String reason) : super('Illegal move: $reason');
}

class InvalidPromotionError extends ChessEngineError {
  const InvalidPromotionError(String reason)
    : super('Invalid promotion: $reason');
}

class InvalidGameStateError extends ChessEngineError {
  const InvalidGameStateError(String reason)
    : super('Invalid game state: $reason');
}
