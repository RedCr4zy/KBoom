import 'package:flutter/material.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/pages/timer_manager.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/pages/results_page.dart';
import 'package:kboom/utils/player_status_formatter.dart';
import 'package:kboom/widgets/timer_widget.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  VoidCallback? _timerListener;

  @override
  void initState() {
    super.initState();
    _timerListener = () {
      if (GameVariables.gameInformation.isTimerPaused.value == false) {
        TimerManager.startCountdown();
      } else {
        TimerManager.stopCountdown();
      }
    };

    GameVariables.gameInformation.isTimerPaused.addListener(_timerListener!);
    _timerListener!(); // Appel initial
  }

  @override
  void dispose() {
    GameVariables.gameInformation.isTimerPaused.removeListener(_timerListener!);
    TimerManager.stopCountdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GameVariables.generalInformation.isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: context.backgroundColor,
          endDrawer: _buildStatsDrawer(context),
          body: SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Stack(
                  children: [
                    // =====================================================
                    // Overlay élimination
                    // =====================================================
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          GameVariables.gameInformation.isEliminated,
                      builder: (context, isEliminated, _) {
                        if (!isEliminated) return SizedBox.shrink();

                        return Positioned.fill(
                          child: Container(
                            color: Colors.black.withAlpha(220),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.block,
                                    size: 100,
                                    color: context.dangerColor,
                                  ),
                                  Text(
                                    "Vous avez été éliminé !",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: context.dangerColor,
                                    ),
                                  ),
                                  Text(
                                    "Vous pouvez regarder la fin de la partie",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withAlpha(0),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text("Quitter"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      children: [
                        // =====================================================
                        // TOP BAR (STATS BUTTON)
                        // =====================================================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: Icon(Icons.leaderboard, color: context.primaryColor, size: 28),
                                  onPressed: () {
                                    Scaffold.of(context).openEndDrawer();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // =====================================================
                        // CHANGER DE PAGE (results.dart)
                        // =====================================================
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              GameVariables.gameInformation.isGameFinished,
                          builder: (context, isFinished, _) {
                            if (isFinished) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted &&
                                    GameVariables
                                            .gameInformation
                                            .isGameStarted
                                            .value ==
                                        true) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ResultsPage(),
                                    ),
                                  );
                                }
                              });
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // =====================================================
                        // AFFICHAGE DE LA LETTRE EN HAUT
                        // =====================================================
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Lettre :",
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 21,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<String?>(
                                valueListenable:
                                    GameVariables.gameInformation.letter,
                                builder: (context, letter, _) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        letter ?? '----',
                                        style: TextStyle(
                                          fontSize: 84,
                                          fontWeight: FontWeight.bold,
                                          color: context.primaryColor,
                                          letterSpacing: 6,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // =====================================================
                        // JOUEUR ACTIF
                        // =====================================================
                        ValueListenableBuilder<String?>(
                          valueListenable:
                              GameVariables.gameInformation.currentPlayerPseudo,
                          builder: (context, currentPlayerPseudo, _) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: context.primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tour de : ${currentPlayerPseudo ?? "En attente..."}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: context.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const Spacer(),

                        // =====================================================
                        // TIMER OR INLINE STATS
                        // =====================================================
                        ValueListenableBuilder<bool>(
                          valueListenable: GameVariables.gameInformation.isCurrent,
                          builder: (context, isCurrent, _) {
                            if (isCurrent) {
                              return const TimerWidget();
                            } else {
                              return _buildInlineStatsList(context);
                            }
                          },
                        ),
                        const Spacer(),

                        // =====================================================
                        // AFFICHAGE BOUTONS SELON ROLE
                        // =====================================================
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              GameVariables.gameInformation.isCurrent,
                          builder: (context, isCurrent, _) {
                            // ✅ CAS 1 : SPECTATEUR (pas mon tour)
                            if (!isCurrent) {
                              return _buildSpectatorButtons(context);
                            }

                            // ✅ CAS 2 : JOUEUR ACTIF (mon tour)
                            return _buildActivePlayerButton(context);
                          },
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // BOUTONS POUR LES SPECTATEURS
  // =====================================================
  Widget _buildSpectatorButtons(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GameVariables.gameInformation.isEliminated,
      builder: (context, isEliminated, _) {
        final canVote = !isEliminated || GameVariables.gameParameters.canEliminatedPlayersVote.value;

        if (!canVote) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Vous ne pouvez plus voter",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.dangerColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: GameVariables.gameInformation.isAnswerValidate,
          builder: (context, isAnswerValidate, _) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideEnough = constraints.maxWidth > 500;

                  // Boutons désactivés si la réponse n'est pas encore validée
                  if (!isAnswerValidate) {
                    return _buildButtonLayout(
                      isWideEnough: isWideEnough,
                      validateColor: context.mutedColor,
                      refuseColor: context.mutedColor,
                      onValidate: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Attendez que le joueur valide sa réponse",
                            ),
                            backgroundColor: context.warningColor,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      onRefuse: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              "Attendez que le joueur valide sa réponse",
                            ),
                            backgroundColor: context.warningColor,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      context: context,
                    );
                  }

                  // Boutons actifs une fois la réponse validée
                  return ValueListenableBuilder<bool>(
                    valueListenable: GameVariables.gameInformation.hasVoted,
                    builder: (context, hasVoted, child) {
                      if (!hasVoted) {
                        return _buildButtonLayout(
                          isWideEnough: isWideEnough,
                          validateColor: context.successColor,
                          refuseColor: context.dangerColor,
                          onValidate: () {
                            print("Le mot a été validé");
                            GameVariables.gameInformation.hasVotedTrue.value =
                                true;
                            GameVariables.gameInformation.hasVoted.value = true;
                            socketService.sendJson({
                              "type": "validateOrNot",
                              "roomCode":
                                  GameVariables.gameInformation.roomCode.value,
                              "token":
                                  GameVariables.generalInformation.token.value,
                              "isAnswerOK": true,
                            });
                          },
                          onRefuse: () {
                            print('Le mot a été refusé');
                            GameVariables.gameInformation.hasVotedTrue.value =
                                false;
                            GameVariables.gameInformation.hasVoted.value = true;
                            socketService.sendJson({
                              "type": "validateOrNot",
                              "roomCode":
                                  GameVariables.gameInformation.roomCode.value,
                              "token":
                                  GameVariables.generalInformation.token.value,
                              "isAnswerOK": false,
                            });
                          },
                          context: context,
                        );
                      }
                      return ValueListenableBuilder<bool>(
                        valueListenable:
                            GameVariables.gameInformation.hasVotedTrue,
                        builder: (context, hasVotedTrue, child) {
                          if (!hasVotedTrue) {
                            return _buildButtonLayout(
                              isWideEnough: isWideEnough,
                              validateColor: context.mutedColor,
                              refuseColor: context.dangerColor,
                              onValidate: null, // Grisé
                              onRefuse: () {}, // Sélectionné
                              context: context,
                            );
                          }
                          return _buildButtonLayout(
                            isWideEnough: isWideEnough,
                            validateColor: context.successColor,
                            refuseColor: context.mutedColor,
                            onValidate: () {}, // Sélectionné
                            onRefuse: null, // Grisé
                            context: context,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // BOUTON POUR LE JOUEUR ACTIF
  // =====================================================
  Widget _buildActivePlayerButton(BuildContext context) {
    if (GameVariables.gameInformation.isEliminated.value == true) {
      return SizedBox.shrink();
    } else {
      return ValueListenableBuilder<bool>(
        valueListenable: GameVariables.gameInformation.isAnswerValidate,
        builder: (context, isAnswerValidate, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAnswerValidate
                    ? null
                    : () {
                        final timestampDebut = GameVariables
                            .gameInformation
                            .timerStartTimestamp
                            .value;
                        final tempsTotal =
                            GameVariables.gameInformation.myTotalTimeLeft.value;

                        if (timestampDebut == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Erreur : timer non démarré"),
                            ),
                          );
                          return;
                        }
                        ;

                        final maintenant =
                            DateTime.now().millisecondsSinceEpoch;
                        final tempsEcoule = maintenant - timestampDebut;
                        int tempsRestant = tempsTotal - tempsEcoule;

                        if (tempsRestant < 0) tempsRestant = 0;

                        TimerManager.stopCountdown();

                        socketService.sendJson({
                          "type": "sendAnswer",
                          "roomCode":
                              GameVariables.gameInformation.roomCode.value,
                          "token": GameVariables.generalInformation.token.value,
                          "timeRemaining": tempsRestant,
                        });

                        print("Réponse validée par le joueur actif");

                        socketService.sendJson({
                          "type": "validateOrNot",
                          "roomCode":
                              GameVariables.gameInformation.roomCode.value,
                          "token": GameVariables.generalInformation.token.value,
                          "isAnswerOK": true,
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnswerValidate
                      ? context.mutedColor
                      : context.successColor,
                  foregroundColor: context.buttonTextColor,
                  disabledBackgroundColor: context.mutedColor,
                  disabledForegroundColor: context.buttonTextColor.withOpacity(
                    0.6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: isAnswerValidate ? 0 : 3,
                ),
                child: Text(
                  isAnswerValidate
                      ? "En attente des autres..."
                      : "Valider mon tour",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // =====================================================
  // LAYOUT RESPONSIVE DES BOUTONS (Row ou Column)
  // =====================================================
  Widget _buildButtonLayout({
    required bool isWideEnough,
    required Color validateColor,
    required Color refuseColor,
    required VoidCallback? onValidate,
    required VoidCallback? onRefuse,
    required BuildContext context,
  }) {
    final validateButton = ElevatedButton(
      onPressed: onValidate,
      style: ElevatedButton.styleFrom(
        backgroundColor: validateColor,
        foregroundColor: context.buttonTextColor,
        disabledBackgroundColor: context.mutedColor.withOpacity(0.15),
        disabledForegroundColor: context.mutedColor,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: onValidate == null || validateColor == context.mutedColor ? 0 : 3,
      ),
      child: const Text('Valider', style: TextStyle(fontSize: 32)),
    );

    final refuseButton = ElevatedButton(
      onPressed: onRefuse,
      style: ElevatedButton.styleFrom(
        backgroundColor: refuseColor,
        foregroundColor: context.buttonTextColor,
        disabledBackgroundColor: context.mutedColor.withOpacity(0.15),
        disabledForegroundColor: context.mutedColor,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: onRefuse == null || refuseColor == context.mutedColor ? 0 : 3,
      ),
      child: const Text('Refuser', style: TextStyle(fontSize: 32)),
    );

    // Mode large : côte à côte
    if (isWideEnough) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: validateButton,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: refuseButton,
            ),
          ),
        ],
      );
    }

    // Mode étroit : l'un en dessous de l'autre
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: validateButton,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: refuseButton,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // SIDEBAR STATS DRAWER
  // =====================================================
  Widget _buildStatsDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: context.backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.leaderboard, color: context.primaryColor, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    "Statistiques",
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Carte des paramètres (lecture seule)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: context.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        "Paramètres de la partie",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Temps total : ${(GameVariables.gameParameters.maxTime.value / 1000).round()} s",
                    style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                  ),
                  Text(
                    "• Vote des éliminés : ${GameVariables.gameParameters.canEliminatedPlayersVote.value ? 'Oui' : 'Non'}",
                    style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                  ),
                  Text(
                    "• Ordre de passage : ${GameVariables.gameParameters.randomizeOrder.value ? 'Aléatoire' : 'Défaut'}",
                    style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),

            const Divider(),
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: GameVariables.gameInformation.playersStatsList,
                builder: (context, statsList, _) {
                  if (statsList.isEmpty) {
                    return Center(
                      child: Text(
                        "Aucune donnée disponible",
                        style: TextStyle(color: context.mutedColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: statsList.length,
                    itemBuilder: (context, index) {
                      final player = statsList[index];
                      final pseudo = player['pseudo'] as String;
                      final timeLeftMs = player['timeLeft'] as int;
                      final timeLeftSec = (timeLeftMs / 1000).ceil();
                      final isEliminated = player['isEliminated'] == true;
                      final malusMs = player['malus'] as int;
                      final malusSec = (malusMs / 1000).toStringAsFixed(0);
                      final score = player['score'] as int;

                      final isCurrentTurnPlayer = pseudo == GameVariables.gameInformation.currentPlayerPseudo.value;

                      return Card(
                        color: isEliminated
                            ? context.mutedColor.withOpacity(0.1)
                            : (isCurrentTurnPlayer
                                ? context.primaryColor.withOpacity(0.12)
                                : context.surfaceColor),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isEliminated
                                ? context.mutedColor.withOpacity(0.2)
                                : (isCurrentTurnPlayer
                                    ? context.primaryColor
                                    : context.borderColor),
                            width: isCurrentTurnPlayer ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pseudo,
                                    style: TextStyle(
                                      color: isEliminated
                                          ? context.mutedColor
                                          : (isCurrentTurnPlayer ? context.primaryColor : context.textColor),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      decoration: isEliminated ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  if (isEliminated)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.mutedColor.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        formatPlayerStatusLabel(
                                          isCurrentTurnPlayer: isCurrentTurnPlayer,
                                          isEliminated: isEliminated,
                                        ),
                                        style: TextStyle(color: context.mutedColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCurrentTurnPlayer
                                            ? context.primaryColor.withOpacity(0.2)
                                            : context.successColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        formatPlayerStatusLabel(
                                          isCurrentTurnPlayer: isCurrentTurnPlayer,
                                          isEliminated: isEliminated,
                                        ),
                                        style: TextStyle(
                                          color: isCurrentTurnPlayer ? context.primaryColor : context.successColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 16, color: context.mutedColor),
                                      const SizedBox(width: 4),
                                      if (isCurrentTurnPlayer && !isEliminated)
                                        ValueListenableBuilder<int>(
                                          valueListenable: GameVariables.gameInformation.currentTimeLeft,
                                          builder: (context, timeLeft, _) {
                                            final currentSec = (timeLeft / 1000).ceil();
                                            final safeSec = currentSec < 0 ? 0 : currentSec;
                                            return Text(
                                              "${safeSec}s restants",
                                              style: TextStyle(
                                                color: timeLeft < 10000 ? context.dangerColor : context.textSecondaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        )
                                      else
                                        Text(
                                          isEliminated ? "0s" : "${timeLeftSec}s restants",
                                          style: TextStyle(
                                            color: isEliminated
                                                ? context.mutedColor
                                                : (timeLeftMs < 10000
                                                    ? context.dangerColor
                                                    : context.textSecondaryColor),
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (malusMs > 0)
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, size: 16, color: isEliminated ? context.mutedColor : context.warningColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Malus: ${malusSec}s",
                                          style: TextStyle(
                                            color: isEliminated ? context.mutedColor : context.warningColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // INLINE STATS LIST (SHOWN WHEN NOT OUR TURN)
  // =====================================================
  Widget _buildInlineStatsList(BuildContext context) {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: context.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "État de la partie",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: GameVariables.gameInformation.playersStatsList,
              builder: (context, statsList, _) {
                if (statsList.isEmpty) {
                  return const Center(child: Text("Aucune statistique"));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: statsList.length,
                  itemBuilder: (context, index) {
                    final player = statsList[index];
                    final pseudo = player['pseudo'] as String;
                    final timeLeftMs = player['timeLeft'] as int;
                    final isEliminated = player['isEliminated'] == true;
                    final score = player['score'] as int;

                    final isCurrentTurnPlayer = pseudo == GameVariables.gameInformation.currentPlayerPseudo.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrentTurnPlayer
                            ? context.primaryColor.withOpacity(0.08)
                            : (isEliminated
                                ? context.mutedColor.withOpacity(0.05)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentTurnPlayer
                              ? context.primaryColor.withOpacity(0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrentTurnPlayer
                                  ? context.primaryColor
                                  : context.mutedColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                color: isCurrentTurnPlayer ? Colors.white : context.textSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pseudo,
                              style: TextStyle(
                                color: isEliminated
                                    ? context.mutedColor
                                    : (isCurrentTurnPlayer ? context.primaryColor : context.textColor),
                                fontWeight: isCurrentTurnPlayer ? FontWeight.bold : FontWeight.normal,
                                decoration: isEliminated ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (isEliminated)
                            Text(
                              formatPlayerStatusLabel(
                                isCurrentTurnPlayer: isCurrentTurnPlayer,
                                isEliminated: isEliminated,
                              ),
                              style: TextStyle(color: context.mutedColor, fontSize: 12, fontWeight: FontWeight.bold),
                            )
                          else if (isCurrentTurnPlayer)
                            ValueListenableBuilder<int>(
                              valueListenable: GameVariables.gameInformation.currentTimeLeft,
                              builder: (context, timeLeft, _) {
                                final currentSec = (timeLeft / 1000).ceil();
                                final safeSec = currentSec < 0 ? 0 : currentSec;
                                return Text(
                                  "${safeSec}s",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: timeLeft < 10000 ? context.dangerColor : context.textColor,
                                  ),
                                );
                              },
                            )
                          else
                            Text(
                              "${(timeLeftMs / 1000).ceil()}s",
                              style: TextStyle(color: context.textSecondaryColor),
                            ),
                          const SizedBox(width: 10),
                          Text(
                            formatPlayerStatusLabel(
                              isCurrentTurnPlayer: isCurrentTurnPlayer,
                              isEliminated: isEliminated,
                            ),
                            style: TextStyle(
                              color: isEliminated ? context.mutedColor : context.successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
