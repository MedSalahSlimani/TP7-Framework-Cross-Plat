import 'package:flutter/material.dart';
import 'auth_widgets.dart';

/// Courbe : une valeur (heures d'absence) par matière
class AbsenceChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;

  const AbsenceChart({Key? key, required this.labels, required this.values})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text("No data")));
    }
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: CustomPaint(painter: _ChartPainter(labels, values)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  _ChartPainter(this.labels, this.values);

  // ax, ay : point d'ancrage du texte (0 = gauche/haut, 0.5 = centre, 1 = droite/bas)
  void _text(Canvas canvas, String s, Offset pos,
      {double ax = 0, double ay = 0, Color color = Colors.black54,
        FontWeight weight = FontWeight.normal, double fontSize = 11}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width * ax, pos.dy - tp.height * ay));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, right = 20.0, top = 24.0, bottom = 36.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final yMax = (maxV <= 0 ? 1.0 : maxV) * 1.2;

    final grid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // grille horizontale + valeurs de l'axe Y
    const steps = 4;
    for (int i = 0; i <= steps; i++) {
      final y = top + h - h * i / steps;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      _text(canvas, fmtAxis(yMax * i / steps), Offset(left - 6, y),
          ax: 1, ay: 0.5);
    }

    // positions des points
    final n = values.length;
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? left + w / 2 : left + w * i / (n - 1);
      final y = top + h - values[i] / yMax * h;
      points.add(Offset(x, y));
    }

    // courbe
    final line = Paint()
      ..color = kPrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < n; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, line);

    // points, valeurs et noms des matières
    final dot = Paint()..color = kPrimary;
    final dotCenter = Paint()..color = Colors.white;
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(points[i], 6, dot);
      canvas.drawCircle(points[i], 3, dotCenter);
      _text(canvas, fmtAxis(values[i]), Offset(points[i].dx, points[i].dy - 10),
          ax: 0.5, ay: 1, color: kPrimaryDark, weight: FontWeight.bold);
      _text(canvas, labels[i], Offset(points[i].dx, top + h + 8),
          ax: 0.5, color: Colors.black87, weight: FontWeight.w600);
    }

    // axes
    final axis = Paint()
      ..color = Colors.black45
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(left, top), Offset(left, top + h), axis);
    canvas.drawLine(Offset(left, top + h), Offset(left + w, top + h), axis);
  }

  String fmtAxis(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}