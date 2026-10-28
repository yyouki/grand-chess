import 'dart:math';

import 'package:flutter/material.dart';

class ThreeDTowerScreen extends StatefulWidget {
  const ThreeDTowerScreen({super.key});

  @override
  State<ThreeDTowerScreen> createState() => _ThreeDTowerScreenState();
}

class _TowerBlock {
  const _TowerBlock({
    required this.width,
    required this.center,
    required this.color,
  });

  final double width;
  final double center;
  final Color color;
}

class _ThreeDTowerScreenState extends State<ThreeDTowerScreen> {
  static const double _baseWidth = 250;
  static const List<Color> _colors = [
    Color(0xFF66C5D8),
    Color(0xFF4C9ED9),
    Color(0xFF7C83DF),
    Color(0xFFB37CDD),
    Color(0xFFD8879F),
    Color(0xFFE3AD62),
    Color(0xFF8CCB8E),
  ];

  final Random _random = Random();
  late List<_TowerBlock> _blocks;
  bool _gameOver = false;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _blocks = [
      const _TowerBlock(
        width: _baseWidth,
        center: 0,
        color: Color(0xFF4F806F),
      ),
    ];
    _gameOver = false;
  }

  void _dropBlock() {
    if (_gameOver) return;
    final previous = _blocks.last;
    final shift = (_random.nextDouble() * 40) - 20;
    final overlap = previous.width - shift.abs();
    if (overlap < 46) {
      setState(() {
        _gameOver = true;
        _best = max(_best, _blocks.length - 1);
      });
      return;
    }

    setState(() {
      _blocks.add(
        _TowerBlock(
          width: overlap,
          center: previous.center + shift / 2,
          color: _colors[(_blocks.length - 1) % _colors.length],
        ),
      );
      _best = max(_best, _blocks.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = _blocks.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF101927),
      appBar: AppBar(
        title: const Text('Tower Builder 3D'),
        backgroundColor: const Color(0xFF101927),
        foregroundColor: const Color(0xFFF7F4EC),
        actions: [
          IconButton(
            key: const ValueKey('tower-reset'),
            tooltip: 'Restart tower',
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
          child: Column(
            children: [
              const SizedBox(height: 6),
              Text(
                _gameOver ? 'TOWER TOPPLED' : 'SCORE  $score',
                key: const ValueKey('tower-score'),
                style: TextStyle(
                  color: _gameOver
                      ? const Color(0xFFECA39B)
                      : const Color(0xFFE4C987),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              Text(
                'BEST  $_best',
                style: const TextStyle(
                  color: Color(0xFFC6D4E2),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const blockHeight = 30.0;
                      final visibleCount = min(
                        _blocks.length,
                        max(1, ((constraints.maxHeight - 35) / blockHeight).floor()),
                      );
                      final firstIndex = _blocks.length - visibleCount;
                      return SizedBox(
                        width: _baseWidth + 30,
                        height: visibleCount * blockHeight + 28,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            for (var index = firstIndex;
                                index < _blocks.length;
                                index++)
                              Positioned(
                                bottom: (index - firstIndex) * blockHeight,
                                child: _buildBlock(_blocks[index], index),
                              ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: _baseWidth + 24,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18283B),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x77000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: SizedBox(
                  width: 320,
                  child: FilledButton.icon(
                    key: const ValueKey('tower-drop-block'),
                    onPressed: _gameOver ? () => setState(_reset) : _dropBlock,
                    icon: Icon(_gameOver ? Icons.refresh : Icons.add_box),
                    label: Text(_gameOver ? 'Restart from the top' : 'Drop block'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE4B868),
                      foregroundColor: const Color(0xFF1C2835),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(_TowerBlock block, int index) {
    return Transform.translate(
      offset: Offset(block.center, 0),
      child: AnimatedContainer(
        key: ValueKey('tower-block-$index'),
        duration: const Duration(milliseconds: 180),
        width: block.width,
        height: 30,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(block.color, Colors.white, 0.28)!,
              block.color,
              Color.lerp(block.color, Colors.black, 0.22)!,
            ],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color(0x66FFFFFF),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 7,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
