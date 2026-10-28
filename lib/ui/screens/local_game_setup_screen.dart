import 'package:flutter/material.dart';

import 'game_screen.dart';

class LocalGameSetupScreen extends StatefulWidget {
  const LocalGameSetupScreen({super.key});

  @override
  State<LocalGameSetupScreen> createState() => _LocalGameSetupScreenState();
}

class _LocalGameSetupScreenState extends State<LocalGameSetupScreen> {
  final TextEditingController _whiteController = TextEditingController();
  final TextEditingController _blackController = TextEditingController();

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
    final blackName = _nameOrDefault(_blackController, 'Black');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            GameScreen(whiteName: whiteName, blackName: blackName),
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
