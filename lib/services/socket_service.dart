// lib/services/socket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kboom/main.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/pages/game.dart';
import 'package:kboom/pages/waiting.dart';
import 'package:kboom/pages/timer_manager.dart';
import 'package:kboom/widgets/vote_bars.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:kboom/widgets/notification_overlay.dart';
import 'package:vibration/vibration.dart';
import 'package:get/get.dart';

enum SocketConnectionState { disconnected, connecting, connected, error }

class SocketService {
  WebSocketChannel? _channel;
  Timer? _timeoutTimer;

  String? _lastUrl;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;

  Timer? _voteTimer;
  bool _isDialogOpen = false;

  ValueNotifier<List<Map<String, dynamic>>> playersNotifier = ValueNotifier([]);
  
  final _suggestedConfigController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get suggestedConfigStream => _suggestedConfigController.stream;

  ValueNotifier<SocketConnectionState> connectionState = ValueNotifier(
    SocketConnectionState.disconnected,
  );
  ValueNotifier<String?> errorMessage = ValueNotifier(null);

  void _closeAnyVoteDialog() {
    if (_isDialogOpen) {
      _voteTimer?.cancel();
      _isDialogOpen = false;
      if (navigatorKey.currentState?.canPop() ?? false) {
        navigatorKey.currentState?.pop();
        print("Log: Vote dialogue closed for safety");
      }
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      connectionState.value = SocketConnectionState.error;
      errorMessage.value = 'Impossible de se connecter';
      return;
    }

    _reconnectAttempts++;

    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_lastUrl != null) {
        connectTo(_lastUrl!);
      }
    });
  }

  void connectTo(String url) {
    _lastUrl = url;
    print('🔌 Tentative de connexion WebSocket vers : $url');

    try {
      connectionState.value = SocketConnectionState.connecting;

      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Envoyer le message de connexion immédiatement après la tentative de connexion
      sendJson({
        "type": "connection",
        "token": GameVariables.generalInformation.token.value,
        "avatarData": GameVariables.generalInformation.avatarData.value,
      });

      _timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (connectionState.value == SocketConnectionState.connecting) {
          connectionState.value = SocketConnectionState.error;
          errorMessage.value = 'Le serveur ne répond pas (timeout 15s)';
          print('⏱️ Timeout : Aucune réponse du serveur après 15 secondes');
          _channel?.sink.close();
          _channel = null;
          _attemptReconnect();
        }
      });

      _channel!.stream.listen(
        (message) {
          if (connectionState.value == SocketConnectionState.connecting) {
            _timeoutTimer?.cancel();
            connectionState.value = SocketConnectionState.connected;
            errorMessage.value = null;
            _reconnectAttempts = 0;
            print('✅ Connexion WebSocket établie - Premier message reçu');
          }

          try {
            final data = jsonDecode(message);
            print('📨 Message JSON reçu du serveur: $data');
            _handleMessage(data);
          } catch (_) {
            print('📨 Message brut reçu du serveur: $message');
          }
        },
        onDone: () {
          print('❌ Connexion WebSocket fermée.');
          _timeoutTimer?.cancel();
          connectionState.value = SocketConnectionState.disconnected;
          _attemptReconnect();
        },
        onError: (err) {
          print('⚠️ Erreur WebSocket: $err');
          _timeoutTimer?.cancel();
          connectionState.value = SocketConnectionState.error;
          errorMessage.value = 'Erreur de connexion: $err';
          _attemptReconnect();
        },
      );
    } catch (e) {
      print('💥 Exception pendant WebSocket.connect: $e');
      _timeoutTimer?.cancel();
      connectionState.value = SocketConnectionState.error;
      errorMessage.value = 'Erreur: $e';
      _channel = null;
      _attemptReconnect();
    }
  }

  /* ===========================
     GESTION MESSAGES
  =========================== */

  void _handleMessage(Map<String, dynamic> data) {
    final gi = GameVariables.gameInformation; // Raccourci

    switch (data['type']) {
      case 'connectionConfirmed':
        print('✅ Connexion au serveur confirmée');
        break;

      case 'updatePlayers':
        playersNotifier.value = List<Map<String, dynamic>>.from(
          data['players'] ?? [],
        );
        if (data['roomCode'] != null) {
          gi.roomCode.value = data['roomCode'];
        }
        if (data['maxTime'] != null) {
          GameVariables.gameParameters.maxTime.value = data['maxTime'] as int;
        }
        if (data['canEliminatedPlayersVote'] != null) {
          GameVariables.gameParameters.canEliminatedPlayersVote.value = data['canEliminatedPlayersVote'] == true;
        }
        if (data['randomizeOrder'] != null) {
          GameVariables.gameParameters.randomizeOrder.value = data['randomizeOrder'] == true;
        }
        if (data['useAiConfig'] != null) {
          GameVariables.gameParameters.useAiConfig.value = data['useAiConfig'] == true;
        }
        break;

      case 'roomJoined':
        if (data['roomCode'] != null) {
          gi.roomCode.value = data['roomCode'];
        }
        break;

      case 'suggestedConfig':
        if (data['maxTime'] != null) {
          GameVariables.gameParameters.maxTime.value = data['maxTime'] as int;
        }
        if (data['canEliminatedPlayersVote'] != null) {
          GameVariables.gameParameters.canEliminatedPlayersVote.value = data['canEliminatedPlayersVote'] == true;
        }
        if (data['randomizeOrder'] != null) {
          GameVariables.gameParameters.randomizeOrder.value = data['randomizeOrder'] == true;
        }
        _suggestedConfigController.add(data);
        break;

      case 'redirection':
        if (data['roomCode'] != null) {
          gi.roomCode.value = data['roomCode'];
        }
        if (data['isMaster'] != null) {
          gi.isMaster.value = data['isMaster'] == true;
        }
        break;

      case 'master':
        gi.isMaster.value = true;
        break;

      case 'gameStarted':
        _handleGameStart(data);
        break;

      case 'nextTurn':
        _closeAnyVoteDialog();

        gi.showVoteBars.value = false;
        gi.isVoteFinal.value = false;

        final currentPlayerToken = data['currentPlayerToken'];
        final currentPlayerPseudo = data['currentPlayerPseudo'];
        final myToken = GameVariables.generalInformation.token.value;

        const animationDuration = Duration(seconds: 2);

        // FIX ✅ On ne fait PLUS de pop global
        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (dialogContext) {
              Future.delayed(animationDuration, () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              });

              return NotificationOverlay(
                message: "Tour de $currentPlayerPseudo !",
                color: currentPlayerToken == myToken
                    ? dialogContext.successColor
                    : dialogContext.primaryColor,
                duration: animationDuration,
              );
            },
          );
        }

        _handleTurnUpdate(data, isReplay: false, forcePause: true);

        Future.delayed(animationDuration, () {
          gi.isTimerPaused.value = false;
        });

        break;

      case 'replayTurn':
        _closeAnyVoteDialog();

        final currentPlayerToken = data['currentPlayerToken'];
        final currentPlayerPseudo = data['currentPlayerPseudo'];
        final myToken = GameVariables.generalInformation.token.value;

        const animationDuration = Duration(seconds: 2);

        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (dialogContext) {
              Future.delayed(animationDuration, () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              });

              return NotificationOverlay(
                message: "Tour de $currentPlayerPseudo !",
                color: currentPlayerToken == myToken
                    ? dialogContext.successColor
                    : dialogContext.primaryColor,
                duration: animationDuration,
              );
            },
          );
        }

        _handleTurnUpdate(data, isReplay: true, forcePause: true);

        Future.delayed(animationDuration, () {
          gi.isTimerPaused.value = false;
        });

        break;

      case 'answerValidated':
        gi.isAnswerValidate.value = true;
        gi.showVoteBars.value = true;
        gi.votesPour.value = 0;
        gi.votesContre.value = 0;
        gi.isTimerPaused.value = true;
        _updateAllTimers(data['allTimers']);
        break;

      case 'voteUpdate':
        final votes = data['votes'] != null
            ? Map<String, dynamic>.from(data['votes'])
            : null;

        if (votes != null) {
          gi.votesPour.value = votes.values.where((v) => v == true).length;
          gi.votesContre.value = votes.values.where((v) => v == false).length;
        } else {
          gi.votesPour.value = data['votesPour'] ?? 0;
          gi.votesContre.value = data['votesContre'] ?? 0;
        }

        gi.totalVotes.value = data['totalVotes'];
        gi.totalPlayers.value = data['totalPlayers'];

        // Annuler le timer précédent s'il existe
        _voteTimer?.cancel();

        // Si dialogue pas ouvert -> l'ouvrir

        if (!_isDialogOpen && navigatorKey.currentContext != null) {
          _isDialogOpen = true;
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (dialogContext) {
              return Dialog(
                backgroundColor: Colors.black.withOpacity(0.6),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Obx(
                    // Utilise Obx pour pouvoir écouter les changements sans fermer le dialog
                    () => VoteBars(
                      votesPour: gi.votesPour.value,
                      votesContre: gi.votesContre.value,
                      totalVotes: gi.totalVotes.value,
                      totalPlayers: gi.totalPlayers.value,
                    ),
                  ),
                ),
              );
            },
          ).then((_) => _isDialogOpen = false);
        }
        break;

      case 'voteResult':
        final votes = data['votes'] != null
            ? Map<String, dynamic>.from(data['votes'])
            : null;

        if (votes != null) {
          gi.votesPour.value = votes.values.where((v) => v == true).length;
          gi.votesContre.value = votes.values.where((v) => v == false).length;
        } else {
          gi.votesPour.value = data['votesPour'] ?? 0;
          gi.votesContre.value = data['votesContre'] ?? 0;
        }

        gi.totalVotes.value = data['totalVotes'];
        gi.totalPlayers.value = data['totalPlayers'];

        // Annuler le timer précédent s'il existe
        _voteTimer?.cancel();

        // Si dialogue pas ouvert -> l'ouvrir

        if (!_isDialogOpen && navigatorKey.currentContext != null) {
          _isDialogOpen = true;
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (dialogContext) {
              return Dialog(
                backgroundColor: Colors.black.withOpacity(0.6),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Obx(
                    // Utilise Obx pour pouvoir écouter les changements sans fermer le dialog
                    () => VoteBars(
                      votesPour: gi.votesPour.value,
                      votesContre: gi.votesContre.value,
                      totalVotes: gi.totalVotes.value,
                      totalPlayers: gi.totalPlayers.value,
                    ),
                  ),
                ),
              );
            },
          ).then((_) => _isDialogOpen = false);
        }

        // On lance (ou relance) le compte à rebours de 3 secondes
        _voteTimer = Timer(const Duration(seconds: 3), () {
          if (_isDialogOpen && navigatorKey.currentContext != null) {
            // On demande à Flutter d'attendre la prochaine frame disponible
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_isDialogOpen) {
                // On vérifie à nouveau
                if (Navigator.of(navigatorKey.currentContext!).canPop()) {
                  Navigator.of(navigatorKey.currentContext!).pop();
                  _isDialogOpen = false;
                }
              }
            });
          }
        });
        break;

      case 'playerEliminated':
        _closeAnyVoteDialog();

        final eliminatedPseudo = data['eliminatedPlayerPseudo'];
        final eliminatedToken = data['eliminatedPlayerToken'];

        // Mettre à jour les stats des joueurs et leurs timers restants
        _updateAllTimers(data['allTimers']);

        // Si c'est nous qui sommes éliminés
        if (eliminatedToken == GameVariables.generalInformation.token.value) {
          gi.isEliminated.value = true;
          gi.isCurrent.value = false;
        }

        // Pendant la transition d'élimination de 3 secondes, on fige/coupe le chrono local
        gi.isTimerPaused.value = true;
        TimerManager.stopCountdown();

        // ✅ INDISPENSABLE : Fermer les barres de vote si elles sont ouvertes
        if (_isDialogOpen && navigatorKey.currentContext != null) {
          if (Navigator.of(navigatorKey.currentContext!).canPop()) {
            Navigator.of(navigatorKey.currentContext!).pop();
            _isDialogOpen = false;
            _voteTimer?.cancel();
          }
        }

        const animationDuration = Duration(seconds: 2);

        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (dialogContext) {
              Future.delayed(animationDuration, () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              });

              return NotificationOverlay(
                message: "Joueur éliminé : $eliminatedPseudo !",
                color: dialogContext.successColor,
                duration: animationDuration,
              );
            },
          );
        }
        break;



      case 'finishGame':
        if (data['stats'] != null) {
          gi.endGameStats.value = Map<String, dynamic>.from(data['stats']);
        }
        gi.isGameFinished.value = true;
        break;

      case 'gameReset':
        gi.isGameStarted.value = false;
        gi.isGameFinished.value = false;
        gi.isAnswerValidate.value = false;
        gi.isEliminated.value = false;
        gi.currentTimeLeft.value = 60000;
        gi.myTotalTimeLeft.value = 60000;
        gi.isTimerPaused.value = true;
        gi.endGameStats.value = {};
        
        if (navigatorKey.currentContext != null) {
          Navigator.pushReplacement(
            navigatorKey.currentContext!,
            MaterialPageRoute(builder: (_) => const WaitingPage()),
          );
        }
        break;

      case 'malusApplied':
        final pseudo = data['pseudo'];
        final seconds = data['seconds'];
        final reason = data['reason'];

        _updateAllTimers(data['allTimers']);

        final myPseudo = GameVariables.generalInformation.pseudo.value;
        if (myPseudo != null && data['allTimers'] != null) {
          final myTimerData = (data['allTimers'] as List<dynamic>).firstWhere(
            (t) => t['pseudo'] == myPseudo,
            orElse: () => null,
          );
          if (myTimerData != null) {
            gi.myTotalTimeLeft.value = myTimerData['totalTimeLeft'] ?? 60000;
            gi.currentTimeLeft.value = myTimerData['totalTimeLeft'] ?? 60000;
            gi.isEliminated.value = myTimerData['isEliminated'] == true;
          }
        }
        
        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (dialogContext) {
              final showDuration = const Duration(seconds: 3);
              Future.delayed(showDuration, () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              });
              
              return NotificationOverlay(
                message: "⚠️ Malus de ${seconds}s pour $pseudo !\n($reason)",
                color: dialogContext.dangerColor,
                duration: showDuration,
              );
            },
          );
        }
        break;

      case 'leftRoom':
        if (data['roomCode'] != null) {
          print("Log: Room ${data['roomCode']} left");
        }
        break;

      case 'error':
        errorMessage.value = data['message'] ?? 'Erreur inconnue';
        print('❌ Erreur serveur : ${data['message']}');
        break;

      case 'message':
        // Message texte brut, ignoré
        break;

      default:
        print('⚠️ Type non géré : ${data['type']}');
    }
  }

  /// Gère le démarrage de la partie
  void _handleGameStart(Map<String, dynamic> data) {
    final gi = GameVariables.gameInformation;

    gi.isGameStarted.value = true;
    gi.letter.value = data['letter'];
    gi.isCurrent.value = data['isCurrentPlayer'] == true;
    gi.currentPlayerPseudo.value = data['currentPlayerPseudo'];

    // VIBRATION ALERTE DEBUT DE NOTRE TOUR
    if (gi.isCurrent.value) {
      try {
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator == true) {
            Vibration.vibrate(pattern: [0, 150, 100, 150, 100, 300]);
          }
        });
      } catch (e) {
        print('Vibration non supportée : $e');
      }
    }
    // Timer
    gi.myTotalTimeLeft.value = data['timeLeft'] ?? 60000;
    gi.currentTimeLeft.value = data['timeLeft'] ?? 60000;
    gi.timerStartTimestamp.value = data['timerStartTimestamp'];
    gi.isTimerPaused.value = false;

    _updateAllTimers(data['allTimers']);

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      try {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GamePage()),
        );
      } catch (e) {
        print('⚠️ Navigation vers la partie impossible: $e');
      }
    }

    print(
      '🎮 Partie démarrée - Lettre: ${gi.letter.value} - Tour actif: ${gi.isCurrent.value}',
    );
  }

  /// Gère les changements de tour (nextTurn et replayTurn)
  void _handleTurnUpdate(
    Map<String, dynamic> data, {
    required bool isReplay,
    bool forcePause = true,
  }) {
    final gi = GameVariables.gameInformation;
    final wasMyTurn = gi.isCurrent.value;

    gi.isCurrent.value = data['isCurrentPlayer'] == true;

    // VIBRATION ALERTE CHANGEMENT DE TOUR
    if (gi.isCurrent.value && !wasMyTurn) {
      try {
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator == true) {
            Vibration.vibrate(pattern: [0, 150, 100, 150, 100, 300]);
          }
        });
      } catch (e) {
        print('Vibration non supportée : $e');
      }
    }
    gi.currentPlayerPseudo.value = data['currentPlayerPseudo'];
    gi.isAnswerValidate.value = false;
    gi.hasVoted.value = false;
    gi.hasVotedTrue.value = false;

    // Timer
    gi.myTotalTimeLeft.value = data['timeLeft'] ?? gi.myTotalTimeLeft.value;
    gi.currentTimeLeft.value = data['timeLeft'] ?? gi.currentTimeLeft.value;
    gi.timerStartTimestamp.value = data['timerStartTimestamp'];

    if (forcePause) {
      gi.isTimerPaused.value = true;
    } else {
      gi.isTimerPaused.value = data['isCurrentPlayer'] != true;
    }

    _updateAllTimers(data['allTimers']);

    print(
      isReplay
          ? '🔄 Tour rejoué - Actif: ${gi.isCurrent.value}'
          : '➡️ Tour suivant - Actif: ${gi.isCurrent.value}',
    );
  }

  /// Met à jour les timers de tous les joueurs
  void _updateAllTimers(dynamic allTimersData) {
    if (allTimersData == null) return;

    try {
      final List<dynamic> timersList = allTimersData as List<dynamic>;
      final List<Map<String, dynamic>> parsedStats = [];
      final Map<String?, int> timersMap = {};

      for (var timer in timersList) {
        final pseudo = timer['pseudo'] as String?;
        final timeLeft = timer['totalTimeLeft'] as int?;
        final isEliminated = timer['isEliminated'] == true;
        final malus = timer['malus'] as int? ?? 0;

        if (pseudo != null) {
          timersMap[pseudo] = timeLeft ?? 0;
          parsedStats.add({
            'pseudo': pseudo,
            'timeLeft': timeLeft ?? 0,
            'isEliminated': isEliminated,
            'malus': malus,
          });
        }
      }

      GameVariables.gameInformation.allPlayerTimer.value = timersMap;
      GameVariables.gameInformation.playersStatsList.value = parsedStats;
      print('⏱️ Timers mis à jour : $timersMap');
    } catch (e) {
      print('⚠️ Erreur lors de la mise à jour des timers : $e');
    }
  }

  /* ===========================
     ENVOI
  =========================== */

  void sendJson(Map<String, dynamic> object) {
    if (_channel == null) {
      print('❌ Impossible d\'envoyer : pas de connexion');
      return;
    }

    try {
      final payload = jsonEncode(object);
      _channel!.sink.add(payload);
      print('📤 Envoi : $payload');
    } catch (e) {
      print('❌ Erreur envoi JSON: $e');
    }
  }

  /* ===========================
     DECONNEXION
  =========================== */

  void disconnect() {
    _timeoutTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;

    playersNotifier.value = [];
    connectionState.value = SocketConnectionState.disconnected;
    errorMessage.value = null;
  }

  void reconnect() {
    if (_lastUrl != null) {
      disconnect();
      Future.delayed(const Duration(milliseconds: 500), () {
        connectTo(_lastUrl!);
      });
    }
  }
}

final socketService = SocketService();
