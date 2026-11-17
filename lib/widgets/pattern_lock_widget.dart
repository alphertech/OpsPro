import 'package:flutter/material.dart';

class PatternLockWidget extends StatefulWidget {
  final Function(String)? onPatternComplete;
  final double size;
  final Color selectedColor;

  const PatternLockWidget({
    super.key,
    this.onPatternComplete,
    this.size = 280,
    this.selectedColor = Colors.blue,
  });

  @override
  State<PatternLockWidget> createState() => _PatternLockWidgetState();
}

class _PatternLockWidgetState extends State<PatternLockWidget> {
  final List<int> _selectedDots = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / 3;
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _PatternPainter(
                  selectedDots: _selectedDots,
                  cellSize: cellSize,
                  selectedColor: widget.selectedColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final cellSize = box.size.width / 3;

    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final dotCenter = Offset(
          col * cellSize + cellSize / 2,
          row * cellSize + cellSize / 2,
        );
        final distance = (localPosition - dotCenter).distance;
        if (distance < cellSize * 0.4) {
          final dotIndex = row * 3 + col;
          if (!_selectedDots.contains(dotIndex)) {
            setState(() => _selectedDots.add(dotIndex));
          }
        }
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_selectedDots.length >= 4 && widget.onPatternComplete != null) {
      final pattern = _selectedDots.join(',');
      widget.onPatternComplete!(pattern);
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _selectedDots.clear());
    });
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> selectedDots;
  final double cellSize;
  final Color selectedColor;

  _PatternPainter({
    required this.selectedDots,
    required this.cellSize,
    required this.selectedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = selectedColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = selectedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final center = Offset(
          col * cellSize + cellSize / 2,
          row * cellSize + cellSize / 2,
        );
        final isSelected = selectedDots.contains(row * 3 + col);
        canvas.drawCircle(center, cellSize * 0.12, isSelected ? selectedPaint : dotPaint);
      }
    }

    if (selectedDots.length > 1) {
      final path = Path();
      for (var i = 0; i < selectedDots.length; i++) {
        final row = selectedDots[i] ~/ 3;
        final col = selectedDots[i] % 3;
        final point = Offset(col * cellSize + cellSize / 2, row * cellSize + cellSize / 2);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.selectedDots != selectedDots;
  }
}
