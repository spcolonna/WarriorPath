import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../config/power_config.dart';

/// Mini-avatar cabezón nativo (sin WebView), pensado para listas de ranking.
///
/// Comparte el lenguaje visual del hero HTML/CSS ([warrior_avatar_view.dart])
/// —cabezón, vincha con el color de la escuela, anillo de tier— pero se pinta
/// con [CustomPaint] para ser barato de renderizar en muchas filas.
class MiniAvatar extends StatelessWidget {
  final AvatarGender gender;
  final int power;
  final Color schoolColor;
  final double size;

  const MiniAvatar({
    super.key,
    required this.gender,
    required this.power,
    required this.schoolColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final tier = tierForPower(power);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniAvatarPainter(
          gender: gender,
          schoolColor: schoolColor,
          tierColor: tier.metal,
          tierIndex: tier.index,
        ),
      ),
    );
  }
}

class _MiniAvatarPainter extends CustomPainter {
  final AvatarGender gender;
  final Color schoolColor;
  final Color tierColor;
  final int tierIndex;

  _MiniAvatarPainter({
    required this.gender,
    required this.schoolColor,
    required this.tierColor,
    required this.tierIndex,
  });

  static const _skin = Color(0xFFFFD9B0);
  static const _skinShadow = Color(0xFFF0B98A);
  static const _hair = Color(0xFF3A2C25);
  static const _eye = Color(0xFF2A2230);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    final r = s * 0.34;

    // ── anillo de tier (glow suave en tier alto) ──
    if (tierIndex >= 1) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..color = tierColor;
      if (tierIndex >= 3) {
        ringPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      }
      canvas.drawCircle(c, r + s * 0.10, ringPaint);
    }

    // ── cuerpo / kimono asomando abajo ──
    final bodyRect = Rect.fromLTWH(
      c.dx - r * 0.95,
      c.dy + r * 0.55,
      r * 1.9,
      r * 1.4,
    );
    final giPaint = Paint()..color = const Color(0xFFF4F1EA);
    canvas.drawRRect(
      RRect.fromRectAndCorners(bodyRect,
          topLeft: Radius.circular(r * 0.6), topRight: Radius.circular(r * 0.6)),
      giPaint,
    );
    // cuello del kimono con color de escuela
    final collar = Path()
      ..moveTo(c.dx, c.dy + r * 0.55)
      ..lineTo(c.dx - r * 0.28, c.dy + r * 0.55)
      ..lineTo(c.dx, c.dy + r * 1.05)
      ..lineTo(c.dx + r * 0.28, c.dy + r * 0.55)
      ..close();
    canvas.drawPath(collar, Paint()..color = schoolColor);

    // ── pelo (según género), dibujado detrás de la cabeza ──
    _paintHair(canvas, c, r);

    // ── cabeza ──
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.0,
        colors: const [_skin, _skinShadow],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, headPaint);

    // ── vincha (headband) con color de escuela ──
    final bandRect = Rect.fromLTWH(
      c.dx - r,
      c.dy - r * 0.28,
      r * 2,
      r * 0.34,
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawRect(bandRect, Paint()..color = schoolColor);
    canvas.restore();

    // ── ojos ──
    final eyePaint = Paint()..color = _eye;
    final glintPaint = Paint()..color = Colors.white;
    final eyeDx = r * 0.42;
    final eyeDy = r * 0.12;
    final eyeR = r * 0.16;
    for (final sign in [-1.0, 1.0]) {
      final ec = Offset(c.dx + sign * eyeDx, c.dy + eyeDy);
      canvas.drawOval(
        Rect.fromCenter(center: ec, width: eyeR * 1.5, height: eyeR * 2),
        eyePaint,
      );
      canvas.drawCircle(
        ec.translate(-eyeR * 0.3, -eyeR * 0.5), eyeR * 0.42, glintPaint);
    }

    // ── cachetes ──
    final blushPaint = Paint()..color = const Color(0xFFFF9A9A).withValues(alpha: 0.5);
    for (final sign in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx + sign * r * 0.62, c.dy + r * 0.42),
          width: r * 0.34,
          height: r * 0.2,
        ),
        blushPaint,
      );
    }

    // ── boca (sonrisa determinada) ──
    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF7A3B3B);
    final mouth = Path();
    mouth.moveTo(c.dx - r * 0.2, c.dy + r * 0.5);
    mouth.quadraticBezierTo(
        c.dx, c.dy + r * 0.72, c.dx + r * 0.2, c.dy + r * 0.5);
    canvas.drawPath(mouth, mouthPaint);
  }

  void _paintHair(Canvas canvas, Offset c, double r) {
    final hairPaint = Paint()..color = _hair;
    switch (gender) {
      case AvatarGender.male:
        // casquete corto con leve pico
        final p = Path()
          ..addArc(
            Rect.fromCircle(center: c, radius: r * 1.02),
            math.pi * 1.05,
            math.pi * 0.9,
          );
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - r, c.dy - r * 0.15)
            ..arcToPoint(Offset(c.dx + r, c.dy - r * 0.15),
                radius: Radius.circular(r * 1.05), clockwise: true)
            ..lineTo(c.dx + r * 0.6, c.dy - r * 0.55)
            ..lineTo(c.dx + r * 0.2, c.dy - r * 0.2)
            ..lineTo(c.dx - r * 0.2, c.dy - r * 0.6)
            ..lineTo(c.dx - r * 0.6, c.dy - r * 0.2)
            ..close(),
          hairPaint,
        );
        canvas.drawPath(p, hairPaint);
        break;
      case AvatarGender.female:
        // melena a los costados + rodete arriba
        canvas.drawCircle(Offset(c.dx - r * 0.8, c.dy), r * 0.55, hairPaint);
        canvas.drawCircle(Offset(c.dx + r * 0.8, c.dy), r * 0.55, hairPaint);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 1.02),
          math.pi,
          math.pi,
          true,
          hairPaint,
        );
        canvas.drawCircle(Offset(c.dx, c.dy - r * 1.1), r * 0.4, hairPaint);
        break;
      case AvatarGender.neutral:
        // casquete redondeado + mechón
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 1.03),
          math.pi * 1.02,
          math.pi * 0.96,
          true,
          hairPaint,
        );
        canvas.drawCircle(Offset(c.dx, c.dy - r * 1.0), r * 0.18, hairPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniAvatarPainter old) =>
      old.gender != gender ||
      old.schoolColor != schoolColor ||
      old.tierColor != tierColor ||
      old.tierIndex != tierIndex;
}
