import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../chess_engine/chess_engine.dart' hide Color;
import '../../chess_engine/chess_engine.dart' as engine;
import '../../game/chess_bot.dart';
import '../../game/game_controller.dart';
import '../../game/game_mode.dart';
import '../theme/chess_visual_theme.dart';
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
    this.mode = GameMode.localTwoPlayer,
    this.botLevel = BotLevel.easy,
  });

  final String whiteName;
  final String blackName;
  final GameState? initialState;
  final GameMode mode;
  final BotLevel botLevel;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  bool _promotionDialogOpen = false;
  bool _resultDialogShown = false;
  bool _dialogCheckScheduled = false;
  bool _botThinking = false;
  int _botTurnToken = 0;
  BoardFinish _boardFinish = BoardFinish.walnut;
  PieceFinish _pieceFinish = PieceFinish.classic;

  @override
  void initState() {
    super.initState();
    _controller = GameController(initialState: widget.initialState);
    _controller.addListener(_handleControllerChanged);
    _enterImmersiveLandscape();
    _scheduleDialogCheck();
    _queueBotIfNeeded();
  }

  bool get _supportsImmersiveMobileUi =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _enterImmersiveLandscape() {
    // Lock orientation and hide system chrome on mobile only. Desktop window
    // management remains under the user's control.
    if (!_supportsImmersiveMobileUi) return;
    unawaited(
      SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  void dispose() {
    _botTurnToken++;
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    if (_supportsImmersiveMobileUi) {
      unawaited(
        SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]),
      );
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_controller.outcome == null) {
      _resultDialogShown = false;
    }
    _scheduleDialogCheck();
    _queueBotIfNeeded();
  }

  bool get _botTurn =>
      widget.mode == GameMode.vsComputer &&
      _controller.gameState.position.sideToMove == engine.Color.black &&
      !_controller.isGameOver &&
      !_controller.isAwaitingPromotionChoice;

  void _queueBotIfNeeded() {
    final ticket = ++_botTurnToken;
    if (!_botTurn) {
      if (_botThinking && mounted) {
        setState(() => _botThinking = false);
      }
      return;
    }

    if (mounted && !_botThinking) {
      setState(() => _botThinking = true);
    }
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted || ticket != _botTurnToken || !_botTurn) {
        return;
      }
      final move = const ChessBot().chooseMove(
        _controller.gameState,
        level: widget.botLevel,
      );
      if (move != null && mounted && ticket == _botTurnToken) {
        _controller.playMove(move);
      }
      if (mounted) {
        setState(() => _botThinking = false);
      }
    });
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
    if (mounted && confirmed == true) {
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
    if (mounted && confirmed == true) {
      _botTurnToken++;
      _controller.newGame();
    }
  }

  void _undoMove() {
    _botTurnToken++;
    if (_botThinking) setState(() => _botThinking = false);
    if (widget.mode == GameMode.vsComputer) {
      final blackToMove =
          _controller.gameState.position.sideToMove == engine.Color.black;
      _controller.undoMove();
      if (!blackToMove) {
        _controller.undoMove();
      }
    } else {
      _controller.undoMove();
    }
  }

  void _redoMove() {
    _botTurnToken++;
    if (_botThinking) setState(() => _botThinking = false);
    if (widget.mode == GameMode.vsComputer) {
      _controller.redoMove();
      if (_controller.gameState.position.sideToMove == engine.Color.black) {
        _controller.redoMove();
      }
    } else {
      _controller.redoMove();
    }
  }

  String _buildPgn() {
    final records = _controller.gameState.moveHistory;
    final out = StringBuffer();
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      if (record.sideThatMoved == engine.Color.white) {
        if (out.isNotEmpty) out.write(' ');
        out.write('${record.fullmoveNumberBeforeMove}. ${record.san}');
      } else {
        final pairedWhiteMove =
            index > 0 &&
            records[index - 1].sideThatMoved == engine.Color.white &&
            records[index - 1].fullmoveNumberBeforeMove ==
                record.fullmoveNumberBeforeMove;
        if (pairedWhiteMove) {
          out.write(' ${record.san}');
        } else {
          if (out.isNotEmpty) out.write(' ');
          out.write('${record.fullmoveNumberBeforeMove}... ${record.san}');
        }
      }
    }

    final result = _controller.outcome?.result ?? _controller.gameState.result;
    final resultText = switch (result) {
      engine.GameResult.whiteWins => '1-0',
      engine.GameResult.blackWins => '0-1',
      engine.GameResult.draw => '1/2-1/2',
      engine.GameResult.ongoing => '*',
    };
    if (out.isNotEmpty) out.write(' ');
    out.write(resultText);
    return out.toString();
  }

  Future<void> _showExportDialog({required bool asPgn}) async {
    final content = asPgn
        ? _buildPgn()
        : const engine.FenCodec().toFen(_controller.gameState.position);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(asPgn ? 'Export PGN' : 'Current FEN'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: SelectableText(content)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEE3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GameStatusBar(
        controller: _controller,
        whiteName: widget.whiteName,
        blackName: widget.blackName,
      ),
    );
  }

  Widget _buildControls() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        IconButton(
          key: const ValueKey('flip-board'),
          tooltip: 'Flip board',
          onPressed: _controller.flipOrientation,
          icon: const Icon(Icons.flip),
          color: const Color(0xFFF3E8D4),
        ),
        IconButton(
          key: const ValueKey('undo-move'),
          tooltip: 'Undo move',
          onPressed: _controller.canUndo ? _undoMove : null,
          icon: const Icon(Icons.undo),
          color: const Color(0xFFF3E8D4),
          disabledColor: const Color(0xFF65717F),
        ),
        IconButton(
          key: const ValueKey('redo-move'),
          tooltip: 'Redo move',
          onPressed: _controller.canRedo ? _redoMove : null,
          icon: const Icon(Icons.redo),
          color: const Color(0xFFF3E8D4),
          disabledColor: const Color(0xFF65717F),
        ),
        PopupMenuButton<String>(
          tooltip: 'Export game',
          icon: const Icon(Icons.ios_share, color: Color(0xFFF3E8D4)),
          onSelected: (value) => _showExportDialog(asPgn: value == 'pgn'),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'pgn', child: Text('Export PGN')),
            PopupMenuItem(value: 'fen', child: Text('Copy FEN')),
          ],
        ),
        IconButton(
          key: const ValueKey('resign-button'),
          tooltip: 'Resign',
          onPressed: _controller.isGameOver ? null : _confirmResign,
          icon: const Icon(Icons.flag_outlined),
          color: const Color(0xFFF3E8D4),
        ),
        IconButton(
          key: const ValueKey('new-game-button'),
          tooltip: 'New game',
          onPressed: _confirmNewGame,
          icon: const Icon(Icons.refresh),
          color: const Color(0xFFF3E8D4),
        ),
      ],
    );
  }

  Widget _buildVisualSettings() {
    return Column(
      children: [
        DropdownButtonFormField<BoardFinish>(
          key: const ValueKey('board-finish-choice'),
          initialValue: _boardFinish,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Chessboard',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final finish in BoardFinish.values)
              DropdownMenuItem(value: finish, child: Text(finish.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _boardFinish = value);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PieceFinish>(
          key: const ValueKey('style-choice-pieces'),
          initialValue: _pieceFinish,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Chess pieces',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final finish in PieceFinish.values)
              DropdownMenuItem(value: finish, child: Text(finish.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _pieceFinish = value);
          },
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ChessBoard(
                    controller: _controller,
                    canSelect: !_botTurn,
                    boardFinish: _boardFinish,
                    pieceFinish: _pieceFinish,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildControls(),
            const SizedBox(height: 12),
            _buildVisualSettings(),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: MoveHistoryPanel(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints) {
    final panelWidth = math
        .min(340.0, math.max(250.0, constraints.maxWidth * 0.31))
        .toDouble();
    final availableBoardWidth = (constraints.maxWidth - panelWidth - 28)
        .clamp(220.0, 2000.0)
        .toDouble();
    final boardSide = math
        .min(math.max(220.0, constraints.maxHeight - 16), availableBoardWidth)
        .toDouble();
    return Row(
      children: [
        Expanded(
          child: Center(
            child: SizedBox.square(
              dimension: boardSide,
              child: ChessBoard(
                controller: _controller,
                canSelect: !_botTurn,
                boardFinish: _boardFinish,
                pieceFinish: _pieceFinish,
              ),
            ),
          ),
        ),
        SizedBox(
          width: panelWidth,
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2835),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF34485B)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 16,
                  offset: Offset(-4, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.view_in_ar,
                      color: Color(0xFFD8B77C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.mode == GameMode.vsComputer
                            ? '3D CHESS · VS BOT'
                            : '3D CHESS · LOCAL',
                        key: const ValueKey('game-screen-title'),
                        style: const TextStyle(
                          color: Color(0xFFF4E9D6),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Exit game',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                      color: const Color(0xFFF4E9D6),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildStatusCard(),
                if (_botThinking)
                  const Padding(
                    padding: EdgeInsets.only(top: 5, bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_alt,
                          size: 16,
                          color: Color(0xFFD8B77C),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Bot is thinking…',
                          style: TextStyle(
                            color: Color(0xFFD8B77C),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                _buildControls(),
                const SizedBox(height: 6),
                _buildVisualSettings(),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: const Color(0xFFF4EEE3),
                      padding: const EdgeInsets.all(4),
                      child: MoveHistoryPanel(controller: _controller),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TAP PIECE → TAP DESTINATION  ·  DRAG EMPTY BOARD TO ROTATE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFACB8C5),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final preferWide = screenSize.width >= 600 &&
        screenSize.width > screenSize.height;
    final title = widget.mode == GameMode.vsComputer
        ? '3D Chess · VS Bot'
        : '3D Chess · Local';
    return Scaffold(
      backgroundColor: const Color(0xFF101821),
      appBar: preferWide ? null : AppBar(title: Text(title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 600 &&
                constraints.maxWidth > constraints.maxHeight;
            return wide ? _buildWideLayout(constraints) : _buildNarrowLayout();
          },
        ),
      ),
    );
  }
}
