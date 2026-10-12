import 'package:flutter/foundation.dart';

import '../chess_engine/chess_engine.dart' hide Color;
import '../chess_engine/chess_engine.dart' as engine;
import 'game_outcome.dart';

/// Application/session layer for a local (human vs human) game.
///
/// Owns only what the chess engine has no business knowing: which square is
/// selected, a promotion awaiting the player's choice, a resignation, board
/// orientation, and the last user-facing error. Every chess fact — whose
/// piece is where, what is legal, whether the game is over — comes from
/// [GameState]; this class never re-implements a rule, it only forwards the
/// player's intent to the engine and reports what the engine says.
///
/// State management: [ChangeNotifier] plus Flutter's own `ListenableBuilder`.
/// The whole UI state is one small object with one change signal, which is
/// exactly what the framework's built-in primitives are for, so no state
/// management package is added (see ADR-011 in Grand-Chess-ADR.md).
class GameController extends ChangeNotifier {
  GameController({GameState? initialState})
    : _gameState = initialState ?? GameState.initial() {
    _legalMoves = _gameState.legalMoves;
  }

  static Result<GameController, ChessEngineError> fromFen(String fen) {
    final parsed = GameState.fromFen(fen);
    if (parsed.isErr) return Result.err(parsed.errorOrNull!);
    return Result.ok(GameController(initialState: parsed.valueOrNull!));
  }

  GameState _gameState;

  /// Legal moves for [_gameState], computed once per state change rather
  /// than once per tap or per rebuild.
  List<Move> _legalMoves = const [];

  Square? _selectedSquare;
  Move? _pendingPromotionMove;
  GameOutcome? _resignationOutcome;
  String? _errorMessage;
  engine.Color _orientation = engine.Color.white;

  GameState get gameState => _gameState;
  Square? get selectedSquare => _selectedSquare;

  /// The from/to of a pawn move that reaches the last rank and is waiting for
  /// the player to pick a promotion piece.
  Move? get pendingPromotionMove => _pendingPromotionMove;
  bool get isAwaitingPromotionChoice => _pendingPromotionMove != null;
  String? get errorMessage => _errorMessage;
  engine.Color get orientation => _orientation;

  /// Why the game ended and who won, or null while it is still in progress.
  GameOutcome? get outcome {
    final resigned = _resignationOutcome;
    if (resigned != null) return resigned;
    if (!_gameState.status.isGameOver) return null;
    return GameOutcome.fromStatus(_gameState.status, _gameState.result);
  }

  bool get isGameOver => outcome != null;

  Move? get lastMove =>
      _gameState.moveHistory.isEmpty ? null : _gameState.moveHistory.last.move;

  /// Legal moves from the selected square, taken from the engine's own list.
  List<Move> get legalMovesFromSelected {
    final selected = _selectedSquare;
    if (selected == null) return const [];
    return _legalMoves
        .where((move) => move.from == selected)
        .toList(growable: false);
  }

  /// Handles a tap on [square]: selects an own piece, or — when a piece is
  /// already selected and [square] is one of its legal destinations — makes
  /// the move. Anything else clears the selection.
  void selectSquare(Square square) {
    if (isGameOver || isAwaitingPromotionChoice) return;
    _errorMessage = null;

    final from = _selectedSquare;
    if (from != null) {
      final candidates = _legalMoves
          .where((move) => move.from == from && move.to == square)
          .toList();
      if (candidates.isNotEmpty) {
        if (candidates.first.promotion != null) {
          _pendingPromotionMove = Move(from: from, to: square);
          _selectedSquare = null;
          notifyListeners();
          return;
        }
        _commitMove(candidates.first);
        return;
      }
    }

    final piece = _gameState.position.pieceAt(square);
    if (piece != null && piece.color == _gameState.position.sideToMove) {
      _selectedSquare = square == from ? null : square;
    } else {
      _selectedSquare = null;
    }
    notifyListeners();
  }

  /// Completes a pending promotion with the player's chosen piece. The engine
  /// validates it; an invalid choice surfaces as [errorMessage].
  void choosePromotion(PieceType type) {
    final pending = _pendingPromotionMove;
    if (pending == null) return;
    _commitMove(Move(from: pending.from, to: pending.to, promotion: type));
  }

  void cancelSelection() {
    if (_selectedSquare == null && _pendingPromotionMove == null) return;
    _selectedSquare = null;
    _pendingPromotionMove = null;
    notifyListeners();
  }

  /// The side to move gives up; the opponent wins.
  void resign() {
    if (isGameOver) return;
    _resignationOutcome = GameOutcome.resignation(
      _gameState.position.sideToMove,
    );
    _selectedSquare = null;
    _pendingPromotionMove = null;
    notifyListeners();
  }

  void newGame() {
    _setGameState(GameState.initial());
    _selectedSquare = null;
    _pendingPromotionMove = null;
    _resignationOutcome = null;
    _errorMessage = null;
    notifyListeners();
  }

  void flipOrientation() {
    _orientation = _orientation == engine.Color.white
        ? engine.Color.black
        : engine.Color.white;
    notifyListeners();
  }

  void _commitMove(Move move) {
    final result = _gameState.applyMove(move);
    if (result.isOk) {
      _setGameState(result.valueOrNull!);
      _errorMessage = null;
    } else {
      _errorMessage = result.errorOrNull!.message;
    }
    _selectedSquare = null;
    _pendingPromotionMove = null;
    notifyListeners();
  }

  void _setGameState(GameState state) {
    _gameState = state;
    _legalMoves = state.legalMoves;
  }
}
