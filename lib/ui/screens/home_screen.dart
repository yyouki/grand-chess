import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'local_game_setup_screen.dart';
import 'three_d_arcade_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openLocalGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LocalGameSetupScreen(),
      ),
    );
  }

  void _openArcade(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ThreeDArcadeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            final compact = constraints.maxWidth < 420;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 32 : 22,
                vertical: wide ? 28 : 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  // A single editorial column keeps the primary actions easy to find.
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBrandBar(compact: compact),
                      SizedBox(height: wide ? 48 : 24),
                      _buildIntro(wide: wide),
                      const SizedBox(height: 18),
                      _buildActions(context),
                      const SizedBox(height: 18),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 4),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Text(
                            'Grand Chess brings the familiar game into a '
                            'thoughtful 3D space. Play side by side, or take '
                            'on the offline bot.',
                            key: const ValueKey('home-tagline'),
                            textAlign: wide ? TextAlign.left : TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.mutedInk,
                              fontSize: 14,
                              height: 1.65,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _BoardPreviewCard(),
                      const SizedBox(height: 24),
                      _buildFooter(wide, compact: compact),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandBar({required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve enough width for the brand and status chip on small screens.
        final small = compact || constraints.maxWidth < 420;
        return Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.accentWash,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.casino_outlined,
                color: AppTheme.seed,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GRAND CHESS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!small) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'A small space for strategy',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.mutedInk, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: small ? 8 : 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.line),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 7, color: AppTheme.sage),
                  SizedBox(width: small ? 5 : 7),
                  Text(
                    small ? 'OFFLINE' : 'OFFLINE PLAY',
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntro({required bool wide}) {
    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          'YOUR NEXT MOVE STARTS HERE',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: AppTheme.seed,
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A quieter way\nto play.',
          key: const ValueKey('home-title'),
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: AppTheme.ink,
            fontFamily: 'serif',
            fontSize: wide ? 58 : 44,
            height: 1.0,
            fontWeight: FontWeight.w500,
            letterSpacing: wide ? -2.0 : -1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const ValueKey('new-local-game'),
              onPressed: () => _openLocalGame(context),
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
              label: const Text('Start a game'),
              style: FilledButton.styleFrom(
                alignment: Alignment.center,
                minimumSize: const Size(0, 56),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('open-3d-arcade'),
              onPressed: () => _openArcade(context),
              icon: const Icon(Icons.view_in_ar, size: 19),
              label: const Text('Explore 3D arcade'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
            ),
            const SizedBox(height: 10),
            const Text(
              'No account. No matchmaking. Just the board.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedInk, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool wide, {required bool compact}) {
    if (compact) {
      return const Center(
        child: Text(
          'MADE FOR THE LOVE OF THE GAME',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.mutedInk,
            fontSize: 8,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: wide
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        const Icon(Icons.circle, size: 5, color: AppTheme.line),
        const SizedBox(width: 8),
        const Text(
          'MADE FOR THE LOVE OF THE GAME',
          style: TextStyle(
            color: AppTheme.mutedInk,
            fontSize: 9,
            letterSpacing: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BoardPreviewCard extends StatelessWidget {
  const _BoardPreviewCard();

  static const String _blackBackRank = '♜♞♝♛♚♝♞♜';
  static const String _whiteBackRank = '♖♘♗♕♔♗♘♖';

  String? _pieceAt(int file, int rank) {
    if (rank == 0) return _blackBackRank[file];
    if (rank == 1) return '♟';
    if (rank == 6) return '♙';
    if (rank == 7) return _whiteBackRank[file];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D3E2D20),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 300;
              return Row(
                children: [
                  const Text(
                    'THE BOARD',
                    style: TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 10,
                      letterSpacing: 1.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.blur_on_rounded,
                    size: 14,
                    color: AppTheme.sage,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    compact ? '3D VIEW' : 'PERSPECTIVE VIEW',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.sage,
                      fontSize: 9,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final file = index % 8;
                  final rank = index ~/ 8;
                  final piece = _pieceAt(file, rank);
                  final isDark = (file + rank).isOdd;
                  final isWhitePiece = rank >= 6;
                  return ColoredBox(
                    color: isDark ? AppTheme.boardDark : AppTheme.boardLight,
                    child: Center(
                      child: piece == null
                          ? const SizedBox.shrink()
                          : Text(
                              piece,
                              style: TextStyle(
                                color: isWhitePiece
                                    ? const Color(0xFFFFF8E9)
                                    : const Color(0xFF322820),
                                fontSize: 20,
                                height: 1,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x33000000),
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WALNUT EDITION',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A familiar game, seen differently.',
                      style: TextStyle(color: AppTheme.mutedInk, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.north_east_rounded, color: AppTheme.seed, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
