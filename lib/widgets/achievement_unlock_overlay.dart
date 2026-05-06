import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:warrior_path/config/achievements_config.dart';
import 'package:warrior_path/services/achievement_engine.dart';
import 'package:warrior_path/widgets/sprite_icon.dart';

// Spritesheet config (must match achievements_section.dart)
const _kSheetPath = 'assets/achievements/achievements_sheet.png';
const _kSheetCols = 3;
const _kSheetRows = 4;
const _kCropFraction = 0.92;
const _kCropDx = 0.0;
const _kCropDyPerRow = [0.1, -0.05, -0.2, -0.3];

/// Full-screen overlay that celebrates a list of newly-unlocked achievements
/// one by one. Parent removes it from the tree when [onDone] fires.
class AchievementUnlockSequence extends StatefulWidget {
  final List<AchievementStatus> achievements;
  final VoidCallback onDone;

  const AchievementUnlockSequence({
    super.key,
    required this.achievements,
    required this.onDone,
  });

  @override
  State<AchievementUnlockSequence> createState() =>
      _AchievementUnlockSequenceState();
}

class _AchievementUnlockSequenceState
    extends State<AchievementUnlockSequence>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late ConfettiController _confetti;
  int _index = 0;
  int _gen = 0; // cancels stale auto-advance timers

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    );
    _enterCurrent();
  }

  void _enterCurrent() {
    final myGen = ++_gen;
    _animCtrl.forward(from: 0);
    _confetti.play();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _gen == myGen) _advance();
    });
  }

  void _advance() {
    _gen++; // invalidate pending timers for the current card
    final isLast = _index >= widget.achievements.length - 1;
    _animCtrl.reverse().then((_) {
      if (!mounted) return;
      if (isLast) {
        widget.onDone();
      } else {
        setState(() => _index++);
        _enterCurrent();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.achievements[_index].def;
    final row = def.spriteIndex ~/ _kSheetCols;
    final dy = _kCropDyPerRow[row.clamp(0, _kCropDyPerRow.length - 1)];
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: _advance,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark overlay
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: Container(
                    color: Colors.black.withValues(alpha: 0.80)),
              ),
            ),

            // Confetti from top center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: pi / 2,
                numberOfParticles: 60,
                gravity: 0.3,
                emissionFrequency: 0.06,
                maxBlastForce: 22,
                minBlastForce: 8,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                  Color(0xFFFFFFFF),
                  Color(0xFFFF6B35),
                  Color(0xFF4ECDC4),
                  Color(0xFFE040FB),
                ],
              ),
            ),

            // Achievement card
            Center(
              child: ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fade,
                  child: _UnlockCard(def: def, dy: dy),
                ),
              ),
            ),

            // Bottom hints (dots + tap label)
            Positioned(
              bottom: bottomPad + 36,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    if (widget.achievements.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.achievements.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _index ? 18 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Toca para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final AchievementDef def;
  final double dy;

  const _UnlockCard({required this.def, required this.dy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.28),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 16),
              SizedBox(width: 6),
              Text(
                '¡LOGRO DESBLOQUEADO!',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Achievement icon with gold gradient frame
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7B5C0A),
                  Color(0xFFD4A843),
                  Color(0xFFF0D878),
                  Color(0xFFC8992C),
                  Color(0xFF8B6010),
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: SpriteIcon(
                assetPath: _kSheetPath,
                spriteIndex: def.spriteIndex,
                totalCols: _kSheetCols,
                totalRows: _kSheetRows,
                size: 84,
                cropFraction: _kCropFraction,
                cropOffsetDx: _kCropDx,
                cropOffsetDy: dy,
                fallback: Text(
                  def.emoji,
                  style: const TextStyle(fontSize: 52),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Title
          Text(
            def.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            def.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 13,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
