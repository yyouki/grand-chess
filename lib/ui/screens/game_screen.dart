import 'package:flutter/material.dart';

import '../../chess_engine/chess_engine.dart' hide Color;
import '../../chess_engine/chess_engine.dart' as engine;
import '../../game/game_controller.dart';
import '../widgets/chess_board.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/game_status_bar.dart';
import '../widgets/move_history_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.whiteName = 'White',
    this.blackName = 'Black',
    this.initialState,
  });

  final String whiteName;
  final String blackName;
  final GameState? initialState;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  bool _promotionDialogOpen = false;
  bool _resultDialogShown = false;
  bool _dialogCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController(initialState: widget.initialState);
    _controller.addListener(_handleControllerChanged);
    _scheduleDialogCheck();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_controller.outcome == null) {
      _resultDialogShown = false;
    }
    _scheduleDialogCheck();
  }

  void _scheduleDialogCheck() {
    if (_dialogCheckScheduled) {
      return;
    }
    _dialogCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dialogCheckScheduled = false;
      if (mounted) {
        _showPendingDialogs();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _showPendingDialogs() {
    if (_controller.isAwaitingPromotionChoice && !_promotionDialogOpen) {
      _promotionDialogOpen = true;
      _showPromotionDialog();
    }
    if (_controller.isGameOver && !_resultDialogShown) {
      _resultDialogShown = true;
      _showResultDialog();
    }
  }

  Future<void> _showPromotionDialog() async {
    final side = _controller.gameState.position.sideToMove;
    final choice = await showPromotionDialog(context, side);
    _promotionDialogOpen = false;
    if (!mounted) {
      return;
    }
    if (choice == null) {
      _controller.cancelSelection();
    } else {
      _controller.choosePromotion(choice);
    }
  }

  Future<void> _showResultDialog() async {
    final outcome = _controller.outcome;
    if (outcome == null) {
      return;
    }
    final action = await showGameResultDialog(context, outcome);
    if (!mounted) {
      return;
    }
    if (action == GameResultAction.newGame) {
      _controller.newGame();
    }
  }

  Future<void> _confirmResign() async {
    final sideToMove = _controller.gameState.position.sideToMove;
    final sideName = sideToMove == engine.Color.white ? 'White' : 'Black';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$sideName resigns?', key: const ValueKey('resign-title')),
        content: const Text('The game ends and the opponent wins.'),
        actions: [
          TextButton(
            key: const ValueKey('resign-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('resign-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (confirmed == true) {
      _controller.resign();
    }
  }

  Future<void> _confirmNewGame() async {
    final inProgress =
        !_controller.isGameOver && _controller.gameState.moveHistory.isNotEmpty;
    if (!inProgress) {
      _controller.newGame();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text('The current game will be lost.'),
        actions: [
          TextButton(
            key: const ValueKey('new-game-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('new-game-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start new game'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (confirmed == true) {
      _controller.newGame();
    }
  }

  Widget _buildStatusBar() {
    return GameStatusBar(
      controller: _controller,
      whiteName: widget.whiteName,
      blackName: widget.blackName,
    );
  }

  Widget _buildControls() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('flip-board'),
              onPressed: _controller.flipOrientation,
              child: const Text('Flip board'),
            ),
            OutlinedButton(
              key: const ValueKey('resign-button'),
              onPressed: _controller.isGameOver ? null : _confirmResign,
              child: const Text('Resign'),
            ),
            OutlinedButton(
              key: const ValueKey('new-game-button'),
              onPressed: _confirmNewGame,
              child: const Text('New game'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBar(),
            const SizedBox(height: 12),
            ChessBoard(controller: _controller),
            const SizedBox(height: 12),
            _buildControls(),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: MoveHistoryPanel(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.biggest.shortestSide;
                  return SizedBox(
                    width: side,
                    height: side,
                    child: ChessBoard(controller: _controller),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 340,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBar(),
                const SizedBox(height: 12),
                _buildControls(),
                const SizedBox(height: 12),
                Expanded(child: MoveHistoryPanel(controller: _controller)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local game')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 720 &&
                constraints.maxWidth > constraints.maxHeight;
            return wide ? _buildWideLayout() : _buildNarrowLayout();
          },
        ),
      ),
    );
  }
}
