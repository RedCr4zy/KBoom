// lib/pages/results_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/services/socket_service.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> with TickerProviderStateMixin {
  int _revealedCount = 0; // Number of positions revealed so far
  List<MapEntry<String, dynamic>> _sortedPlayers = [];
  Timer? _revealTimer;
  bool _isFinishedRevealing = false;

  @override
  void initState() {
    super.initState();
    _prepareSortedPlayers();
    _startProgressiveReveal();
  }

  void _prepareSortedPlayers() {
    final stats = GameVariables.gameInformation.endGameStats.value;
    final entries = stats.entries.toList();

    // Sort strictly by elimination status & rank in stats
    entries.sort((a, b) {
      final isElimA = a.value['isEliminated'] == true;
      final isElimB = b.value['isEliminated'] == true;
      if (isElimA != isElimB) {
        return isElimA ? 1 : -1;
      }
      final malusA = a.value['totalMalus'] as int? ?? 0;
      final malusB = b.value['totalMalus'] as int? ?? 0;
      return malusA.compareTo(malusB);
    });

    _sortedPlayers = entries;
  }

  void _startProgressiveReveal() {
    if (_sortedPlayers.isEmpty) return;

    // We reveal from bottom rank (last place) to 1st place with 1.2s delay
    _revealTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_revealedCount < _sortedPlayers.length) {
          _revealedCount++;
        } else {
          _isFinishedRevealing = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  // =======================
  // REPLAY GAME CALL
  // =======================
  void _replayGame() {
    socketService.sendJson({
      "type": "replayGame",
      "roomCode": GameVariables.gameInformation.roomCode.value,
      "token": GameVariables.generalInformation.token.value,
    });
  }

  // =======================
  // LEAVE ROOM CALL
  // =======================
  void _leaveRoom() {
    socketService.sendJson({
      "type": "leaveRoom",
      "roomCode": GameVariables.gameInformation.roomCode.value,
      "token": GameVariables.generalInformation.token.value,
    });

    // Cleanup local info
    GameVariables.gameInformation.roomCode.value = null;
    GameVariables.gameInformation.isMaster.value = false;
    GameVariables.gameInformation.isGameStarted.value = false;
    GameVariables.gameInformation.isGameFinished.value = false;

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GameVariables.generalInformation.isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: context.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // =======================
                // HEADER SECTION
                // =======================
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        "Résultats de la partie",
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!_isFinishedRevealing)
                        Text(
                          "Révélation du classement...",
                          style: TextStyle(
                            color: context.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          // =======================
                          // WINNER CELEBRATION
                          // =======================
                          if (_revealedCount >= _sortedPlayers.length && _sortedPlayers.isNotEmpty)
                            _buildWinnerBanner(context, _sortedPlayers.first),

                          const SizedBox(height: 16),

                          // =======================
                          // PODIUM SECTION
                          // =======================
                          if (_sortedPlayers.isNotEmpty)
                            _buildPodium(context, _sortedPlayers, _revealedCount),

                          const SizedBox(height: 24),

                          // =======================
                          // STATS LIST SECTION
                          // =======================
                          Text(
                            "Classement général",
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _sortedPlayers.length,
                            itemBuilder: (context, index) {
                              // Calculate index from bottom to reveal progressively
                              final reverseIndex = _sortedPlayers.length - 1 - index;
                              final isRevealed = index < _revealedCount;

                              if (!isRevealed) {
                                return Card(
                                  color: context.surfaceColor.withOpacity(0.4),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: context.borderColor.withOpacity(0.3)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: context.mutedColor.withOpacity(0.2),
                                          child: Text(
                                            "${index + 1}",
                                            style: TextStyle(color: context.mutedColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          "???",
                                          style: TextStyle(
                                            color: context.mutedColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.lock, color: context.mutedColor, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final entry = _sortedPlayers[index];
                              final pseudo = entry.key;
                              final totalMalusMs = entry.value['totalMalus'] as int? ?? 0;
                              final totalMalusSec = (totalMalusMs / 1000).toStringAsFixed(0);
                              final isEliminated = entry.value['isEliminated'] == true;

                              final refused = entry.value['refusedWords'] as int? ?? 0;
                              final wrongNo = entry.value['wrongNoVotes'] as int? ?? 0;
                              final wrongYes = entry.value['wrongYesVotes'] as int? ?? 0;

                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 600),
                                opacity: isRevealed ? 1.0 : 0.0,
                                child: Card(
                                  color: isEliminated 
                                      ? context.mutedColor.withOpacity(0.1) 
                                      : context.surfaceColor,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isEliminated 
                                          ? context.mutedColor.withOpacity(0.3) 
                                          : (index == 0 ? Colors.amber : context.borderColor),
                                      width: index == 0 ? 2 : 1,
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    backgroundColor: Colors.transparent,
                                    collapsedBackgroundColor: Colors.transparent,
                                    title: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: index == 0
                                              ? Colors.amber
                                              : (isEliminated
                                                  ? context.mutedColor.withOpacity(0.2)
                                                  : context.primaryColor.withOpacity(0.15)),
                                          child: Text(
                                            "${index + 1}",
                                            style: TextStyle(
                                              color: index == 0
                                                  ? Colors.black
                                                  : (isEliminated ? context.mutedColor : context.primaryColor),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                pseudo,
                                                style: TextStyle(
                                                  color: isEliminated
                                                      ? context.mutedColor
                                                      : context.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  decoration: isEliminated
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                              ),
                                              if (isEliminated) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: context.mutedColor.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    "Éliminé",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: context.mutedColor,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(left: 48.0, top: 4.0),
                                      child: Text(
                                        isEliminated
                                            ? "Éliminé - Pénalité malus : ${totalMalusSec}s"
                                            : "Temps restant préservé - Malus : ${totalMalusSec}s",
                                        style: TextStyle(
                                          color: isEliminated
                                              ? context.mutedColor
                                              : (totalMalusMs > 0 ? context.warningColor : context.successColor),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 64.0, right: 20.0, bottom: 16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Divider(),
                                            _buildDetailRow("Mots refusés :", refused.toString()),
                                            const SizedBox(height: 4),
                                            _buildDetailRow("Votes 'NON' incorrects :", wrongNo.toString()),
                                            const SizedBox(height: 4),
                                            _buildDetailRow("Votes 'OUI' incorrects :", wrongYes.toString()),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // =======================
                // BOTTOM ACTIONS SECTION
                // =======================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border(top: BorderSide(color: context.borderColor)),
                  ),
                  child: Column(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: GameVariables.gameInformation.isMaster,
                        builder: (context, isMaster, _) {
                          if (isMaster) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showFeedbackDialog(context, isReplayAction: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  "Rejouer la partie",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "En attente du Host pour rejouer...",
                                style: TextStyle(
                                  color: context.mutedColor,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showFeedbackDialog(context, isReplayAction: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.dangerColor,
                            side: BorderSide(color: context.dangerColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Quitter le salon",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinnerBanner(BuildContext context, MapEntry<String, dynamic> winner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.amber, blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 50, color: Colors.white),
          const SizedBox(height: 8),
          const Text(
            "GRAND VAINQUEUR !",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text(
            winner.key,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // =======================
  // BUILD PODIUM HELPER
  // =======================
  Widget _buildPodium(BuildContext context, List<MapEntry<String, dynamic>> players, int revealedCount) {
    final goldPlayer = (players.isNotEmpty && revealedCount >= players.length) ? players[0] : null;
    final silverPlayer = (players.length > 1 && revealedCount >= (players.length - 1)) ? players[1] : null;
    final bronzePlayer = (players.length > 2 && revealedCount >= (players.length - 2)) ? players[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver)
          if (silverPlayer != null)
            _buildPodiumStep(
              context,
              name: silverPlayer.key,
              place: "2",
              stepHeight: 100,
              gradient: const LinearGradient(
                colors: [Color(0xFFBDC3C7), Color(0xFF95A5A6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),

          // 1st Place (Gold)
          if (goldPlayer != null)
            _buildPodiumStep(
              context,
              name: goldPlayer.key,
              place: "1",
              stepHeight: 140,
              gradient: const LinearGradient(
                colors: [Color(0xFFF1C40F), Color(0xFFF39C12)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),

          // 3rd Place (Bronze)
          if (bronzePlayer != null)
            _buildPodiumStep(
              context,
              name: bronzePlayer.key,
              place: "3",
              stepHeight: 75,
              gradient: const LinearGradient(
                colors: [Color(0xFFD35400), Color(0xFFE67E22)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep(
    BuildContext context, {
    required String name,
    required String place,
    required double stepHeight,
    required Gradient gradient,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: stepHeight,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Text(
                place,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: GameVariables.generalInformation.isDarkMode.value ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // ÉCRAN DE FEEDBACK DE FIN DE PARTIE
  // =====================================================
  void _showFeedbackDialog(BuildContext context, {required bool isReplayAction}) {
    int rating = 5;
    String? selectedTop;
    String? selectedFlop;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border.all(color: context.borderColor),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.mutedColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "Votre avis sur la partie",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Note Globale (Étoiles)
                    Text(
                      "Note globale",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starIndex = index + 1;
                          return IconButton(
                            iconSize: 40,
                            icon: Icon(
                              starIndex <= rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                rating = starIndex;
                              });
                            },
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Le TOP (Point positif)
                    Text(
                      "Le Top (Point positif)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        "Durée de la partie parfaite",
                        "Malus équilibrés",
                        "Rythme intense"
                      ].map((topText) {
                        final isSelected = selectedTop == topText;
                        return ChoiceChip(
                          label: Text(topText),
                          selected: isSelected,
                          selectedColor: context.primaryColor.withOpacity(0.2),
                          checkmarkColor: context.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? context.primaryColor : context.textSecondaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setStateDialog(() {
                              selectedTop = selected ? topText : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Le FLOP (Point négatif)
                    Text(
                      "Le Flop (Point négatif)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        "Partie trop longue",
                        "Partie trop courte",
                        "Malus trop sévères",
                        "Pas assez de temps pour répondre"
                      ].map((flopText) {
                        final isSelected = selectedFlop == flopText;
                        return ChoiceChip(
                          label: Text(flopText),
                          selected: isSelected,
                          selectedColor: context.dangerColor.withOpacity(0.2),
                          checkmarkColor: context.dangerColor,
                          labelStyle: TextStyle(
                            color: isSelected ? context.dangerColor : context.textSecondaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setStateDialog(() {
                              selectedFlop = selected ? flopText : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Bouton d'envoi
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          socketService.sendJson({
                            "type": "submitFeedback",
                            "roomCode": GameVariables.gameInformation.roomCode.value,
                            "rating": rating,
                            "top": selectedTop,
                            "flop": selectedFlop,
                          });

                          Navigator.pop(context);

                          if (isReplayAction) {
                            _replayGame();
                          } else {
                            _leaveRoom();
                          }
                        },
                        child: Text(
                          isReplayAction ? "Envoyer et Rejouer" : "Envoyer et Quitter",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
