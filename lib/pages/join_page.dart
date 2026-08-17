import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/pages/waiting.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/game_variable.dart';

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isJoining = false;

  Future<void> _joinRoom(String pseudo) async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("room_code_empty".tr),
          backgroundColor: context.dangerColor,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    GameVariables.code.value = input;
    GameVariables.generalInformation.pseudo.value = pseudo;

    socketService.sendJson({
      "type": "joinRoom",
      "roomCode": input,
      "pseudo": pseudo,
      "token": GameVariables.generalInformation.token.value,
      "avatarData": GameVariables.generalInformation.avatarData.value,
    });

    // Simuler délai réponse serveur
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
                fontWeight: FontWeight.bold,
              ),
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
                    hintStyle: TextStyle(color: context.mutedColor),
                    counterText: '',
                    errorText: errorText,
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: context.borderColor)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: context.primaryColor, width: 2)),
                  ),
                  style: TextStyle(color: context.textColor),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _validatePseudo(setStateDialog, value),
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
                child: Text("cancel".tr, style: TextStyle(color: context.mutedColor)),
              ),
              ElevatedButton(
                onPressed: () => _validatePseudo(setStateDialog, pseudoController.text),
                style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
                child: Text("validate".tr, style: TextStyle(color: context.buttonTextColor)),
              ),
            ],
          );
        });
      },
    );
  }

  void _validatePseudo(void Function(void Function()) setStateDialog, String value) {
    final trimmed = value.trim();
    String? error;
    if (trimmed.isEmpty) {
      error = "pseudo_empty_error".tr;
    }
    else if (trimmed.length < 3) {
      error = "pseudo_short_error".tr;
    }

    if (error != null) {
      setStateDialog(() => {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: context.warningColor),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bouton retour
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    color: context.textColor,
                    iconSize: 28,
                  ),
                ),
                const SizedBox(height: 60),
                // Contenu central
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "join_title".tr,
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 30),
                        // Input code
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: context.borderColor),
                              ),
                              hintText: 'room_code_hint'.tr,
                              hintStyle: TextStyle(color: context.textSecondaryColor),
                              filled: true,
                              fillColor: context.surfaceColor,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            style: TextStyle(color: context.textColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Bouton Join
                        ElevatedButton(
                          onPressed: _isJoining
                              ? null
                              : () async {
                            if (GameVariables.generalInformation.pseudo.value?.isEmpty ?? true) {
                              final pseudo = await _showPseudoDialog(context);
                              if (pseudo != null) await _joinRoom(pseudo);
                            } else {
                              await _joinRoom(GameVariables.generalInformation.pseudo.value!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            _isJoining ? context.mutedColor : context.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isJoining
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            "join_btn".tr,
                            style: TextStyle(
                                fontSize: 28,
                                fontFamily: 'Poppins',
                                color: context.buttonTextColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
