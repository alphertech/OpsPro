import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [12, 19, 25, 32, 28, 35, 42];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final median = data.reduce((a, b) => a + b) / data.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _ChartPainter(
            data: data,
            labels: labels,
            maxValue: maxValue,
            median: median,
            barColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            medianColor: Colors.green,
            recessionColor: Colors.red,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> labels;
  final double maxValue;
  final double median;
  final Color barColor;
  final Color medianColor;
  final Color recessionColor;

  _ChartPainter({
    required this.data,
    required this.labels,
    required this.maxValue,
    required this.median,
    required this.barColor,
    required this.medianColor,
    required this.recessionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(0, 20, 0, 24);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;
    final barGroupWidth = chartWidth / data.length;

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxValue) * chartHeight;
      final x = padding.left + i * barGroupWidth + barGroupWidth * 0.2;
      final y = padding.top + chartHeight - barHeight;
      final w = barGroupWidth * 0.6;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(barRect, Paint()..color = barColor);

      textPaint.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      );
      textPaint.layout();
      textPaint.paint(canvas, Offset(x + w / 2 - textPaint.width / 2, padding.top + chartHeight + 6));
    }

    final medianY = padding.top + chartHeight - (median / maxValue) * chartHeight;
    final medianPaint = Paint()
      ..color = medianColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(padding.left, medianY), Offset(size.width - padding.right, medianY), medianPaint);

    textPaint.text = TextSpan(text: 'Median', style: TextStyle(fontSize: 9, color: medianColor));
    textPaint.layout();
    textPaint.paint(canvas, Offset(size.width - padding.right - textPaint.width, medianY - 12));

    final progressPaint = Paint()
      ..color = medianColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    path.moveTo(padding.left + barGroupWidth * 0.5, padding.top + chartHeight - (data[0] / maxValue) * chartHeight);
    for (var i = 1; i < data.length; i++) {
      final x = padding.left + i * barGroupWidth + barGroupWidth * 0.5;
      final y = padding.top + chartHeight - (data[i] / maxValue) * chartHeight;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, progressPaint);

    final recessionData = [0.6, 0.55, 0.5, 0.45, 0.4, 0.38, 0.35];
    final recessionPaint = Paint()
      ..color = recessionColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final recessionPath = Path();
    recessionPath.moveTo(padding.left + barGroupWidth * 0.5, padding.top + chartHeight - recessionData[0] * chartHeight);
    for (var i = 1; i < recessionData.length; i++) {
      final x = padding.left + i * barGroupWidth + barGroupWidth * 0.5;
      final y = padding.top + chartHeight - recessionData[i] * chartHeight;
      recessionPath.lineTo(x, y);
    }
    canvas.drawPath(recessionPath, recessionPaint);

    textPaint.text = TextSpan(text: 'Recession', style: TextStyle(fontSize: 9, color: recessionColor));
    textPaint.layout();
    textPaint.paint(canvas, Offset(0, padding.top + chartHeight - recessionData[recessionData.length - 1] * chartHeight - 12));
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
