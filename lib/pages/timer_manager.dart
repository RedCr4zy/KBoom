import 'dart:async';
import 'package:kboom/game_variable.dart';
import 'package:kboom/services/socket_service.dart';

class TimerManager {
  static Timer? _timer;

  static void startCountdown() {
    _timer?.cancel();

    final timestampDebut = GameVariables.gameInformation.timerStartTimestamp.value;
    if (timestampDebut == null) {
      print("⚠️ Timer non démarré : pas de timestamp");
      return;
    }

    final isMyTurn = GameVariables.gameInformation.isCurrent.value;
    final activePseudo = GameVariables.gameInformation.currentPlayerPseudo.value;
    
    final tempsTotal = isMyTurn 
        ? GameVariables.gameInformation.myTotalTimeLeft.value
        : (GameVariables.gameInformation.allPlayerTimer.value[activePseudo] ?? 60000);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final maintenant = DateTime.now().millisecondsSinceEpoch;

      int tempsEcoule = maintenant - timestampDebut;
      if (tempsEcoule < 0) tempsEcoule = 0;

      final tempsRestant = tempsTotal - tempsEcoule;

      GameVariables.gameInformation.currentTimeLeft.value = tempsRestant;

      if (tempsRestant <= 0) {
        stopCountdown();
        GameVariables.gameInformation.currentTimeLeft.value = 0;

        if (isMyTurn) {
          socketService.sendJson({
            "type": "timeout",
            "roomCode": GameVariables.gameInformation.roomCode.value,
            "token": GameVariables.generalInformation.token.value,
          });
        }
        return;
      }
    });
  }

  static void stopCountdown() {
    _timer?.cancel();
    _timer = null;
    GameVariables.gameInformation.myTotalTimeLeft.value =
        GameVariables.gameInformation.currentTimeLeft.value;
    print("Timer stopped");
  }
}
