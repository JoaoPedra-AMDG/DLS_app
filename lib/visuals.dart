import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

/// All illustrations are drawn locally: no tracking, external imagery or fonts.
class StudyArt extends StatelessWidget {
  const StudyArt({super.key, this.color = purple});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HeroPainter(color), size: const Size(310, 210));
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 310, s.height / 210);
    final p = Paint()..color = color.withValues(alpha: .08);
    c.drawCircle(const Offset(162, 103), 87, p);
    p
      ..color = color.withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    c.save();
    c.translate(163, 106);
    c.rotate(-.35);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 268, height: 114),
      p,
    );
    c.restore();
    c.save();
    c.translate(152, 114);
    c.rotate(-.12);
    final left =
        Path()
          ..moveTo(-68, -43)
          ..quadraticBezierTo(-30, -60, 0, -35)
          ..lineTo(0, 64)
          ..quadraticBezierTo(-32, 40, -68, 50)
          ..close();
    final right =
        Path()
          ..moveTo(0, -35)
          ..quadraticBezierTo(32, -57, 70, -43)
          ..lineTo(70, 50)
          ..quadraticBezierTo(32, 39, 0, 64)
          ..close();
    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFAF8FF);
    c.drawPath(left, p);
    c.drawPath(right, p);
    p
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 3;
    c.drawPath(left, p);
    c.drawPath(right, p);
    p
      ..color = color.withValues(alpha: .3)
      ..strokeWidth = 2;
    for (int i = 0; i < 4; i++) {
      c.drawLine(Offset(-54, -20 + i * 15.0), Offset(-13, -13 + i * 15.0), p);
      c.drawLine(Offset(14, -13 + i * 15.0), Offset(56, -20 + i * 15.0), p);
    }
    c.restore();
    _badge(c, const Offset(70, 46), const Color(0xFFFFD782), 'π', -.18);
    _badge(c, const Offset(247, 122), const Color(0xFFABDCC9), '✓', .15);
    _badge(c, const Offset(201, 25), const Color(0xFFC5BAF5), 'x²', .15);
    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFEFACC1);
    c.drawCircle(const Offset(268, 53), 5, p);
    c.drawCircle(const Offset(67, 169), 4, p);
    p
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 2;
    c.drawLine(const Offset(260, 173), const Offset(260, 187), p);
    c.drawLine(const Offset(253, 180), const Offset(267, 180), p);
    c.restore();
  }

  void _badge(Canvas c, Offset at, Color col, String text, double angle) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-23, -23, 46, 46),
        const Radius.circular(13),
      ),
      Paint()..color = col,
    );
    final t = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, Offset(-t.width / 2, -t.height / 2));
    c.restore();
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.color != color;
}

class LearningVisual extends StatefulWidget {
  const LearningVisual({
    super.key,
    required this.type,
    required this.color,
    required this.formula,
  });
  final String type, formula;
  final Color color;
  @override
  State<LearningVisual> createState() => _LearningVisualState();
}

class _LearningVisualState extends State<LearningVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool playing = true;
  double parameter = 1;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
      playing = false;
    } else if (playing) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adjustable = [
      'wave',
      'parabola',
      'growth',
      'arousal',
    ].contains(widget.type);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: widget.color, size: 19),
              const SizedBox(width: 8),
              const Text(
                'See the idea',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: playing ? 'Pause animation' : 'Play animation',
                onPressed: () {
                  setState(() {
                    playing = !playing;
                    playing ? controller.repeat() : controller.stop();
                  });
                },
                icon: Icon(
                  playing
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: widget.color,
                ),
              ),
            ],
          ),
          Semantics(
            label: 'Illustration of ${widget.type}. ${widget.formula}',
            child: AnimatedBuilder(
              animation: controller,
              builder:
                  (_, __) => SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: DiagramPainter(
                        widget.type,
                        widget.color,
                        controller.value,
                        parameter,
                      ),
                    ),
                  ),
            ),
          ),
          if (adjustable)
            Row(
              children: [
                Text(
                  widget.type == 'wave'
                      ? 'Amplitude'
                      : widget.type == 'parabola'
                      ? 'Curve scale'
                      : widget.type == 'growth'
                      ? 'Growth rate'
                      : 'Peak position',
                  style: const TextStyle(fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: parameter,
                    min: .5,
                    max: 1.5,
                    activeColor: widget.color,
                    onChanged: (v) => setState(() => parameter = v),
                  ),
                ),
              ],
            ),
          Text(
            widget.formula,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: widget.color,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Concept sketch · not to scale',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class DiagramPainter extends CustomPainter {
  DiagramPainter(this.type, this.color, this.time, this.parameter);
  final String type;
  final Color color;
  final double time, parameter;
  void label(Canvas c, String t, Offset o, {Color? col, double size = 12}) {
    final text = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: col ?? ink,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 140);
    text.paint(c, o - Offset(text.width / 2, text.height / 2));
  }

  void arrow(Canvas c, Offset a, Offset b, Paint p) {
    c.drawLine(a, b, p);
    final d = (b - a).direction;
    for (final delta in [-.5, .5]) {
      c.drawLine(
        b,
        b - Offset(math.cos(d + delta) * 8, math.sin(d + delta) * 8),
        p,
      );
    }
  }

  @override
  void paint(Canvas c, Size s) {
    // Fixed logical bounds keep labels legible and never let drawings escape.
    final w = math.min(s.width, 520.0);
    c.save();
    c.translate((s.width - w) / 2, 0);
    c.scale(w / 520, s.height / 190);
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
    const center = Offset(260, 95);
    final phase = time * 2 * math.pi;
    if (type == 'complex') {
      arrow(c, const Offset(120, 145), const Offset(425, 145), p);
      arrow(c, const Offset(160, 170), const Offset(160, 15), p);
      label(c, 'Real', const Offset(445, 145));
      label(c, 'Imaginary', const Offset(160, 10), size: 10);
      arrow(c, const Offset(160, 145), const Offset(320, 50), p);
      c.drawCircle(const Offset(320, 50), 5, Paint()..color = color);
      label(c, 'a + bi', const Offset(358, 45));
      label(c, '|z|', const Offset(238, 80));
      label(
        c,
        'distance and angle describe a complex number',
        const Offset(260, 182),
        size: 10,
      );
    } else if (type == 'distribution') {
      final curve = Path();
      for (int i = 0; i <= 360; i++) {
        final x = (i - 180) / 65;
        final y = 155 - 115 * math.exp(-x * x / 2);
        if (i == 0) {
          curve.moveTo(80 + i.toDouble(), y);
        } else {
          curve.lineTo(80 + i.toDouble(), y);
        }
      }
      c.drawLine(const Offset(65, 155), const Offset(455, 155), p);
      c.drawPath(curve, p);
      for (int i = -2; i <= 2; i++) {
        final x = 260 + i * 65.0;
        c.drawLine(Offset(x, 150), Offset(x, 160), p);
        label(
          c,
          i == 0
              ? 'μ'
              : i < 0
              ? 'μ − ${-i}σ'
              : 'μ + $iσ',
          Offset(x, 178),
          size: 10,
        );
      }
      label(c, 'Normal-distribution model', const Offset(260, 14), size: 11);
    } else if ([
      'wave',
      'parabola',
      'growth',
      'arousal',
      'motion',
    ].contains(type)) {
      p
        ..color = color.withValues(alpha: .25)
        ..strokeWidth = 1;
      for (int x = 50; x <= 480; x += 43) {
        c.drawLine(Offset(x.toDouble(), 15), Offset(x.toDouble(), 160), p);
      }
      arrow(c, const Offset(45, 155), const Offset(490, 155), p);
      arrow(c, const Offset(45, 155), const Offset(45, 10), p);
      label(c, type == 'motion' ? 'time' : 'x', const Offset(490, 175));
      label(c, type == 'motion' ? 'velocity' : 'y', const Offset(27, 15));
      final path = Path();
      for (int i = 0; i <= 420; i++) {
        final x = i / 420;
        final y = switch (type) {
          'wave' => 90 - 40 * parameter * math.sin(x * 4 * math.pi - phase),
          'parabola' => 145 - 480 * parameter * math.pow(x - .5, 2),
          'growth' =>
            150 - 110 * (math.exp(x * parameter) - 1) / (math.exp(1.5) - 1),
          'arousal' =>
            145 - 100 * math.exp(-math.pow((x - parameter / 2) * 4, 2)),
          _ => 150 - 110 * x,
        };
        if (i == 0) {
          path.moveTo(50 + i.toDouble(), y);
        } else {
          path.lineTo(50 + i.toDouble(), y);
        }
      }
      p
        ..color = color
        ..strokeWidth = 3;
      c.drawPath(path, p);
      label(c, switch (type) {
        'wave' => 'displacement vs position',
        'parabola' => 'y = a(x − h)² + k',
        'growth' => 'compound growth',
        'arousal' => 'performance vs arousal',
        _ => 'gradient = acceleration',
      }, const Offset(265, 175));
    } else if (type == 'venn') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(100, 20, 320, 145),
          const Radius.circular(12),
        ),
        p..color = color.withValues(alpha: .25),
      );
      c.drawCircle(
        const Offset(225, 93),
        58,
        Paint()..color = color.withValues(alpha: .13),
      );
      c.drawCircle(
        const Offset(295, 93),
        58,
        Paint()..color = const Color(0xFFEBAD71).withValues(alpha: .25),
      );
      c.drawCircle(const Offset(225, 93), 58, p..color = color);
      c.drawCircle(
        const Offset(295, 93),
        58,
        p..color = const Color(0xFFBF7837),
      );
      label(c, 'A only', const Offset(199, 92));
      label(c, 'A ∩ B', center, size: 11);
      label(c, 'B only', const Offset(322, 92));
      label(c, 'outside: neither', const Offset(260, 178));
    } else if (type == 'atom' || type == 'charges') {
      if (type == 'atom') {
        c.drawCircle(center, 25, Paint()..color = color.withValues(alpha: .15));
        label(c, '+ nucleus', center, size: 11);
        for (int i = 0; i < 3; i++) {
          c.save();
          c.translate(260, 95);
          c.rotate(i * math.pi / 3);
          c.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 240, height: 100),
            p..color = color.withValues(alpha: .35),
          );
          c.restore();
          final a = phase + i * 2 * math.pi / 3;
          c.drawCircle(
            Offset(260 + 120 * math.cos(a), 95 + 50 * math.sin(a)),
            6,
            Paint()..color = color,
          );
        }
        label(c, 'electron model (schematic)', const Offset(260, 180));
      } else {
        for (final x in [170.0, 350.0]) {
          c.drawCircle(
            Offset(x, 95),
            32,
            Paint()..color = color.withValues(alpha: .15),
          );
          label(c, x < 260 ? '+ Q' : '− Q', Offset(x, 95), size: 22);
        }
        arrow(c, const Offset(225, 95), const Offset(295, 95), p);
        label(c, 'Opposite charges attract', const Offset(260, 166));
      }
    } else if (type == 'circuit') {
      final path =
          Path()
            ..moveTo(150, 140)
            ..lineTo(150, 45)
            ..lineTo(235, 45);
      c.drawPath(path, p);
      c.drawLine(const Offset(285, 45), const Offset(370, 45), p);
      c.drawLine(const Offset(370, 45), const Offset(370, 140), p);
      c.drawLine(const Offset(370, 140), const Offset(150, 140), p);
      c.drawLine(const Offset(245, 25), const Offset(245, 65), p);
      c.drawLine(const Offset(270, 33), const Offset(270, 57), p);
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(230, 128, 60, 24),
          const Radius.circular(3),
        ),
        Paint()..color = color.withValues(alpha: .18),
      );
      label(c, 'R', const Offset(260, 140));
      label(c, 'battery', const Offset(260, 15));
      c.drawCircle(Offset(150 + 220 * time, 140), 5, Paint()..color = color);
      label(c, 'I = V / R', const Offset(260, 178));
    } else if (type == 'cell' ||
        type == 'mitosis' ||
        type == 'enzyme' ||
        type == 'heart') {
      if (type == 'cell') {
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(145, 25, 230, 132),
            const Radius.circular(35),
          ),
          p,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(154, 34, 212, 114),
            const Radius.circular(29),
          ),
          p..strokeWidth = 1,
        );
        c.drawOval(
          const Rect.fromLTWH(222, 48, 120, 85),
          Paint()..color = color.withValues(alpha: .12),
        );
        c.drawCircle(
          const Offset(193, 91),
          19,
          Paint()..color = color.withValues(alpha: .4),
        );
        label(c, 'nucleus', const Offset(193, 91), size: 10);
        label(c, 'vacuole', const Offset(282, 91));
        label(c, 'Plant cell · schematic', const Offset(260, 178));
      } else if (type == 'mitosis') {
        final stage = (time * 4).floor().clamp(0, 3);
        final sep = stage >= 2 ? 45.0 : 0.0;
        c.drawOval(const Rect.fromLTWH(155, 25, 210, 130), p);
        for (int i = 0; i < 4; i++) {
          final x = 260 + (i.isEven ? -sep : sep);
          final y = 53 + i * 25.0;
          c.drawLine(Offset(x - 7, y - 7), Offset(x + 7, y + 7), p);
          if (stage < 2) {
            c.drawLine(Offset(x + 7, y - 7), Offset(x - 7, y + 7), p);
          }
        }
        label(
          c,
          ['Prophase', 'Metaphase', 'Anaphase', 'Telophase'][stage],
          const Offset(260, 178),
        );
      } else if (type == 'enzyme') {
        final shape =
            Path()
              ..moveTo(140, 135)
              ..lineTo(140, 55)
              ..quadraticBezierTo(190, 15, 230, 55)
              ..lineTo(225, 80)
              ..lineTo(250, 95)
              ..lineTo(275, 80)
              ..lineTo(270, 55)
              ..quadraticBezierTo(320, 15, 355, 55)
              ..lineTo(355, 135)
              ..close();
        c.drawPath(shape, Paint()..color = color.withValues(alpha: .18));
        c.drawPath(shape, p);
        final y = 30 + 30 * (.5 + .5 * math.sin(phase));
        final tri =
            Path()
              ..moveTo(230, y)
              ..lineTo(270, y)
              ..lineTo(250, y + 25)
              ..close();
        c.drawPath(tri, Paint()..color = const Color(0xFFDA9A4B));
        label(c, 'substrate', const Offset(405, 45));
        label(c, 'enzyme + active site', const Offset(260, 173));
      } else {
        final radius = 43 + 5 * math.sin(phase * 2);
        c.drawCircle(
          center,
          radius,
          Paint()..color = color.withValues(alpha: .12),
        );
        label(c, '♥', center, col: color, size: 55);
        arrow(c, const Offset(160, 95), const Offset(205, 95), p);
        arrow(c, const Offset(315, 95), const Offset(360, 95), p);
        label(c, 'HR × SV = cardiac output', const Offset(260, 178));
      }
    } else if (type == 'triangle' || type == 'lever') {
      if (type == 'triangle') {
        final path =
            Path()
              ..moveTo(155, 145)
              ..lineTo(365, 145)
              ..lineTo(155, 35)
              ..close();
        c.drawPath(path, p);
        label(c, 'opposite', const Offset(112, 91));
        label(c, 'adjacent', const Offset(260, 167));
        label(c, 'hypotenuse', const Offset(280, 77));
        label(c, 'θ', const Offset(328, 131));
      } else {
        c.save();
        c.translate(260, 100);
        c.rotate(math.sin(phase) * .1);
        c.drawLine(const Offset(-140, 0), const Offset(140, 0), p);
        c.restore();
        final tri =
            Path()
              ..moveTo(250, 132)
              ..lineTo(270, 132)
              ..lineTo(260, 105)
              ..close();
        c.drawPath(tri, Paint()..color = color);
        arrow(c, const Offset(145, 40), const Offset(145, 88), p);
        arrow(c, const Offset(375, 40), const Offset(375, 88), p);
        label(c, 'effort', const Offset(145, 22));
        label(c, 'load', const Offset(375, 22));
        label(c, 'fulcrum', const Offset(260, 160));
      }
    } else if (type == 'bars' || type == 'energy') {
      for (int i = 0; i < 4; i++) {
        final height = type == 'energy' ? 100 - i * 23.0 : 35 + i * 22.0;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(130 + i * 70.0, 155 - height, 42, height),
            const Radius.circular(7),
          ),
          Paint()..color = color.withValues(alpha: .3 + i * .15),
        );
        label(
          c,
          type == 'energy'
              ? ['input', 'transfer', 'work', 'heat'][i]
              : '${i + 1}',
          Offset(151 + i * 70.0, 174),
          size: 11,
        );
      }
      label(
        c,
        type == 'energy'
            ? 'Energy transfers; total energy is conserved'
            : 'Compare values using a consistent scale',
        const Offset(260, 17),
        size: 11,
      );
    } else if (type == 'numberline') {
      arrow(c, const Offset(95, 95), const Offset(425, 95), p);
      for (int i = 0; i < 7; i++) {
        final x = 110 + i * 48.0;
        c.drawLine(Offset(x, 88), Offset(x, 102), p);
        label(c, '${i - 3}', Offset(x, 120));
      }
      c.drawCircle(const Offset(158, 95), 6, Paint()..color = color);
      c.drawCircle(
        const Offset(350, 95),
        6,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      label(c, '[−2; 2) includes −2, excludes 2', const Offset(260, 170));
    } else if (type == 'tree') {
      for (final y in [52.0, 138.0]) {
        arrow(c, const Offset(130, 95), Offset(255, y), p);
        for (final dy in [-22.0, 22.0]) {
          arrow(c, Offset(255, y), Offset(385, y + dy), p);
        }
      }
      label(c, 'start', const Offset(99, 95));
      label(
        c,
        'multiply along a path · add separate paths',
        const Offset(260, 180),
        size: 11,
      );
    } else {
      final labels = switch (type) {
        'feedback' => ['change', 'response', 'balance'],
        'cycle' => ['producer', 'consumer', 'recycle'],
        'timeline' => ['past', 'evidence', 'explain'],
        'sequence' => ['1', '4', '7'],
        _ => ['identify', 'connect', 'explain'],
      };
      for (int i = 0; i < 3; i++) {
        final x = 145 + i * 115.0;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 95), width: 95, height: 58),
            const Radius.circular(15),
          ),
          Paint()..color = color.withValues(alpha: .12),
        );
        label(c, labels[i], Offset(x, 95));
        if (i < 2) {
          arrow(c, Offset(x + 50, 95), Offset(x + 62, 95), p);
        }
      }
      c.drawCircle(Offset(145 + 230 * time, 138), 4, Paint()..color = color);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(DiagramPainter old) =>
      old.time != time ||
      old.parameter != parameter ||
      old.type != type ||
      old.color != color;
}
