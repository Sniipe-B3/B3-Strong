import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../domain/exercise_content.dart';

/// A small, self-contained movement preview; the written instructions take priority.
class ExerciseMotionDemo extends StatefulWidget {
  const ExerciseMotionDemo({super.key, required this.guide});

  final ExerciseGuide guide;

  @override
  State<ExerciseMotionDemo> createState() => _ExerciseMotionDemoState();
}

class _ExerciseMotionDemoState extends State<ExerciseMotionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  bool _paused = false;
  bool? _reducedMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reduced) return;
    _reducedMotion = reduced;
    if (reduced) {
      _controller.stop();
      _controller.value = 0.75;
    } else if (!_paused) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reducedMotion ?? false;
    return Column(
      children: [
        Semantics(
          image: true,
          label:
              '${widget.guide.illustrationLabel} '
              '${reduced ? 'Image fixe, animations réduites.' : 'Démonstration animée simplifiée.'}',
          child: AspectRatio(
            aspectRatio: 1.6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.raised,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  key: ValueKey('motion-${widget.guide.id}'),
                  painter: ExerciseMotionPainter(
                    widget.guide.id,
                    Curves.easeInOut.transform(_controller.value),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (reduced)
          const Text(
            'Animation désactivée par les réglages de votre appareil.',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          )
        else
          TextButton.icon(
            onPressed: _togglePlayback,
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(_paused ? 'Reprendre l’animation' : 'Mettre en pause'),
          ),
        const Text(
          'Démonstration schématique : lisez les consignes ci-dessous.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Draws two coordinated exercise poses and every position between them.
class ExerciseMotionPainter extends CustomPainter {
  const ExerciseMotionPainter(this.id, this.progress);

  final String id;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 100);
    final t = progress.clamp(0.0, 1.0);
    final body = Paint()
      ..color = AppColors.text
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final limb = Paint()
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
    final guide = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset p(double x, double y) => Offset(x, y);
    Offset mix(Offset a, Offset b) => Offset.lerp(a, b, t)!;
    void line(Offset a, Offset b, Paint paint) => canvas.drawLine(a, b, paint);
    void chain(List<Offset> points, Paint paint) {
      for (var i = 1; i < points.length; i++) {
        line(points[i - 1], points[i], paint);
      }
    }

    void head(Offset center) {
      canvas.drawCircle(center, 8, accent);
      canvas.drawCircle(center, 2.3, Paint()..color = AppColors.accent);
    }

    void joint(Offset center) =>
        canvas.drawCircle(center, 2.8, Paint()..color = AppColors.accent);

    void floor() => line(p(12, 87), p(148, 87), guide);
    void wall() => line(p(133, 8), p(133, 87), guide);

    switch (id) {
      case 'plank':
        floor();
        final shoulder = mix(p(104, 57), p(104, 47));
        final hip = mix(p(65, 75), p(64, 52));
        head(shoulder + p(13, -10));
        chain([shoulder, hip, p(27, 77), p(17, 84)], body);
        chain([shoulder, p(93, 75), p(116, 75)], limb);
        joint(hip);
      case 'squat':
        floor();
        final shoulder = mix(p(80, 37), p(83, 44));
        final hip = mix(p(80, 59), p(72, 68));
        final leftKnee = mix(p(66, 73), p(56, 73));
        final rightKnee = mix(p(94, 73), p(103, 72));
        head(shoulder + p(0, -14));
        chain([shoulder, hip], body);
        chain([hip, leftKnee, p(60, 85)], limb);
        chain([hip, rightKnee, p(99, 85)], limb);
        chain([shoulder + p(-2, 4), p(61, 50), p(48, 47)], limb);
        chain([shoulder + p(2, 4), p(104, 50), p(115, 47)], limb);
        joint(hip);
      case 'step_jack':
        floor();
        head(p(79, 22));
        chain([p(79, 32), p(79, 62)], body);
        chain([p(79, 62), p(69, 84)], limb);
        chain([p(79, 62), mix(p(90, 84), p(120, 84))], accent);
        chain([p(78, 39), p(59, 52), p(54, 61)], limb);
        chain([
          p(80, 39),
          mix(p(100, 52), p(105, 31)),
          mix(p(111, 62), p(119, 18)),
        ], accent);
        joint(p(79, 62));
      case 'wall_pushup':
        floor();
        wall();
        final shoulder = mix(p(87, 39), p(104, 42));
        final hip = mix(p(66, 59), p(75, 60));
        head(shoulder + p(2, -13));
        chain([shoulder, hip, p(48, 84)], body);
        chain([shoulder, mix(p(109, 49), p(116, 55)), p(132, 43)], accent);
        chain([hip, p(58, 84)], limb);
        joint(shoulder);
      case 'glute_bridge':
        floor();
        head(p(29, 75));
        final hip = mix(p(82, 76), p(85, 53));
        chain([p(39, 78), p(54, 77), hip], body);
        chain([hip, p(112, 68), p(116, 85)], limb);
        chain([p(50, 78), p(66, 83)], limb);
        joint(hip);
      case 'calf_raise':
        floor();
        final lift = 8 * t;
        head(p(69, 22 - lift));
        chain([p(69, 32 - lift), p(70, 60 - lift)], body);
        chain([p(70, 60 - lift), p(62, 75 - lift), p(65, 84)], limb);
        chain([p(70, 60 - lift), p(83, 75 - lift), p(88, 84)], limb);
        chain([p(69, 38 - lift), p(99, 46 - lift), p(114, 46)], accent);
        line(p(116, 46), p(116, 86), guide);
        joint(p(70, 60 - lift));
      case 'shoulder_circle':
        final theta = t * 2 * math.pi;
        final rise = math.cos(theta) * 4;
        final spread = math.sin(theta) * 3;
        head(p(80, 25));
        chain([p(80, 35), p(80, 70)], body);
        chain([
          p(80, 42),
          p(56 - spread, 47 - rise),
          p(52 - spread, 68 - rise),
        ], limb);
        chain([
          p(80, 42),
          p(104 + spread, 47 - rise),
          p(108 + spread, 68 - rise),
        ], limb);
        canvas.drawArc(
          const Rect.fromLTWH(44, 33, 28, 23),
          0,
          4.8,
          false,
          accent,
        );
        canvas.drawArc(
          const Rect.fromLTWH(88, 33, 28, 23),
          0,
          4.8,
          false,
          accent,
        );
      case 'neck_rotation':
        final turn = math.sin((t - 0.5) * math.pi) * 5;
        final face = p(80 + turn, 25);
        head(face);
        canvas.drawCircle(face + p(turn * 0.45, 0), 2, accent);
        chain([p(80, 35), p(80, 68)], body);
        chain([p(80, 43), p(55, 53)], limb);
        chain([p(80, 43), p(105, 53)], limb);
        canvas.drawArc(
          const Rect.fromLTWH(60, 10, 40, 24),
          3.5,
          2.5,
          false,
          guide,
        );
      case 'calf_stretch':
        floor();
        wall();
        final shoulder = mix(p(86, 39), p(92, 39));
        final hip = mix(p(76, 59), p(83, 59));
        head(shoulder + p(1, -13));
        chain([shoulder, hip], body);
        chain([hip, p(108, 74), p(107, 85)], limb);
        chain([hip, p(44, 83), p(25, 84)], accent);
        chain([shoulder, p(111, 43), p(132, 43)], limb);
        joint(hip);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ExerciseMotionPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.progress != progress;
}
