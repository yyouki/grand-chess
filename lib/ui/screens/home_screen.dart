import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'local_game_setup_screen.dart';
import 'three_d_tic_tac_toe_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    '\u2656\u2658\u2657\u2655\u2654\u2657\u2658\u2656',
                    key: ValueKey('home-motif'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, color: AppTheme.seed),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Grand Chess',
                    key: ValueKey('home-title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Classic chess for two players on one device.',
                    key: ValueKey('home-tagline'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppTheme.mutedInk),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    key: const ValueKey('new-local-game'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const LocalGameSetupScreen(),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('New Local Game'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('open-3d-arcade'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const ThreeDTicTacToeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.view_in_ar),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Open 3D Arcade'),
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
