import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/models/avatar_model.dart';
import 'package:kboom/pages/parameters.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/widgets/avatar_widget.dart';
import 'package:kboom/widgets/friends_list_sheet.dart';

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  late final StreamSubscription<Map<String, dynamic>> _suggestedSubscription;
  VoidCallback? _playerListListener;
  int _lastPlayerCount = -1;

  @override
  void initState() {
    super.initState();

    _suggestedSubscription = socketService.suggestedConfigStream.listen((config) {
      // The socket service updates the shared game parameters directly.
    });

    _playerListListener = () {
      if (mounted && GameVariables.gameInformation.isMaster.value == true) {
        final count = socketService.playersNotifier.value.length;
        if (count > 0 && count != _lastPlayerCount) {
          _lastPlayerCount = count;
          socketService.sendJson({
            'type': 'getSuggestedConfig',
            'playerCount': count,
          });
        }
      }
    };

    socketService.playersNotifier.addListener(_playerListListener!);

    Future.microtask(() {
      if (GameVariables.gameInformation.isMaster.value == true) {
        final count = socketService.playersNotifier.value.length;
        _lastPlayerCount = count > 0 ? count : 2;
        socketService.sendJson({
          'type': 'getSuggestedConfig',
          'playerCount': _lastPlayerCount,
        });
      }
    });
  }

  @override
  void dispose() {
    _suggestedSubscription.cancel();
    if (_playerListListener != null) {
      socketService.playersNotifier.removeListener(_playerListListener!);
    }
    super.dispose();
  }

  Future<bool> _confirmLeaveRoom() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Quitter la partie ?',
            style: TextStyle(color: context.textColor),
          ),
          content: Text(
            'Voulez-vous vraiment quitter la salle ?',
            style: TextStyle(color: context.textSecondaryColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Annuler',
                style: TextStyle(color: context.textSecondaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.dangerColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true) {
      final roomCode = GameVariables.gameInformation.roomCode.value;

      socketService.sendJson({
        'type': 'leaveRoom',
        'roomCode': roomCode,
        'token': GameVariables.generalInformation.token.value,
      });

      GameVariables.gameInformation.roomCode.value = null;
      GameVariables.gameInformation.isMaster.value = false;
      GameVariables.gameInformation.isGameStarted.value = false;
      return true;
    }

    return false;
  }

  Future<Map<String, dynamic>?> _showParametersDialog(
    BuildContext context,
  ) async {
    socketService.sendJson({
      'type': 'getSuggestedConfig',
      'playerCount': socketService.playersNotifier.value.length,
    });

    double currentSliderValue = GameVariables.gameParameters.maxTime.value / 1000;
    bool light = GameVariables.gameParameters.canEliminatedPlayersVote.value;
    bool randomize = GameVariables.gameParameters.randomizeOrder.value;
    bool useAi = GameVariables.gameParameters.useAiConfig.value;

    StreamSubscription<Map<String, dynamic>>? suggestedDialogSub;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      barrierColor: context.modalOverlayColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            suggestedDialogSub ??= socketService.suggestedConfigStream.listen((config) {
              setStateDialog(() {
                currentSliderValue = (config['maxTime'] ?? 60000) / 1000.0;
                light = config['canEliminatedPlayersVote'] == true;
                randomize = config['randomizeOrder'] == true;
              });
            });

            return AlertDialog(
              backgroundColor: context.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.borderColor),
              ),
              title: Text(
                'Paramètres de la partie',
                style: TextStyle(
                  color: context.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recommandations IA',
                              style: TextStyle(
                                color: context.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Générer les meilleurs réglages au lancement',
                              style: TextStyle(color: context.mutedColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: useAi,
                        activeColor: context.primaryColor,
                        onChanged: (val) {
                          setStateDialog(() => useAi = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: useAi ? 0.4 : 1.0,
                    child: AbsorbPointer(
                      absorbing: useAi,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temps total par joueur : ${currentSliderValue.round()} secondes',
                            style: TextStyle(color: context.mutedColor, fontSize: 12),
                          ),
                          Slider(
                            value: currentSliderValue,
                            max: 120,
                            min: 5,
                            activeColor: context.primaryColor,
                            inactiveColor: context.mutedColor,
                            onChanged: (double value) {
                              setStateDialog(() {
                                currentSliderValue = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Joueurs éliminés peuvent voter',
                                  style: TextStyle(color: context.mutedColor, fontSize: 12),
                                ),
                              ),
                              Switch(
                                value: light,
                                activeColor: context.primaryColor,
                                onChanged: (bool value) {
                                  setStateDialog(() {
                                    light = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Ordre de passage aléatoire',
                                  style: TextStyle(color: context.mutedColor, fontSize: 12),
                                ),
                              ),
                              Switch(
                                value: randomize,
                                activeColor: context.primaryColor,
                                onChanged: (bool value) {
                                  setStateDialog(() {
                                    randomize = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: context.mutedColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'maxTime': (currentSliderValue * 1000).toInt(),
                      'canEliminatedPlayersVote': light,
                      'randomizeOrder': randomize,
                      'useAiConfig': useAi,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                  ),
                  child: Text(
                    'Valider',
                    style: TextStyle(color: context.buttonTextColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    suggestedDialogSub?.cancel();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Code de la partie',
                          style: TextStyle(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<String?>(
                          valueListenable: GameVariables.gameInformation.roomCode,
                          builder: (context, code, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  code ?? '----',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryColor,
                                    letterSpacing: 6,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  color: context.primaryColor,
                                  onPressed: code == null
                                      ? null
                                      : () {
                                          Clipboard.setData(
                                            ClipboardData(text: code),
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Code copié !'),
                                              backgroundColor: context.successColor,
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paramètres de la partie',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                                fontSize: 16,
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: GameVariables.gameInformation.isMaster,
                              builder: (context, isMaster, _) {
                                if (!isMaster) return const SizedBox.shrink();
                                return IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(Icons.edit, color: context.primaryColor, size: 20),
                                  onPressed: () async {
                                    final results = await _showParametersDialog(context);
                                    if (results != null) {
                                      socketService.sendJson({
                                        'type': 'updateRoomConfig',
                                        'roomCode': GameVariables.gameInformation.roomCode.value,
                                        'maxTime': results['maxTime'],
                                        'canEliminatedPlayersVote': results['canEliminatedPlayersVote'],
                                        'randomizeOrder': results['randomizeOrder'],
                                        'useAiConfig': results['useAiConfig'],
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 85,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mode IA',
                                    style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: GameVariables.gameParameters.useAiConfig,
                                    builder: (context, val, _) => Text(
                                      val ? 'Oui (IA)' : 'Manuel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: val ? context.primaryColor : context.textColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 85,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Temps/joueur',
                                    style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  ValueListenableBuilder<int>(
                                    valueListenable: GameVariables.gameParameters.maxTime,
                                    builder: (context, val, _) => Text(
                                      '${(val / 1000).round()} s',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 85,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vote éliminés',
                                    style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: GameVariables.gameParameters.canEliminatedPlayersVote,
                                    builder: (context, val, _) => Text(
                                      val ? 'Oui' : 'Non',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ordre',
                                    style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: GameVariables.gameParameters.randomizeOrder,
                                    builder: (context, val, _) => Text(
                                      val ? 'Aléatoire' : 'Défaut',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: context.textColor, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: context.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Joueurs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<List<Map<String, dynamic>>>(
                          valueListenable: socketService.playersNotifier,
                          builder: (context, players, _) {
                            return Text(
                              '${players.length}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: socketService.playersNotifier,
                      builder: (context, players, _) {
                        if (players.isEmpty) {
                          return Center(
                            child: Text(
                              'En attente de joueurs...',
                              style: TextStyle(color: context.textSecondaryColor),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final pseudo = (player['pseudo'] ?? '').toString();
                            final isOffline = player['isOffline'] == true;
                            final isReady = player['isReady'] == true;
                            final isHost = player['isMaster'] == true;
                            final isYou = pseudo == GameVariables.generalInformation.pseudo.value;

                            //final rawAvatar = player['avatarData'];
                            final rawAvatar = GameVariables.generalInformation.avatarData.value;
                            print('Avatar widget: $AvatarWidget');
                            print('rawAvatar: $rawAvatar');
                            AvatarData playerAvatar;
                            if (rawAvatar is Map<String, dynamic>) {
                              playerAvatar = AvatarData.fromMap(rawAvatar);
                            } else if (rawAvatar is Map) {
                              playerAvatar = AvatarData.fromMap(Map<String, dynamic>.from(rawAvatar));
                            } else {
                              playerAvatar = const AvatarData();
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isYou ? context.primaryColor : context.borderColor,
                                  width: isYou ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AvatarWidget(
                                    avatarData: playerAvatar,
                                    size: 48,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              pseudo,
                                              style: TextStyle(
                                                fontWeight: isYou ? FontWeight.bold : FontWeight.w600,
                                                fontSize: 16,
                                                color: isOffline ? context.mutedColor : context.textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (isYou)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: context.primaryColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Vous',
                                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (isHost)
                                              Container(
                                                margin: const EdgeInsets.only(right: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: context.warningColor,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Hôte',
                                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            if (!isHost)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isReady
                                                      ? context.successColor.withOpacity(0.2)
                                                      : context.mutedColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isReady ? '✓ Prêt' : 'Pas prêt',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isReady ? context.successColor : context.mutedColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            if (isOffline)
                                              Container(
                                                margin: const EdgeInsets.only(left: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: context.dangerColor.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Déconnecté',
                                                  style: TextStyle(fontSize: 10, color: context.dangerColor, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
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
                  ValueListenableBuilder<bool>(
                    valueListenable: GameVariables.gameInformation.isMaster,
                    builder: (context, isMaster, _) {
                      return ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: socketService.playersNotifier,
                        builder: (context, players, _) {
                          final nonHostPlayers = players.where((p) => p['isMaster'] != true).toList();
                          final readyCount = nonHostPlayers.where((player) => player['isReady'] == true).length;
                          final allReady = nonHostPlayers.isNotEmpty && readyCount == nonHostPlayers.length;
                          final canStart = players.length >= 2 && allReady;
                          final mine = players.where((player) => player['token'] == GameVariables.generalInformation.token.value).toList();
                          final amReady = mine.isNotEmpty && mine.first['isReady'] == true;

                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: ElevatedButton(
                              onPressed: isMaster
                                  ? (canStart
                                      ? () {
                                          socketService.sendJson({
                                            'type': 'startGame',
                                            'roomCode': GameVariables.gameInformation.roomCode.value,
                                            'maxTime': GameVariables.gameParameters.maxTime.value,
                                            'canEliminatedPlayersVote': GameVariables.gameParameters.canEliminatedPlayersVote.value,
                                            'randomizeOrder': GameVariables.gameParameters.randomizeOrder.value,
                                            'useAiConfig': GameVariables.gameParameters.useAiConfig.value,
                                          });
                                        }
                                      : null)
                                  : () => socketService.sendJson({
                                        'type': 'setReady',
                                        'roomCode': GameVariables.gameInformation.roomCode.value,
                                        'isReady': !amReady,
                                      }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isMaster
                                    ? (canStart ? context.successColor : context.mutedColor)
                                    : (amReady ? context.warningColor : context.successColor),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isMaster
                                    ? (players.length < 2
                                        ? 'En attente de plus de joueurs (min. 2)'
                                        : (canStart
                                            ? 'Lancer la partie'
                                            : 'En attente des joueurs prêts ($readyCount/${nonHostPlayers.length})'))
                                    : (amReady ? 'Annuler mon statut Prêt' : 'Je suis prêt !'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () async {
                    final canLeave = await _confirmLeaveRoom();
                    if (canLeave) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 48,
                child: IconButton(
                  icon: const Icon(Icons.people),
                  color: context.successColor,
                  onPressed: () {
                    FriendsListSheet.show(context);
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  color: context.textColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParametersPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
