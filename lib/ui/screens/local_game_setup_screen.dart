import 'package:flutter/material.dart';

import '../../game/chess_bot.dart';
import '../../game/chess_clock.dart';
import '../../game/game_mode.dart';
import 'game_screen.dart';

class LocalGameSetupScreen extends StatefulWidget {
  const LocalGameSetupScreen({super.key});

  @override
  State<LocalGameSetupScreen> createState() => _LocalGameSetupScreenState();
}

class _LocalGameSetupScreenState extends State<LocalGameSetupScreen> {
  final TextEditingController _whiteController = TextEditingController();
  final TextEditingController _blackController = TextEditingController();

  GameMode _mode = GameMode.localTwoPlayer;
  BotLevel _botLevel = BotLevel.easy;
  ChessTimeControl _timeControl = ChessTimeControl.untimed;

  @override
  void dispose() {
    _whiteController.dispose();
    _blackController.dispose();
    super.dispose();
  }

  String _nameOrDefault(TextEditingController controller, String fallback) {
    final trimmed = controller.text.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  void _startGame() {
    final whiteName = _nameOrDefault(_whiteController, 'White');
    final blackName = _mode == GameMode.vsComputer
        ? 'Grand Bot'
        : _nameOrDefault(_blackController, 'Black');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GameScreen(
          whiteName: whiteName,
          blackName: blackName,
          mode: _mode,
          botLevel: _botLevel,
          timeControl: _timeControl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Local Game')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Two players, one device. Names are optional.',
                    key: ValueKey('setup-hint'),
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<GameMode>(
                    key: const ValueKey('game-mode-choice'),
                    initialValue: _mode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Game mode',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: GameMode.localTwoPlayer,
                        child: Text('Two players · same device'),
                      ),
                      DropdownMenuItem(
                        value: GameMode.vsComputer,
                        child: Text('Play against a bot'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) setState(() => _mode = mode);
                    },
                  ),
                  if (_mode == GameMode.vsComputer) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BotLevel>(
                      key: const ValueKey('bot-level-choice'),
                      initialValue: _botLevel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Bot style',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final level in BotLevel.values)
                          DropdownMenuItem(
                            value: level,
                            child: Text(level.label),
                          ),
                      ],
                      onChanged: (level) {
                        if (level != null) setState(() => _botLevel = level);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ChessTimeControl>(
                    key: const ValueKey('time-control-choice'),
                    initialValue: _timeControl,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Time control',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final control in ChessTimeControl.values)
                        DropdownMenuItem(
                          value: control,
                          child: Text(control.label),
                        ),
                    ],
                    onChanged: (control) {
                      if (control != null) {
                        setState(() => _timeControl = control);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('white-name-field'),
                    controller: _whiteController,
                    textInputAction: TextInputAction.next,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'White player',
                      hintText: 'White',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_mode == GameMode.localTwoPlayer) ...[
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('black-name-field'),
                      controller: _blackController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _startGame(),
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Black player',
                        hintText: 'Black',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const ValueKey('start-game'),
                    onPressed: _startGame,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Start game'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
