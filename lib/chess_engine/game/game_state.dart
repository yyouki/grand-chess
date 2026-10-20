import '../../core/result.dart';
import '../board/position.dart';
import '../errors/chess_engine_error.dart';
import '../model/color.dart';
import '../model/game_result.dart';
import '../model/game_status.dart';
import '../model/square.dart';
import '../move/move.dart';
import '../notation/fen_codec.dart';
import '../notation/san_generator.dart';
import '../rules/game_rules.dart';
import '../rules/move_generator.dart';
import 'move_record.dart';

/// Pure Dart domain model for an in-progress (or finished) chess game.
///
/// Immutable by design (see ADR-008): [applyMove] never mutates `this`,
/// it returns a new [GameState]. This makes "undo" free (just keep the
/// previous reference), makes repetition detection safe (past [Position]s
/// can never be accidentally changed), and matches the determinism
/// requirement — the same [GameState] plus the same [Move] always
/// produces the same resulting [GameState].
///
/// For MVP Alpha this lives entirely in memory. Nothing here depends on
/// Flutter, a database, or any persistence mechanism — Version 1.0 wraps
/// this with Drift without needing to change anything in this file
/// (ADR-005, ADR-008).
class GameState {
  final Position position;
  final List<Position> positionHistory;
  final List<MoveRecord> moveHistory;
  final GameStatus status;
  final GameResult result;

  /// Wraps [positionHistory] and [moveHistory] with `List.unmodifiable`,
  /// which copies the elements into a fresh, read-only list rather than
  /// aliasing the caller's list — so neither a caller's later mutation of
  /// the list they passed in, nor an attempt to mutate the exposed field
  /// directly, can ever change this instance after construction. `final`
  /// alone does not provide this: it only stops the field from being
  /// *reassigned*, not the underlying list from being mutated in place.
  GameState._({
    required this.position,
    required List<Position> positionHistory,
    required List<MoveRecord> moveHistory,
    required this.status,
    required this.result,
  }) : positionHistory = List.unmodifiable(positionHistory),
       moveHistory = List.unmodifiable(moveHistory);

  factory GameState.initial({
    GameRules gameRules = const GameRules(),
  }) {
    final position = Position.initial();
    final status = gameRules.determineStatus(position, [position]);
    return GameState._(
      position: position,
      positionHistory: [position],
      moveHistory: const [],
      status: status,
      result: _resultFor(status, position.sideToMove),
    );
  }

  static Result<GameState, ChessEngineError> fromFen(
    String fen, {
    FenCodec fenCodec = const FenCodec(),
    GameRules gameRules = const GameRules(),
  }) {
    final parsed = fenCodec.parse(fen);
    if (parsed.isErr) return Result.err(parsed.errorOrNull!);
    final position = parsed.valueOrNull!;
    final status = gameRules.determineStatus(position, [position]);
    return Result.ok(
      GameState._(
        position: position,
        positionHistory: [position],
        moveHistory: const [],
        status: status,
        result: _resultFor(status, position.sideToMove),
      ),
    );
  }

  /// Derives the game result from a status and whichever side is to move
  /// *in the position that status was computed for*. On checkmate, the
  /// side to move is the side with no legal escape (the loser), so the
  /// winner is its opponent — this holds whether the position was just
  /// reached via [applyMove] or loaded directly via [fromFen]/[initial].
  static GameResult _resultFor(GameStatus status, Color sideToMove) {
    if (status == GameStatus.checkmate) {
      return GameResult.fromCheckmate(sideToMove.opponent);
    }
    if (status.isDraw) {
      return GameResult.draw;
    }
    return GameResult.ongoing;
  }

  bool get isInCheck => const GameRules().isInCheck(position);

  List<Move> get legalMoves =>
      const MoveGenerator().generateLegalMoves(position);

  /// Applies [move] and returns a new [GameState]. Returns an error
  /// (rather than throwing) if [move] is not currently legal — an illegal
  /// move attempt is an expected, recoverable condition, not a
  /// programmer error.
  Result<GameState, IllegalMoveError> applyMove(
    Move move, {
    MoveGenerator moveGenerator = const MoveGenerator(),
    GameRules gameRules = const GameRules(),
    SanGenerator sanGenerator = const SanGenerator(),
  }) {
    if (status.isGameOver) {
      return const Result.err(
        IllegalMoveError('the game is already over'),
      );
    }

    final legal = moveGenerator.generateLegalMoves(position);
    final matched = legal.where((m) => m == move).toList();
    if (matched.isEmpty) {
      return Result.err(IllegalMoveError('$move is not a legal move in this position'));
    }
    final resolvedMove = matched.first;

    final capturedPiece = resolvedMove.isEnPassant
        ? position.pieceAt(Square(resolvedMove.to.file, resolvedMove.from.rank))
        : position.pieceAt(resolvedMove.to);

    final san = sanGenerator.generate(position, resolvedMove);
    final newPosition = position.applyMove(resolvedMove);
    final newHistory = [...positionHistory, newPosition];
    final newStatus = gameRules.determineStatus(newPosition, newHistory);

    final record = MoveRecord(
      move: resolvedMove,
      san: san,
      sideThatMoved: position.sideToMove,
      capturedPiece: capturedPiece,
      fullmoveNumberBeforeMove: position.fullmoveNumber,
      givesCheck: newStatus == GameStatus.checkmate || gameRules.isInCheck(newPosition),
      givesCheckmate: newStatus == GameStatus.checkmate,
    );

    return Result.ok(
      GameState._(
        position: newPosition,
        positionHistory: newHistory,
        moveHistory: [...moveHistory, record],
        status: newStatus,
        result: _resultFor(newStatus, newPosition.sideToMove),
      ),
    );
  }
}
