import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../chess_engine/chess_engine.dart' hide Color;
import '../../chess_engine/chess_engine.dart' as engine;
import '../../game/game_controller.dart';
import 'piece_glyph.dart';
import 'chess_board_3d_renderer.dart';

/// A perspective-rendered chessboard with a draggable 360-degree camera.
class ChessBoard extends StatefulWidget {
  const ChessBoard({super.key, required this.controller});

  final GameController controller;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  final FocusNode _focusNode = FocusNode(debugLabel: '3D chess board');

  Square _cursor = const Square(4, 1);
  Offset? _pointerDown;
  Offset? _lastPointerPosition;
  Square? _dragFrom;
  Square? _gestureStartSquare;
  int? _activePointer;
  bool _gestureMoved = false;
  bool _rotating = false;
  bool _keyboardActive = false;
  double _yaw = -0.55;
  double _pitch = 0.90;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  ChessBoardProjection _projection(Size size, bool flipped) {
    return ChessBoardProjection(
      size: size,
      yaw: _yaw,
      pitch: _pitch,
      flipped: flipped,
    );
  }

  Square? _squareAt(Offset point, ChessBoardProjection projection) {
    final position = widget.controller.gameState.position;
    final side = projection.size.shortestSide;

    // Prefer a real piece when the pointer is on its raised 3D model.
    // The small threshold prevents a neighboring empty square stealing taps.
    Square? closestPiece;
    var closestPieceDistance = double.infinity;
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final square = Square(file, rank);
        final piece = position.pieceAt(square);
        if (piece == null) {
          continue;
        }
        final centerHeight = _pieceHeightFor(piece.type) * 0.53;
        final center = projection.centerOf(square, height: centerHeight);
        final distance = (center - point).distance;
        if (distance < closestPieceDistance) {
          closestPieceDistance = distance;
          closestPiece = square;
        }
      }
    }
    if (closestPiece != null && closestPieceDistance < side * 0.03) {
      return closestPiece;
    }

    // A projected square polygon provides reliable input for the tilted board.
    for (var row = 0; row < 8; row++) {
      for (var column = 0; column < 8; column++) {
        final square = projection.squareAtVisualPosition(column, row);
        if (_containsPoint(projection.polygonOf(square), point)) {
          return square;
        }
      }
    }

    // The top of a tall piece may extend beyond its square polygon. Use the
    // closest square only when the pointer is still within the board footprint.
    Square? closestSquare;
    var closestDistance = double.infinity;
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final square = Square(file, rank);
        final center = projection.centerOf(square);
        final distance = (center - point).distance;
        if (distance < closestDistance) {
          closestDistance = distance;
          closestSquare = square;
        }
      }
    }
    if (closestDistance <= side * 0.16) {
      return closestSquare;
    }
    return null;
  }

  bool _containsPoint(List<Offset> polygon, Offset point) {
    var inside = false;
    var previous = polygon.length - 1;
    for (var current = 0; current < polygon.length; current++) {
      final a = polygon[current];
      final b = polygon[previous];
      final crosses = (a.dy > point.dy) != (b.dy > point.dy);
      if (crosses) {
        final intersectionX =
            (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx;
        if (point.dx < intersectionX) {
          inside = !inside;
        }
      }
      previous = current;
    }
    return inside;
  }

  bool _canDragFrom(Square? square) {
    if (square == null) {
      return false;
    }
    final controller = widget.controller;
    final piece = controller.gameState.position.pieceAt(square);
    return !controller.isGameOver &&
        !controller.isAwaitingPromotionChoice &&
        piece != null &&
        piece.color == controller.gameState.position.sideToMove;
  }

  void _handlePointerDown(
    PointerDownEvent event,
    ChessBoardProjection projection,
  ) {
    if (_activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    _pointerDown = event.localPosition;
    _lastPointerPosition = event.localPosition;
    _gestureStartSquare = _squareAt(event.localPosition, projection);
    _gestureMoved = false;
    _dragFrom = null;
    _rotating = false;
    _focusNode.requestFocus();
  }

  void _handlePointerMove(
    PointerMoveEvent event,
    ChessBoardProjection projection,
  ) {
    if (event.pointer != _activePointer) {
      return;
    }
    final startPoint = _pointerDown;
    if (startPoint == null) {
      return;
    }

    final previousPoint = _lastPointerPosition ?? startPoint;
    final delta = event.localPosition - previousPoint;
    _lastPointerPosition = event.localPosition;

    if (!_gestureMoved && (event.localPosition - startPoint).distance >= 6) {
      _gestureMoved = true;
      final square = _gestureStartSquare;
      final piece = square == null
          ? null
          : widget.controller.gameState.position.pieceAt(square);

      if (_canDragFrom(square)) {
        _dragFrom = square;
        if (widget.controller.selectedSquare != square) {
          widget.controller.selectSquare(square!);
        }
        setState(() {
          _cursor = square!;
          _keyboardActive = false;
        });
      } else if (piece == null) {
        // Dragging empty board space rotates the camera, not a chess piece.
        _rotating = true;
      }
    }

    if (_dragFrom != null || !_rotating || delta == Offset.zero) {
      return;
    }
    setState(() {
      _yaw = (_yaw + delta.dx * 0.012) % (math.pi * 2);
      _pitch = (_pitch + delta.dy * 0.004).clamp(0.43, 1.18).toDouble();
    });
  }

  void _handlePointerUp(PointerUpEvent event, ChessBoardProjection projection) {
    if (event.pointer != _activePointer) {
      return;
    }

    final wasMoved = _gestureMoved;
    final from = _dragFrom;
    if (!wasMoved) {
      final square = _squareAt(event.localPosition, projection);
      if (square != null) {
        setState(() {
          _cursor = square;
          _keyboardActive = false;
        });
        widget.controller.selectSquare(square);
      }
    } else if (from != null) {
      final destination = _squareAt(event.localPosition, projection);
      if (destination != null && destination != from) {
        final isLegal = widget.controller.legalMovesFromSelected.any(
          (move) => move.to == destination,
        );
        if (isLegal) {
          widget.controller.selectSquare(destination);
        }
      }
    }
    _resetPointerGesture();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointer) {
      _resetPointerGesture();
    }
  }

  void _resetPointerGesture() {
    _activePointer = null;
    _pointerDown = null;
    _lastPointerPosition = null;
    _gestureStartSquare = null;
    _dragFrom = null;
    _gestureMoved = false;
    _rotating = false;
  }

  void _resetView() {
    setState(() {
      _yaw = -0.55;
      _pitch = 0.90;
    });
  }

  int _clampIndex(int value) => value.clamp(0, 7);

  void _moveCursor(int columnDelta, int rowDelta) {
    final flipped = widget.controller.orientation == engine.Color.black;
    setState(() {
      _keyboardActive = true;
      _cursor = Square(
        _clampIndex(_cursor.file + (flipped ? -columnDelta : columnDelta)),
        _clampIndex(_cursor.rank + (flipped ? -rowDelta : rowDelta)),
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

  List<Widget> _buildAnchors(
    ChessBoardProjection projection, {
    required Position position,
    required Square? selected,
    required List<Move> targets,
    required Move? lastMove,
    required Square? checkedKing,
    required bool interactive,
    required bool focused,
  }) {
    final anchors = <Widget>[];
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final square = Square(file, rank);
        final name = square.algebraic;
        final piece = position.pieceAt(square);
        final visual = projection.visualPosition(square);
        final center = projection.centerOf(square);
        final isLast =
            lastMove != null &&
            (lastMove.from == square || lastMove.to == square);
        final isSelected = selected == square;
        final isChecked = checkedKing == square;
        final isTarget = targets.any((move) => move.to == square);
        final isCapture = targets.any(
          (move) => move.to == square && move.isCapture,
        );
        final isCursor = focused && _cursor == square;

        final markerChildren = <Widget>[
          SizedBox(key: ValueKey('square-$name'), width: 1, height: 1),
          if (isLast)
            SizedBox(key: ValueKey('last-move-$name'), width: 1, height: 1),
          if (isSelected)
            SizedBox(key: ValueKey('selected-$name'), width: 1, height: 1),
          if (isChecked)
            SizedBox(key: ValueKey('check-$name'), width: 1, height: 1),
          if (isTarget && !isCapture)
            SizedBox(key: ValueKey('legal-$name'), width: 1, height: 1),
          if (isCapture)
            SizedBox(key: ValueKey('capture-$name'), width: 1, height: 1),
          if (isCursor)
            SizedBox(key: ValueKey('cursor-$name'), width: 1, height: 1),
          if (visual.$1 == 0)
            SizedBox(key: ValueKey('rank-label-$name'), width: 1, height: 1),
          if (visual.$2 == 7)
            SizedBox(key: ValueKey('file-label-$name'), width: 1, height: 1),
        ];

        if (piece != null) {
          final glyph = Opacity(
            opacity: 0,
            child: PieceGlyph(
              key: ValueKey('piece-$name'),
              piece: piece,
              size: 1,
            ),
          );
          if (interactive &&
              !widget.controller.isAwaitingPromotionChoice &&
              piece.color == position.sideToMove) {
            markerChildren.add(
              Draggable<Square>(
                data: square,
                maxSimultaneousDrags: 1,
                feedback: const SizedBox.shrink(),
                childWhenDragging: glyph,
                child: glyph,
              ),
            );
          } else {
            markerChildren.add(glyph);
          }
        }

        anchors.add(
          Positioned(
            left: center.dx - 0.5,
            top: center.dy - 0.5,
            width: 1,
            height: 1,
            child: IgnorePointer(
              child: Stack(clipBehavior: Clip.none, children: markerChildren),
            ),
          ),
        );
      }
    }
    return anchors;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final controller = widget.controller;
        final position = controller.gameState.position;
        final flipped = controller.orientation == engine.Color.black;
        final selected = controller.selectedSquare;
        final targets = controller.legalMovesFromSelected;
        final lastMove = controller.lastMove;
        final checkedKing = _checkedKingSquare();
        final interactive =
            !controller.isGameOver && !controller.isAwaitingPromotionChoice;
        final focused = _focusNode.hasFocus && _keyboardActive;

        return AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.biggest.shortestSide;
              final size = Size(side, side);
              final projection = _projection(size, flipped);
              return CallbackShortcuts(
                bindings: _bindings(),
                child: Focus(
                  focusNode: _focusNode,
                  child: Semantics(
                    container: true,
                    label:
                        'Three-dimensional chess board. Drag an empty area to rotate the board 360 degrees. Tap a square to move.',
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (event) =>
                                _handlePointerDown(event, projection),
                            onPointerMove: (event) =>
                                _handlePointerMove(event, projection),
                            onPointerUp: (event) =>
                                _handlePointerUp(event, projection),
                            onPointerCancel: _handlePointerCancel,
                            child: Stack(
                              fit: StackFit.expand,
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                CustomPaint(
                                  key: const ValueKey('chess-board-3d-scene'),
                                  painter: Chess3DScenePainter(
                                    position: position,
                                    selected: selected,
                                    targets: targets,
                                    lastMove: lastMove,
                                    checkedKing: checkedKing,
                                    cursor: _cursor,
                                    cursorVisible: focused,
                                    projection: projection,
                                  ),
                                ),
                                ..._buildAnchors(
                                  projection,
                                  position: position,
                                  selected: selected,
                                  targets: targets,
                                  lastMove: lastMove,
                                  checkedKing: checkedKing,
                                  interactive: interactive,
                                  focused: focused,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xAA141820),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0x557D8796),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.threed_rotation,
                                        size: 14,
                                        color: Color(0xFFE8EDF4),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'DRAG TO ROTATE 360°',
                                        style: TextStyle(
                                          color: Color(0xFFE8EDF4),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Tooltip(
                              message: 'Reset 3D view',
                              child: Material(
                                color: const Color(0xCC202630),
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  key: const ValueKey('reset-3d-view'),
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: _resetView,
                                  child: const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: Icon(
                                      Icons.center_focus_strong,
                                      size: 17,
                                      color: Color(0xFFF5F3EF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

double _pieceHeightFor(PieceType type) {
  switch (type) {
    case PieceType.pawn:
      return 0.67;
    case PieceType.knight:
      return 0.87;
    case PieceType.bishop:
      return 0.85;
    case PieceType.rook:
      return 0.84;
    case PieceType.queen:
      return 0.93;
    case PieceType.king:
      return 1.15;
  }
}
