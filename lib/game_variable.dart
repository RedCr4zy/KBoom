import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class GameVariables {
  static final gameParameters = _GameParameters();
  static final generalInformation = _GeneralInformation();
  static final gameInformation = _GameInformation();

  static ValueNotifier<String?> code = ValueNotifier<String?>(null);

  static void resetGameState() {
    gameInformation.roomCode.value = null;
    gameInformation.isMaster.value = false;
    gameInformation.isGameStarted.value = false;
    gameInformation.isGameFinished.value = false;
    gameInformation.isAnswerValidate.value = false;
    gameInformation.isEliminated.value = false;
    gameInformation.isCurrent.value = false;
    gameInformation.currentPlayerPseudo.value = null;
    gameInformation.letter.value = null;
    gameInformation.currentTimeLeft.value = 60000;
    gameInformation.myTotalTimeLeft.value = 60000;
    gameInformation.timerStartTimestamp.value = null;
    gameInformation.isTimerPaused.value = true;
    gameInformation.allPlayerTimer.value = {};
    gameInformation.playersStatsList.value = [];
    gameInformation.endGameStats.value = {};
    gameInformation.hasVoted.value = false;
    gameInformation.hasVotedTrue.value = false;
    gameInformation.showVoteBars.value = false;
    gameInformation.isVoteFinal.value = false;
    gameInformation.votesPour.value = 0;
    gameInformation.votesContre.value = 0;
    gameInformation.totalVotes.value = 0;
    gameInformation.totalPlayers.value = 0;
  }

  static ValueNotifier<ServerType> serverType = ValueNotifier<ServerType>(ServerType.production);
  static ValueNotifier<String> customServerIp = ValueNotifier<String>('192.168.1.1');
  static ValueNotifier<int> customServerPort = ValueNotifier<int>(3000);

  // ========================================
  // Central Auth URLs
  // ========================================
  static String get centralAuthHttpUrl {
    if (serverType.value == ServerType.local) {
      return 'http://192.168.1.13:4000';
    }

    return 'https://targets-counts-washing-bald.trycloudflare.com';
  }

  static String get centralAuthWsUrl {
    if (serverType.value == ServerType.local) {
      return 'ws://192.168.1.13:4000';
    }

    return 'wss://targets-counts-washing-bald.trycloudflare.com/api/';
  }

  // ========================================
  // URLs des serveurs de jeu
  // ========================================
  static const String localUrl = 'ws://192.168.1.13:3000';
  static const String productionUrl = 'wss://targets-counts-washing-bald.trycloudflare.com';
  static const String productionHttpUrl = 'https://targets-counts-washing-bald.trycloudflare.com';
}

enum ServerType {
  local,
  production,
  custom
}

class _GameParameters {
  final ValueNotifier<int> maxTime = ValueNotifier(60000);
  final ValueNotifier<bool> canEliminatedPlayersVote = ValueNotifier<bool>(false);
  final ValueNotifier<bool> randomizeOrder = ValueNotifier<bool>(false);
  final ValueNotifier<bool> useAiConfig = ValueNotifier<bool>(false);
}

class _GeneralInformation {
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);
  final ValueNotifier<String?> pseudo = ValueNotifier<String?>(null);
  final ValueNotifier<String?> token = ValueNotifier<String?>(null);
  final ValueNotifier<Map<String, dynamic>> avatarData = ValueNotifier<Map<String, dynamic>>({
    'equipped_color': '#FF5733',
    'equipped_hat': '',
    'equipped_eyes': '',
    'equipped_mouth': '',
  });
}

class _GameInformation {
  final ValueNotifier<String?> roomCode = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isMaster = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGameStarted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGameFinished = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAnswerValidate = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasVotedTrue = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasVoted = ValueNotifier<bool>(false);
  final ValueNotifier<String?> letter = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isCurrent = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentPlayerPseudo = ValueNotifier<String?>(null);
  final ValueNotifier<int> myTotalTimeLeft = ValueNotifier<int>(60000);
  final ValueNotifier<int> currentTimeLeft = ValueNotifier<int>(60000);
  final ValueNotifier<bool> isTimerPaused = ValueNotifier<bool>(true);
  final ValueNotifier<Map<String?, int>> allPlayerTimer = ValueNotifier<Map<String?, int>>({});
  final ValueNotifier<int?> timerStartTimestamp = ValueNotifier<int?>(null);
  final ValueNotifier<bool> isEliminated = ValueNotifier<bool>(false);
  final ValueNotifier<Map<String, dynamic>> endGameStats = ValueNotifier<Map<String, dynamic>>({});
  final ValueNotifier<List<Map<String, dynamic>>> playersStatsList = ValueNotifier<List<Map<String, dynamic>>>([]);

  final votesPour = 0.obs;
  final votesContre = 0.obs;
  final showVoteBars = false.obs;
  final isVoteFinal = false.obs;
  final totalVotes = 0.obs;
  final totalPlayers = 0.obs;
}
