import 'package:flutter/material.dart';

import '../../game/chess_bot.dart';
import '../../game/chess_clock.dart';
import '../../game/game_mode.dart';
import '../theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('New game')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.paper,
            border: Border(top: BorderSide(color: AppTheme.line)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your settings stay on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.mutedInk, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('start-game'),
                    onPressed: _startGame,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Start game'),
                        SizedBox(width: 9),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SET UP YOUR GAME',
                    style: TextStyle(
                      color: AppTheme.seed,
                      fontSize: 10,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'How would you like\nto play?',
                    key: ValueKey('setup-title'),
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontFamily: 'serif',
                      fontSize: 36,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose your opponent, set the pace, then make your '
                    'first move.',
                    key: ValueKey('setup-hint'),
                    style: TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.line),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A3E2D20),
                          blurRadius: 22,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('PLAY MODE'),
                        const SizedBox(height: 9),
                        DropdownButtonFormField<GameMode>(
                          key: const ValueKey('game-mode-choice'),
                          initialValue: _mode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Opponent',
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
                          const SizedBox(height: 20),
                          _sectionLabel('BOT PERSONALITY'),
                          const SizedBox(height: 9),
                          DropdownButtonFormField<BotLevel>(
                            key: const ValueKey('bot-level-choice'),
                            initialValue: _botLevel,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Playing style',
                            ),
                            items: [
                              for (final level in BotLevel.values)
                                DropdownMenuItem(
                                  value: level,
                                  child: Text(level.label),
                                ),
                            ],
                            onChanged: (level) {
                              if (level != null) {
                                setState(() => _botLevel = level);
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        _sectionLabel('TIME CONTROL'),
                        const SizedBox(height: 9),
                        DropdownButtonFormField<ChessTimeControl>(
                          key: const ValueKey('time-control-choice'),
                          initialValue: _timeControl,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Clock'),
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
                        const SizedBox(height: 20),
                        _sectionLabel('PLAYERS'),
                        const SizedBox(height: 9),
                        TextField(
                          key: const ValueKey('white-name-field'),
                          controller: _whiteController,
                          textInputAction: TextInputAction.next,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            labelText: 'White player',
                            hintText: 'White',
                            counterText: '',
                          ),
                        ),
                        if (_mode == GameMode.localTwoPlayer) ...[
                          const SizedBox(height: 14),
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
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                      ],
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.mutedInk,
        fontSize: 10,
        letterSpacing: 1.3,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
