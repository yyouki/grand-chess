import 'package:flutter/material.dart';

/// A small local 3D-style arcade prototype. This standalone game is a real,
/// playable 3 x 3 x 3 tic-tac-toe board, not just a promotional placeholder.
class ThreeDTicTacToeScreen extends StatefulWidget {
  const ThreeDTicTacToeScreen({super.key});

  @override
  State<ThreeDTicTacToeScreen> createState() => _ThreeDTicTacToeScreenState();
}

class _ThreeDTicTacToeScreenState extends State<ThreeDTicTacToeScreen> {
  static const int _cellCount = 27;
  late List<String?> _cells;
  String _turn = 'X';
  String? _winner;

  static final List<List<int>> _winningLines = _buildWinningLines();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  static List<List<int>> _buildWinningLines() {
    final lines = <List<int>>[];
    bool onBoard(int n) => n >= 0 && n < 3;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (var dz = -1; dz <= 1; dz++) {
          if (dx == 0 && dy == 0 && dz == 0) continue;
          if (dx < 0 || (dx == 0 && dy < 0) || (dx == 0 && dy == 0 && dz < 0)) {
            continue;
          }
          for (var z = 0; z < 3; z++) {
            for (var y = 0; y < 3; y++) {
              for (var x = 0; x < 3; x++) {
                final ex = x + 2 * dx;
                final ey = y + 2 * dy;
                final ez = z + 2 * dz;
                if (!onBoard(ex) || !onBoard(ey) || !onBoard(ez)) continue;
                final line = <int>[
                  _index(x, y, z),
                  _index(x + dx, y + dy, z + dz),
                  _index(ex, ey, ez),
                ];
                lines.add(line);
              }
            }
          }
        }
      }
    }
    return lines;
  }

  static int _index(int x, int y, int z) => z * 9 + y * 3 + x;

  void _reset() {
    _cells = List<String?>.filled(_cellCount, null);
    _turn = 'X';
    _winner = null;
  }

  void _play(int index) {
    if (_winner != null || _cells[index] != null) return;
    setState(() {
      _cells[index] = _turn;
      if (_winningLines.any(
        (line) => line.every((cell) => _cells[cell] == _turn),
      )) {
        _winner = _turn;
      } else if (_cells.every((cell) => cell != null)) {
        _winner = 'DRAW';
      } else {
        _turn = _turn == 'X' ? 'O' : 'X';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (_winner) {
      'X' => 'X wins the 3D board!',
      'O' => 'O wins the 3D board!',
      'DRAW' => 'Draw — play again?',
      _ => 'Player $_turn to move',
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Arcade · Cube Tic-Tac-Toe'),
        actions: [
          IconButton(
            tooltip: 'New game',
            onPressed: () => setState(_reset),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF101927), Color(0xFF263C50), Color(0xFF101927)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      status,
                      key: const ValueKey('cube-game-status'),
                      style: const TextStyle(
                        color: Color(0xFFF7F4EC),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Three stacked layers · 27 cells · connect three in any direction',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFC6D4E2)),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: compact
                          ? ListView(
                              children: [
                                for (var z = 2; z >= 0; z--) _buildLayer(z),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                for (var z = 2; z >= 0; z--)
                                  Flexible(child: _buildLayer(z)),
                              ],
                            ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(_reset),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Restart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF7F4EC),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLayer(int z) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LAYER ${z + 1}',
              style: const TextStyle(
                color: Color(0xFFD9C18A),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemBuilder: (context, cell) {
                  final index = _index(cell % 3, cell ~/ 3, z);
                  final value = _cells[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: value == 'X'
                            ? const [Color(0xFF5AB6E8), Color(0xFF2374B5)]
                            : value == 'O'
                            ? const [Color(0xFFE7BA68), Color(0xFF9F6729)]
                            : const [Color(0xFF3A526B), Color(0xFF202F42)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: const Color(0x667D9CB8),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          offset: Offset(0, 4),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('cube-cell-$index'),
                        onTap: () => _play(index),
                        borderRadius: BorderRadius.circular(9),
                        child: Center(
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 180),
                            scale: value == null ? 0.7 : 1,
                            child: Text(
                              value ?? '',
                              style: TextStyle(
                                color: value == 'X'
                                    ? const Color(0xFFF3FBFF)
                                    : const Color(0xFFFFF3D8),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x99000000),
                                    offset: Offset(1, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
