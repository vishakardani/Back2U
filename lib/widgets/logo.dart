
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum LogoSize { sm, lg }
enum LogoVariant { light, dark }

class Back2ULogo extends StatefulWidget {
  final LogoSize size;
  final LogoVariant variant;
  final bool showSlogan;

  const Back2ULogo({
    super.key,
    this.size = LogoSize.lg,
    this.variant = LogoVariant.dark,
    this.showSlogan = true,
  });

  @override
  State<Back2ULogo> createState() => _Back2ULogoState();
}

class _Back2ULogoState extends State<Back2ULogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.size == LogoSize.lg ? 1.0 : 0.33;
    final textColor = widget.variant == LogoVariant.light ? Colors.white : const Color(0xFF0F172A);
    final brandColor = widget.variant == LogoVariant.light ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240 * scale,
          height: 140 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arched Text Simulation
              Positioned(
                top: 20 * scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Back", style: TextStyle(color: textColor, fontSize: 40 * scale, fontWeight: FontWeight.w900, letterSpacing: -1)),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: 0.15 + (0.05 * _controller.value),
                          child: Text("2", style: TextStyle(color: brandColor, fontSize: 48 * scale, fontWeight: FontWeight.w900)),
                        );
                      },
                    ),
                    Text("U", style: TextStyle(color: textColor, fontSize: 40 * scale, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ],
                ),
              ),
              // Paper Plane Widget
              Positioned(
                bottom: 10 * scale,
                child: CustomPaint(
                  size: Size(100 * scale, 70 * scale),
                  painter: PaperPlanePainter(color: brandColor, strokeColor: textColor),
                ),
              ),
            ],
          ),
        ),
        if (widget.showSlogan) ...[
          const SizedBox(height: 8),
          Text(
            "Property Where It Belongs..",
            style: TextStyle(
              color: brandColor,
              fontSize: 14 * scale,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
              fontFamily: 'Serif',
            ),
          ),
          Container(
            height: 2,
            width: 80 * scale,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: brandColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ],
    );
  }
}

class PaperPlanePainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  PaperPlanePainter({required this.color, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.6)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.6)
      ..lineTo(size.width * 0.9, size.height * 0.1)
      ..lineTo(size.width * 0.8, size.height * 0.9)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..lineTo(size.width * 0.4, size.height * 1.0)
      ..close();

    // Flight Trail
    final trail = Path()
      ..moveTo(-30, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.8, size.width * 0.4, size.height * 1.0);

    canvas.drawPath(trail, Paint()..color = strokeColor.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
    
    // Internal Detail Line
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 1.0),
      Offset(size.width * 0.8, size.height * 0.9),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
