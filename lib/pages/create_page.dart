import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/pages/waiting.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/game_variable.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  bool _isJoining = false;

  // =======================
  // GAME PARAMETERS VARIABLES
  // =======================
  bool _useAiConfigValue = false;
  double _timeSliderValue = 60.0;
  bool _canVoteValue = false;
  bool _randomizeOrderValue = false;

  late final StreamSubscription<Map<String, dynamic>> _suggestedSubscription;

  @override
  void initState() {
    super.initState();
    _suggestedSubscription = socketService.suggestedConfigStream.listen((config) {
      if (mounted) {
        setState(() {
          _timeSliderValue = (config['maxTime'] ?? 60000) / 1000.0;
          _canVoteValue = config['canEliminatedPlayersVote'] == true;
          _randomizeOrderValue = config['randomizeOrder'] == true;
        });
      }
    });

    // Request default suggestion for 4 players when create page loads
    socketService.sendJson({
      "type": "getSuggestedConfig",
      "playerCount": 4,
    });
  }

  @override
  void dispose() {
    _suggestedSubscription.cancel();
    super.dispose();
  }

  Future<void> _joinRoom(String pseudo) async {
    setState(() => _isJoining = true);

    GameVariables.generalInformation.pseudo.value = pseudo;

    final maxTimeVal = (_timeSliderValue * 1000).toInt();
    final canVoteVal = _canVoteValue;
    final randomizeVal = _randomizeOrderValue;
    final useAiVal = _useAiConfigValue;

    // Sauvegarde locale initiale
    GameVariables.gameParameters.maxTime.value = maxTimeVal;
    GameVariables.gameParameters.canEliminatedPlayersVote.value = canVoteVal;
    GameVariables.gameParameters.randomizeOrder.value = randomizeVal;
    GameVariables.gameParameters.useAiConfig.value = useAiVal;

    socketService.sendJson({
      "type": "createRoom",
      "pseudo": pseudo,
      "token": GameVariables.generalInformation.token.value,
      "avatarData": GameVariables.generalInformation.avatarData.value,
      "maxTime": maxTimeVal,
      "canEliminatedPlayersVote": canVoteVal,
      "randomizeOrder": randomizeVal,
      "useAiConfig": useAiVal,
    });

    // Attendre un peu pour simuler la réponse serveur
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isJoining = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WaitingPage()),
    );
  }

  Future<String?> _showPseudoDialog(BuildContext context) async {
    final TextEditingController pseudoController =
    TextEditingController(text: GameVariables.generalInformation.pseudo.value ?? '');
    String? errorText;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: context.modalOverlayColor,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: context.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.borderColor),
            ),
            title: Text(
              "pseudo_dialog_title".tr,
              style: TextStyle(
                  color: context.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pseudoController,
                  autofocus: true,
                  maxLength: 15,
                  decoration: InputDecoration(
                    hintText: "pseudo_hint".tr,
                    errorText: errorText,
                    counterText: '',
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: context.borderColor)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: context.primaryColor, width: 2)),
                  ),
                  style: TextStyle(color: context.textColor),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) =>
                      _validatePseudo(setStateDialog, value),
                ),
                const SizedBox(height: 8),
                Text(
                  "pseudo_warning".tr,
                  style: TextStyle(color: context.mutedColor, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("cancel".tr,
                    style: TextStyle(color: context.mutedColor)),
              ),
              ElevatedButton(
                onPressed: () =>
                    _validatePseudo(setStateDialog, pseudoController.text),
                style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor),
                child: Text("validate".tr,
                    style: TextStyle(color: context.buttonTextColor)),
              ),
            ],
          );
        });
      },
    );
  }

  void _validatePseudo(
      void Function(void Function()) setStateDialog, String value) {
    final trimmed = value.trim();
    String? error;
    if (trimmed.isEmpty) {
      error = "pseudo_empty_error".tr;
    } else if (trimmed.length < 3) {
      error = "pseudo_short_error".tr;
    }

    if (error != null) {
      setStateDialog(() => {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error), backgroundColor: context.warningColor),
      );
      return;
    }

    GameVariables.generalInformation.pseudo.value = trimmed;
    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GameVariables.generalInformation.isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: context.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================
                  // HAUT : Bouton retour aligné à gauche
                  // ========================================
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        context.surfaceColor,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ========================================
                  // MILIEU : Titre et paramètres
                  // ========================================
                  Center(
                    child: Text(
                      "create_title".tr,
                      style: TextStyle(
                        fontSize: 36,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Card(
                    color: context.surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Paramètres de la partie",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Interrupteur ON/OFF Recommandations IA
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Utiliser les paramètres IA",
                                      style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Génère les meilleurs réglages au lancement",
                                      style: TextStyle(
                                        color: context.mutedColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _useAiConfigValue,
                                activeColor: context.primaryColor,
                                onChanged: (bool val) {
                                  setState(() => _useAiConfigValue = val);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Zone de réglages manuels (grisée si IA active)
                          Opacity(
                            opacity: _useAiConfigValue ? 0.4 : 1.0,
                            child: AbsorbPointer(
                              absorbing: _useAiConfigValue,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Temps par joueur
                                  Text(
                                    "Temps total par joueur : ${_timeSliderValue.round()} secondes",
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Slider(
                                    value: _timeSliderValue,
                                    max: 120,
                                    min: 5,
                                    activeColor: context.primaryColor,
                                    inactiveColor: context.mutedColor.withOpacity(0.3),
                                    onChanged: (double value) {
                                      setState(() {
                                        _timeSliderValue = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Éliminés peuvent voter
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Les joueurs éliminés peuvent voter",
                                          style: TextStyle(
                                            color: context.textSecondaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: _canVoteValue,
                                        activeColor: context.primaryColor,
                                        onChanged: (bool value) {
                                          setState(() {
                                            _canVoteValue = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Ordre aléatoire
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Tirer l'ordre de passage au sort",
                                          style: TextStyle(
                                            color: context.textSecondaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: _randomizeOrderValue,
                                        activeColor: context.primaryColor,
                                        onChanged: (bool value) {
                                          setState(() {
                                            _randomizeOrderValue = value;
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
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ========================================
                  // BOUTON DE CRÉATION
                  // ========================================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isJoining
                          ? null
                          : () async {
                              if (GameVariables.generalInformation.pseudo.value?.isEmpty ??
                                  true) {
                                final pseudo = await _showPseudoDialog(context);
                                if (pseudo != null) {
                                  await _joinRoom(pseudo);
                                }
                              } else {
                                await _joinRoom(
                                    GameVariables.generalInformation.pseudo.value!);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "create_btn".tr,
                              style: TextStyle(
                                color: context.buttonTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}