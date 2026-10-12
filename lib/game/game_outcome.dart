import '../chess_engine/chess_engine.dart' hide Color;
import '../chess_engine/chess_engine.dart' as engine;

/// Why a game session ended. The first five mirror [GameStatus]; resignation
/// is an application-level reason the chess engine deliberately has no
/// concept of — resigning is a player's choice about the session, not a rule
/// of chess, so it does not belong in chess_engine.
enum GameEndReason {
  checkmate,
  stalemate,
  fiftyMoveRule,
  threefoldRepetition,
  insufficientMaterial,
  resignation,
}

/// How a game session ended: the result and why. Built either from the
/// engine's own status/result, or for a resignation, which only this
/// application layer knows about.
class GameOutcome {
  const GameOutcome(this.result, this.reason);

  /// Builds the outcome for a game the engine reports as finished. Throws
  /// [StateError] for [GameStatus.ongoing] — callers must only ask once the
  /// game is actually over.
  factory GameOutcome.fromStatus(GameStatus status, GameResult result) {
    final reason = switch (status) {
      GameStatus.checkmate => GameEndReason.checkmate,
      GameStatus.stalemate => GameEndReason.stalemate,
      GameStatus.drawByFiftyMoveRule => GameEndReason.fiftyMoveRule,
      GameStatus.drawByThreefoldRepetition => GameEndReason.threefoldRepetition,
      GameStatus.drawByInsufficientMaterial =>
        GameEndReason.insufficientMaterial,
      GameStatus.ongoing => throw StateError(
        'A game that is still ongoing has no outcome yet.',
      ),
    };
    return GameOutcome(result, reason);
  }

  /// [resigningSide] gives up, so the opponent wins.
  factory GameOutcome.resignation(engine.Color resigningSide) {
    return GameOutcome(
      resigningSide == engine.Color.white
          ? GameResult.blackWins
          : GameResult.whiteWins,
      GameEndReason.resignation,
    );
  }

  final GameResult result;
  final GameEndReason reason;

  String get headline => switch (result) {
    GameResult.whiteWins => 'White wins',
    GameResult.blackWins => 'Black wins',
    GameResult.draw => 'Draw',
    GameResult.ongoing => 'Game in progress',
  };

  String get subtitle => switch (reason) {
    GameEndReason.checkmate => 'Checkmate',
    GameEndReason.stalemate => 'Stalemate',
    GameEndReason.fiftyMoveRule => 'Fifty-move rule',
    GameEndReason.threefoldRepetition => 'Threefold repetition',
    GameEndReason.insufficientMaterial => 'Insufficient material',
    GameEndReason.resignation =>
      result == GameResult.whiteWins ? 'Black resigned' : 'White resigned',
  };
}
