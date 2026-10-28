import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../chess_engine/chess_engine.dart' hide Color;
import '../../chess_engine/chess_engine.dart' as engine;
import '../../game/game_controller.dart';
import '../theme/board_colors.dart';
import 'piece_glyph.dart';

class ChessBoard extends StatefulWidget {
  const ChessBoard({super.key, required this.controller});

  final GameController controller;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Chess board');
  Square _cursor = const Square(4, 1);
  bool _keyboardActive = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  void _handleTap(Square square) {
    _focusNode.requestFocus();
    setState(() {
      _cursor = square;
      _keyboardActive = false;
    });
    widget.controller.selectSquare(square);
  }

  void _handleDragStarted(Square square) {
    _focusNode.requestFocus();
    setState(() {
      _cursor = square;
      _keyboardActive = false;
    });
    if (widget.controller.selectedSquare != square) {
      widget.controller.selectSquare(square);
    }
  }

  bool _canDrop(Square from, Square to) {
    final controller = widget.controller;
    if (controller.selectedSquare != from) {
      return false;
    }
    return controller.legalMovesFromSelected.any((move) => move.to == to);
  }

  void _handleDrop(Square to) {
    setState(() {
      _cursor = to;
      _keyboardActive = false;
    });
    widget.controller.selectSquare(to);
  }

  int _clampIndex(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 7) {
      return 7;
    }
    return value;
  }

  void _moveCursor(int columnDelta, int rowDelta) {
    final flipped = widget.controller.orientation == engine.Color.black;
    final fileDelta = flipped ? -columnDelta : columnDelta;
    final rankDelta = flipped ? -rowDelta : rowDelta;
    setState(() {
      _keyboardActive = true;
      _cursor = Square(
        _clampIndex(_cursor.file + fileDelta),
        _clampIndex(_cursor.rank + rankDelta),
      );
    });
  }

  void _activateCursor() {
    setState(() {
      _keyboardActive = true;
    });
    widget.controller.selectSquare(_cursor);
  }

  Map<ShortcutActivator, VoidCallback> _bindings() {
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.escape):
          widget.controller.cancelSelection,
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          _moveCursor(0, 1),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          _moveCursor(0, -1),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          _moveCursor(-1, 0),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          _moveCursor(1, 0),
      const SingleActivator(LogicalKeyboardKey.enter): _activateCursor,
      const SingleActivator(LogicalKeyboardKey.space): _activateCursor,
    };
  }

  Square? _checkedKingSquare() {
    final state = widget.controller.gameState;
    if (!state.isInCheck) {
      return null;
    }
    return state.position.findKing(state.position.sideToMove);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) => _buildBoard(),
    );
  }

  Widget _buildBoard() {
    final controller = widget.controller;
    final view = _BoardView(
      position: controller.gameState.position,
      selected: controller.selectedSquare,
      targets: controller.legalMovesFromSelected,
      lastMove: controller.lastMove,
      checkedKing: _checkedKingSquare(),
      interactive:
          !controller.isGameOver && !controller.isAwaitingPromotionChoice,
      flipped: controller.orientation == engine.Color.black,
      focused: _focusNode.hasFocus && _keyboardActive,
      cursor: _cursor,
    );
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final squareSize = constraints.biggest.shortestSide / 8;
          return CallbackShortcuts(
            bindings: _bindings(),
            child: Focus(
              focusNode: _focusNode,
              child: Semantics(
                container: true,
                label: 'Chess board',
                child: Column(
                  children: [
                    for (var row = 0; row < 8; row++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var column = 0; column < 8; column++)
                              Expanded(
                                child: _buildSquare(
                                  view,
                                  row,
                                  column,
                                  squareSize,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSquare(_BoardView view, int row, int column, double squareSize) {
    final square = Square(
      view.flipped ? 7 - column : column,
      view.flipped ? row : 7 - row,
    );
    final name = square.algebraic;
    final piece = view.position.pieceAt(square);
    final isLight = (square.file + square.rank).isOdd;
    final last = view.lastMove;
    final isLastMove =
        last != null && (last.from == square || last.to == square);
    final isSelected = view.selected == square;
    final isChecked = view.checkedKing == square;
    final isTarget = view.targets.any((move) => move.to == square);
    final isCaptureTarget = view.targets.any(
      (move) => move.to == square && move.isCapture,
    );
    return DragTarget<Square>(
      onWillAcceptWithDetails: (details) => _canDrop(details.data, square),
      onAcceptWithDetails: (_) => _handleDrop(square),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          key: ValueKey('square-$name'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleTap(square),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: isLight
                    ? BoardColors.lightSquare
                    : BoardColors.darkSquare,
              ),
              if (isLastMove)
                ColoredBox(
                  key: ValueKey('last-move-$name'),
                  color: BoardColors.lastMove,
                ),
              if (isSelected)
                ColoredBox(
                  key: ValueKey('selected-$name'),
                  color: BoardColors.selection,
                ),
              if (isChecked)
                ColoredBox(
                  key: ValueKey('check-$name'),
                  color: BoardColors.check,
                ),
              if (candidateData.isNotEmpty)
                const ColoredBox(color: BoardColors.dropHover),
              if (isTarget && !isCaptureTarget)
                _buildLegalMarker(name, squareSize),
              if (isCaptureTarget) _buildCaptureMarker(name, squareSize),
              if (piece != null)
                Center(
                  key: ValueKey('slot-$name'),
                  child: _buildPiece(view, square, piece, squareSize),
                ),
              if (column == 0)
                Positioned(
                  left: squareSize * 0.06,
                  top: squareSize * 0.03,
                  child: _buildCoordinate(
                    key: ValueKey('rank-label-$name'),
                    text: '${square.rank + 1}',
                    onLight: isLight,
                    squareSize: squareSize,
                  ),
                ),
              if (row == 7)
                Positioned(
                  right: squareSize * 0.06,
                  bottom: squareSize * 0.03,
                  child: _buildCoordinate(
                    key: ValueKey('file-label-$name'),
                    text: String.fromCharCode(0x61 + square.file),
                    onLight: isLight,
                    squareSize: squareSize,
                  ),
                ),
              if (view.focused && view.cursor == square)
                IgnorePointer(
                  child: DecoratedBox(
                    key: ValueKey('cursor-$name'),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: BoardColors.keyboardCursor,
                        width: squareSize * 0.07,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegalMarker(String name, double squareSize) {
    final dot = squareSize * 0.3;
    return Center(
      child: SizedBox(
        key: ValueKey('legal-$name'),
        width: dot,
        height: dot,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: BoardColors.moveHint,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureMarker(String name, double squareSize) {
    final ring = squareSize * 0.92;
    return Center(
      child: SizedBox(
        key: ValueKey('capture-$name'),
        width: ring,
        height: ring,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: BoardColors.moveHint,
              width: squareSize * 0.08,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinate({
    required Key key,
    required String text,
    required bool onLight,
    required double squareSize,
  }) {
    return Text(
      text,
      key: key,
      style: TextStyle(
        fontSize: squareSize * 0.2,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
        color: onLight
            ? BoardColors.coordinateOnLight
            : BoardColors.coordinateOnDark,
      ),
    );
  }

  Widget _buildPiece(
    _BoardView view,
    Square square,
    Piece piece,
    double squareSize,
  ) {
    final glyphSize = squareSize * 0.82;
    final glyph = PieceGlyph(
      key: ValueKey('piece-${square.algebraic}'),
      piece: piece,
      size: glyphSize,
    );
    final movable = view.interactive && piece.color == view.position.sideToMove;
    if (!movable) {
      return glyph;
    }
    return Draggable<Square>(
      data: square,
      maxSimultaneousDrags: 1,
      hitTestBehavior: HitTestBehavior.opaque,
      onDragStarted: () => _handleDragStarted(square),
      feedback: Material(
        type: MaterialType.transparency,
        child: PieceGlyph(piece: piece, size: squareSize * 1.05),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: PieceGlyph(piece: piece, size: glyphSize),
      ),
      child: glyph,
    );
  }
}

class _BoardView {
  const _BoardView({
    required this.position,
    required this.selected,
    required this.targets,
    required this.lastMove,
    required this.checkedKing,
    required this.interactive,
    required this.flipped,
    required this.focused,
    required this.cursor,
  });

  final Position position;
  final Square? selected;
  final List<Move> targets;
  final Move? lastMove;
  final Square? checkedKing;
  final bool interactive;
  final bool flipped;
  final bool focused;
  final Square cursor;
}
