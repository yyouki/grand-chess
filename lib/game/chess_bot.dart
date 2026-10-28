import 'dart:math';

import '../chess_engine/chess_engine.dart';

/// Difficulty options for the built-in, offline bot.
///
/// This lightweight bot always uses the chess engine's legal-move list. It is
/// intentionally not described as Stockfish-strength; deeper search can be
/// added later without coupling the UI to the rules engine.
enum BotLevel { easy, tactical }

extension BotLevelLabel on BotLevel {
  String get label => switch (this) {
    BotLevel.easy => 'Easy',
    BotLevel.tactical => 'Tactical',
  };
}

class ChessBot {
  const ChessBot();

  Move? chooseMove(
    GameState state, {
    BotLevel level = BotLevel.easy,
    Random? random,
  }) {
    final moves = state.legalMoves;
    if (moves.isEmpty) return null;

    final rng = random ?? Random();
    if (level == BotLevel.easy) {
      return moves[rng.nextInt(moves.length)];
    }

    var bestScore = -double.infinity;
    final bestMoves = <Move>[];
    for (final move in moves) {
      final score = _scoreMove(state, move);
      if (score > bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(move);
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
    }
    return bestMoves[rng.nextInt(bestMoves.length)];
  }

  double _scoreMove(GameState state, Move move) {
    final position = state.position;
    final targetPiece = move.isEnPassant
        ? position.pieceAt(Square(move.to.file, move.from.rank))
        : position.pieceAt(move.to);
    var score = 0.0;

    if (targetPiece != null) {
      score += _pieceValue(targetPiece.type) * 10;
    }
    if (move.promotion != null) {
      score += _pieceValue(move.promotion!) * 8;
    }

    // Reward developing minor pieces and controlling the center. This is a
    // small heuristic, not a substitute for a deep search engine.
    final movingPiece = position.pieceAt(move.from);
    if (movingPiece != null) {
      final fromBackRank = move.from.rank == 0 || move.from.rank == 7;
      if (fromBackRank &&
          (movingPiece.type == PieceType.knight ||
              movingPiece.type == PieceType.bishop)) {
        score += 2.0;
      }
    }
    score += (3.5 - (move.to.file - 3.5).abs()) * 0.35;
    score += (3.5 - (move.to.rank - 3.5).abs()) * 0.35;

    final result = state.applyMove(move);
    final nextState = result.valueOrNull;
    if (nextState != null && nextState.moveHistory.isNotEmpty) {
      final record = nextState.moveHistory.last;
      if (record.givesCheck) score += 2.5;
      if (record.givesCheckmate) score += 100000;
    }
    // A tiny stable preference avoids a static bot repeatedly preferring the
    // same low-value move when the move scores are close.
    score += (move.from.file + move.to.file + move.to.rank) * 0.001;
    return score;
  }

  double _pieceValue(PieceType type) => switch (type) {
    PieceType.pawn => 1,
    PieceType.knight => 3,
    PieceType.bishop => 3.2,
    PieceType.rook => 5,
    PieceType.queen => 9,
    PieceType.king => 100,
  };
}
