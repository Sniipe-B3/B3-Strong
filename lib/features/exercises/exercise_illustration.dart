import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../domain/exercise_content.dart';

/// Small local vector sketches. Text instructions remain the source of truth.
class ExerciseIllustration extends StatelessWidget {
  const ExerciseIllustration({
    super.key,
    required this.guide,
    this.width = 160,
  });

  final ExerciseGuide guide;
  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: guide.illustrationLabel,
    child: Container(
      width: width,
      height: width * 0.625,
      decoration: BoxDecoration(
        color: AppColors.raised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        key: ValueKey('illustration-${guide.id}'),
        painter: _MovementPainter(guide.id),
      ),
    ),
  );
}

class _MovementPainter extends CustomPainter {
  const _MovementPainter(this.id);

  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 100);
    final body = Paint()
      ..color = AppColors.text
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final accent = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final muted = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void line(double x1, double y1, double x2, double y2, Paint paint) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    void head(double x, double y) => canvas.drawCircle(Offset(x, y), 8, accent);
    void arrow(double x1, double y1, double x2, double y2) {
      line(x1, y1, x2, y2, accent);
      final a = math.atan2(y2 - y1, x2 - x1);
      for (final side in [-1, 1]) {
        line(
          x2,
          y2,
          x2 - 7 * math.cos(a + side * 0.65),
          y2 - 7 * math.sin(a + side * 0.65),
          accent,
        );
      }
    }

    void floor() => line(12, 85, 148, 85, muted);

    switch (id) {
      case 'plank':
        floor();
        head(118, 42);
        line(106, 49, 32, 62, body);
        line(32, 62, 19, 82, body);
        line(105, 51, 92, 73, body);
        line(92, 73, 116, 73, body);
        arrow(70, 29, 92, 29);
      case 'squat':
        floor();
        head(79, 22);
        line(79, 31, 76, 53, body);
        line(76, 53, 61, 67, body);
        line(61, 67, 60, 83, body);
        line(76, 53, 92, 67, body);
        line(92, 67, 92, 83, body);
        line(77, 37, 53, 46, body);
        line(77, 37, 102, 46, body);
        arrow(127, 42, 127, 64);
      case 'step_jack':
        floor();
        head(77, 22);
        line(77, 31, 77, 63, body);
        line(77, 63, 65, 83, body);
        line(77, 63, 116, 83, accent);
        line(77, 37, 53, 22, body);
        line(77, 37, 106, 16, accent);
        arrow(98, 56, 122, 56);
      case 'wall_pushup':
        floor();
        line(130, 10, 130, 85, muted);
        head(94, 30);
        line(88, 38, 65, 59, body);
        line(65, 59, 47, 83, body);
        line(90, 43, 114, 48, body);
        line(114, 48, 129, 43, accent);
        arrow(51, 29, 71, 29);
      case 'glute_bridge':
        floor();
        head(29, 69);
        line(39, 71, 58, 70, body);
        line(58, 70, 89, 49, accent);
        line(89, 49, 113, 59, body);
        line(113, 59, 116, 83, body);
        line(53, 74, 85, 74, muted);
        arrow(91, 70, 91, 51);
      case 'calf_raise':
        floor();
        head(70, 19);
        line(70, 28, 70, 56, body);
        line(70, 56, 62, 76, body);
        line(62, 76, 67, 83, accent);
        line(70, 56, 82, 76, body);
        line(82, 76, 88, 83, accent);
        line(70, 35, 100, 43, body);
        line(100, 43, 112, 43, body);
        line(115, 40, 115, 83, muted);
        arrow(39, 73, 39, 53);
      case 'shoulder_circle':
        head(80, 26);
        line(80, 35, 80, 70, body);
        line(80, 43, 55, 49, body);
        line(55, 49, 50, 67, body);
        line(80, 43, 105, 49, body);
        line(105, 49, 110, 67, body);
        canvas.drawArc(
          const Rect.fromLTWH(44, 31, 28, 24),
          0.4,
          4.5,
          false,
          accent,
        );
        canvas.drawArc(
          const Rect.fromLTWH(88, 31, 28, 24),
          2.6,
          4.5,
          false,
          accent,
        );
      case 'neck_rotation':
        head(80, 27);
        line(80, 36, 80, 68, body);
        line(80, 43, 55, 52, body);
        line(80, 43, 105, 52, body);
        arrow(55, 18, 67, 13);
        arrow(105, 18, 93, 13);
      case 'calf_stretch':
        floor();
        line(130, 8, 130, 85, muted);
        head(90, 21);
        line(89, 30, 79, 55, body);
        line(79, 55, 110, 73, body);
        line(110, 73, 107, 84, body);
        line(79, 55, 40, 81, accent);
        line(40, 81, 22, 82, accent);
        line(88, 36, 127, 35, body);
        arrow(42, 66, 30, 66);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MovementPainter oldDelegate) =>
      oldDelegate.id != id;
}
