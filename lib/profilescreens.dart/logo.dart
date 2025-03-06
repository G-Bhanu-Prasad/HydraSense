import 'package:flutter/material.dart';

class HydraSenseLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const HydraSenseLogo({
    Key? key,
    this.size = 200,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.75, // Maintain aspect ratio of original logo
      child: CustomPaint(
        painter: HydraSenseLogoPainter(showText: showText),
        size: Size(size, size * 0.75),
      ),
    );
  }
}

class HydraSenseLogoPainter extends CustomPainter {
  final bool showText;

  HydraSenseLogoPainter({this.showText = true});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;

    // Scale factors
    final double scaleX = width / 400;
    final double scaleY = height / 300;

    // Hexagon background
    final Path hexagonPath = Path();
    hexagonPath.moveTo(centerX, 50 * scaleY);
    hexagonPath.lineTo(centerX + 120 * scaleX, 100 * scaleY);
    hexagonPath.lineTo(centerX + 120 * scaleX, 200 * scaleY);
    hexagonPath.lineTo(centerX, 260 * scaleY);
    hexagonPath.lineTo(centerX - 120 * scaleX, 200 * scaleY);
    hexagonPath.lineTo(centerX - 120 * scaleX, 100 * scaleY);
    hexagonPath.close();

    final Paint hexagonFillPaint = Paint()
      ..color = const Color(0xFF0A0E21)
      ..style = PaintingStyle.fill;

    final Paint hexagonStrokePaint = Paint()
      ..color = const Color(0xFF1A2737)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scaleX;

    canvas.drawPath(hexagonPath, hexagonFillPaint);
    canvas.drawPath(hexagonPath, hexagonStrokePaint);

    // Professional water drop shape
    canvas.save();
    canvas.translate(160 * scaleX, 135 * scaleY);
    canvas.scale(0.65 * scaleX, 0.65 * scaleY);

    final Path waterDropPath = Path();
    waterDropPath.moveTo(120, 20);
    waterDropPath.cubicTo(170, 60, 200, 120, 200, 160);
    waterDropPath.cubicTo(200, 220, 160, 260, 100, 260);
    waterDropPath.cubicTo(40, 260, 0, 220, 0, 160);
    waterDropPath.cubicTo(0, 120, 30, 60, 80, 20);
    waterDropPath.close();

    // Gradient for water drop
    final Paint waterDropPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E90FF),
          const Color(0xFF2563EB),
          const Color(0xFF1E3A8A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 200, 260));

    canvas.drawPath(waterDropPath, waterDropPaint);

    // Upper wave line
    final Path upperWavePath = Path();
    upperWavePath.moveTo(40, 140);
    upperWavePath.cubicTo(60, 130, 80, 150, 100, 140);
    upperWavePath.cubicTo(120, 130, 140, 150, 160, 140);

    final Paint waveLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(upperWavePath, waveLinePaint);

    // Lower wave line
    final Path lowerWavePath = Path();
    lowerWavePath.moveTo(50, 170);
    lowerWavePath.cubicTo(70, 160, 90, 180, 110, 170);
    lowerWavePath.cubicTo(130, 160, 150, 180, 170, 170);

    final Paint lowerWaveLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(lowerWavePath, lowerWaveLinePaint);
    canvas.restore();

    // Decorative dots
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF4D8FFF).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(100 * scaleX, 100 * scaleY), 3 * scaleX, dotPaint);
    canvas.drawCircle(Offset(300 * scaleX, 100 * scaleY), 3 * scaleX, dotPaint);
    canvas.drawCircle(Offset(100 * scaleX, 200 * scaleY), 3 * scaleX, dotPaint);
    canvas.drawCircle(Offset(300 * scaleX, 200 * scaleY), 3 * scaleX, dotPaint);

    if (showText) {
      // Logo Text
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: 'HYDRASENSE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30 * scaleX,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            letterSpacing: 1 * scaleX,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centerX - textPainter.width / 2,
          220 * scaleY - textPainter.height / 2,
        ),
      );

      // Tagline
      final TextPainter taglinePainter = TextPainter(
        text: TextSpan(
          text: 'HYDRATION INTELLIGENCE',
          style: TextStyle(
            // color: const Color(0xFF4D8FFF),
            color: Colors.blue,
            fontSize: 12 * scaleX,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            letterSpacing: 1.5 * scaleX,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      taglinePainter.layout();
      taglinePainter.paint(
        canvas,
        Offset(
          centerX - taglinePainter.width / 2,
          245 * scaleY - taglinePainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Example usage - Add this to your app
class LogoPage extends StatelessWidget {
  const LogoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      // appBar: AppBar(
      //   title: const Text('HydraSense Logo'),
      //   backgroundColor: const Color(0xFF1A2737),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Full logo with text
            const HydraSenseLogo(
              size: 300,
              showText: true,
            ),
            const SizedBox(height: 40),
            // Icon only version (for app icon)
            const HydraSenseLogo(
              size: 100,
              showText: false,
            ),
            const SizedBox(height: 40),
            // Example of how to integrate with other elements
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFF1A2737).withOpacity(0.4),
            //     borderRadius: BorderRadius.circular(15),
            //   ),
            //   child: Column(
            //     children: [
            //       const HydraSenseLogo(
            //         size: 120,
            //         showText: false,
            //       ),
            //       const SizedBox(height: 16),
            //       Text(
            //         'Track your hydration journey',
            //         style: TextStyle(
            //           color: Colors.blue[400],
            //           fontSize: 16,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
