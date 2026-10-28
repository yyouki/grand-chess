import 'package:flutter/material.dart';

import 'three_d_tic_tac_toe_screen.dart';
import 'three_d_tower_screen.dart';

class ThreeDArcadeScreen extends StatelessWidget {
  const ThreeDArcadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101927),
      appBar: AppBar(
        title: const Text('Grand 3D Arcade'),
        backgroundColor: const Color(0xFF101927),
        foregroundColor: const Color(0xFFF7F4EC),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF101927),
              Color(0xFF263C50),
              Color(0xFF101927),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 2 : 1;
              return GridView(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: columns == 2 ? 1.45 : 1.9,
                ),
                children: [
                  _ArcadeCard(
                    key: const ValueKey('arcade-cube-tic-tac-toe'),
                    icon: Icons.grid_3x3,
                    title: 'Cube Tic-Tac-Toe',
                    subtitle:
                        'Play across three stacked layers. Connect three in any direction.',
                    accent: const Color(0xFF5BB8E9),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const ThreeDTicTacToeScreen(),
                      ),
                    ),
                  ),
                  _ArcadeCard(
                    key: const ValueKey('arcade-tower-builder'),
                    icon: Icons.view_in_ar,
                    title: 'Tower Builder 3D',
                    subtitle:
                        'Stack blocks, keep the tower balanced and beat your best score.',
                    accent: const Color(0xFFE4B868),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const ThreeDTowerScreen(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArcadeCard extends StatelessWidget {
  const _ArcadeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D2C3C),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.55)),
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF7F4EC),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFC6D4E2),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'PLAY NOW',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: accent, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
