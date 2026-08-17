import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _circleController;
  Timer? _vibrationTimer;
  int _lastSecond = -1;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    // Ecouter le temps pour animer le cercle
    GameVariables.gameInformation.currentTimeLeft.addListener(_updateCircle);
  }

  void _updateCircle() {
    final timeLeft = GameVariables.gameInformation.currentTimeLeft.value;
    final currentSecond = (timeLeft / 1000).floor();

    // Nouvelle seconde ?
    if (currentSecond != _lastSecond) {
      _lastSecond = currentSecond;

      // Animer le cercle
      _circleController.forward(from: 0);

      // Ne vibrer que si c'est le tour de l'utilisateur
      final isMyTurn = GameVariables.gameInformation.isCurrent.value;
      if (isMyTurn) {
        final isVerySlow = timeLeft < 5000;
        final intensity = timeLeft < 10000 ? 60 : 30;

        try {
          Vibration.hasVibrator().then((hasVibrator) {
            if (hasVibrator == true) {
              if (isVerySlow) {
                // Double pulse pour stresser quand < 5s
                Vibration.vibrate(duration: intensity);
                Future.delayed(const Duration(milliseconds: 250), () {
                  Vibration.vibrate(duration: intensity);
                });
              } else {
                Vibration.vibrate(duration: intensity);
              }
            }
          });
        } catch (e) {
          print('Vibration non supportée : $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GameVariables.gameInformation.currentTimeLeft,
      builder: (context, timeLeft, _) {
        final seconds = (timeLeft / 1000).ceil();
        final isSlow = timeLeft < 10000;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Cercle animé
            AnimatedBuilder(
              animation: _circleController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(240, 240),
                  painter: CircleTimerPainter(
                    progress: _circleController.value,
                    color: isSlow ? context.dangerColor : context.primaryColor,
                  ),
                );
              },
            ),
            // Texte qui clignote si t < 10s
            AnimatedOpacity(
              opacity: isSlow && (seconds % 2 == 0) ? 0.3 : 1.0,
              duration: Duration(milliseconds: 500),
              child: Text(
                "$seconds s",
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: isSlow ? context.dangerColor : context.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    GameVariables.gameInformation.currentTimeLeft.removeListener(_updateCircle);
    _circleController.dispose();
    _vibrationTimer?.cancel();
    super.dispose();
  }
}

class CircleTimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircleTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleTimerPainter oldDelegate) => true;
}
