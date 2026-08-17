import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/pages/avatar_custom_page.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/pages/login_page.dart';
import 'package:kboom/services/auth_socket_service.dart';

class ParametersPage extends StatefulWidget {
  const ParametersPage({super.key});

  @override
  State<ParametersPage> createState() => _ParametersPageState();
}

class _ParametersPageState extends State<ParametersPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Initialise le champ avec le pseudo actuel
    _controller.text = GameVariables.generalInformation.pseudo.value ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // Check if player is in a room and is ready
    final players = socketService.playersNotifier.value;
    final myToken = GameVariables.generalInformation.token.value;
    final mine = players.where((p) => p['token'] == myToken).toList();
    if (mine.isNotEmpty && mine.first['isReady'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez retirer votre état 'Prêt' pour modifier votre pseudo !"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _errorText = "Le pseudo ne peut pas être vide");
      return;
    }
    if (input == GameVariables.generalInformation.pseudo.value) {
      setState(() => _errorText = "Pseudo déjà choisi");
      return;
    }

    // Sauvegarde
    GameVariables.generalInformation.pseudo.value = input;
    setState(() => _errorText = null);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('saved_pseudo', input);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pseudo enregistré : $input'),
        backgroundColor: context.successColor,
        duration: const Duration(seconds: 2),
      ),
    );

    socketService.sendJson({
      'type': 'update',
      'token': GameVariables.generalInformation.token.value,
      'pseudo': GameVariables.generalInformation.pseudo.value,
      'avatarData': GameVariables.generalInformation.avatarData.value,
      'roomCode': GameVariables.gameInformation.roomCode.value,
    });
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: context.textColor,
                          size: 24,
                        ),
                      ),
                      Text(
                        'settings'.tr,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final newValue = !GameVariables.generalInformation.isDarkMode.value;
                          GameVariables.generalInformation.isDarkMode.value = newValue;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('is_dark_mode', newValue);
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: context.textColor,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ===== SECTION COMPTE GLOBAL =====
                  ValueListenableBuilder<String?>(
                    valueListenable: GameVariables.generalInformation.token,
                    builder: (context, tokenValue, _) {
                      final isLoggedIn = tokenValue != null && tokenValue.contains('.');

                      if (isLoggedIn) {
                        return Card(
                          color: context.surfaceColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Compte Global",
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Connecté en tant que : ${GameVariables.generalInformation.pseudo.value ?? ''}",
                                  style: TextStyle(color: context.textColor, fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      // Logout: Clear preferences and variables
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.remove('auth_token');
                                      GameVariables.generalInformation.token.value = null;
                                      GameVariables.generalInformation.pseudo.value = null;

                                      // Reconnect game socket in Guest mode
                                      _reconnectAsGuest();

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Déconnecté avec succès"),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: context.dangerColor,
                                      side: BorderSide(color: context.dangerColor),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Se déconnecter",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Card(
                          color: context.surfaceColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Compte Global (Optionnel)",
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Créez un compte pour débloquer le système de progression par niveau, la personnalisation d'avatar et le système d'amis en temps réel !",
                                  style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Se connecter / S'inscrire",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // ===== SECTION PSEUDO =====
                  Card(
                    color: context.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'pseudo'.tr,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Entrez votre pseudo",
                              errorText: _errorText,
                              hintStyle: TextStyle(color: context.mutedColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.primaryColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: context.backgroundColor,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            style: TextStyle(color: context.textColor),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                "save".tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== SECTION LANGUE =====
                  Card(
                    color: context.surfaceColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'language_label'.tr,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: context.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: Get.locale?.languageCode ?? 'fr',
                                isExpanded: true,
                                dropdownColor: context.surfaceColor,
                                style: TextStyle(color: context.textColor, fontSize: 16),
                                icon: Icon(Icons.arrow_drop_down, color: context.textColor),
                                items: [
                                  DropdownMenuItem(
                                    value: 'fr',
                                    child: Text('language_fr'.tr),
                                  ),
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text('language_en'.tr),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value != null) {
                                    // Changer la langue locale
                                    Get.updateLocale(Locale(value));
                                    
                                    // Sauvegarder dans SharedPreferences
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString('language_code', value);

                                    // Notification
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('lang_changed'.tr),
                                        backgroundColor: context.successColor,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== SECTION PERSONNALISATION D'AVATAR =====
                  ValueListenableBuilder<String?>(
                    valueListenable: GameVariables.generalInformation.token,
                    builder: (context, tokenValue, _) {
                      if (tokenValue != null && tokenValue.contains('.')) {
                        return Card(
                          color: context.surfaceColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AvatarCustomPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.face, color: context.primaryColor, size: 28),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Personnaliser mon avatar",
                                          style: TextStyle(
                                            color: context.textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Changez l'apparence de votre personnage",
                                          style: TextStyle(
                                            color: context.textSecondaryColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: context.mutedColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 32),

                  // =======================
                  // SECTION RULES (RÈGLES)
                  // =======================
                  _buildRulesCard(context),
                  const SizedBox(height: 24),

                  // =======================
                  // SECTION CREDITS
                  // =======================
                  _buildCreditsCard(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRulesCard(BuildContext context) {
    return Card(
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.menu_book, color: context.primaryColor),
            const SizedBox(width: 12),
            Text(
              "rules".tr,
              style: TextStyle(
                color: context.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        iconColor: context.primaryColor,
        collapsedIconColor: context.mutedColor,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuleItem(
                  context,
                  icon: Icons.lightbulb,
                  title: "Le Principe",
                  description: "À votre tour, vous devez nommer à voix haute un objet de votre environnement qui commence par la lettre affichée à l'écran. L'objet doit être visible par tous.",
                ),
                _buildRuleItem(
                  context,
                  icon: Icons.how_to_vote,
                  title: "Le Vote",
                  description: "Les autres joueurs votent pour accepter ou rejeter votre mot. Si le mot est accepté, le tour passe au joueur suivant. S'il est refusé, votre chrono reprend et vous devez trouver un autre mot.",
                ),
                _buildRuleItem(
                  context,
                  icon: Icons.warning_amber_rounded,
                  title: "Système de Malus",
                  description: "• Joueur actif : 2 mots refusés = -10 secondes de malus sur votre chrono global.\n• Votants : 2 erreurs de vote (voter contre un mot validé, ou pour un mot refusé) = -15 secondes de pénalité.",
                ),
                _buildRuleItem(
                  context,
                  icon: Icons.timer_off,
                  title: "Élimination",
                  description: "Chaque joueur possède un minuteur qui ne s'écoule que durant son tour. Si votre minuteur atteint 0, vous êtes éliminé. Le dernier en jeu l'emporte !",
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsCard(BuildContext context) {
    return Card(
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: context.primaryColor),
            const SizedBox(width: 12),
            Text(
              "credits".tr,
              style: TextStyle(
                color: context.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        iconColor: context.primaryColor,
        collapsedIconColor: context.mutedColor,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Text(
                  "Kboom",
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    color: context.mutedColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildCreditRow("Développement", "Alexis"),
                const SizedBox(height: 8),
                _buildCreditRow("Design graphique", "Alexis"),
                const SizedBox(height: 8),
                _buildCreditRow("Inspiration originale", "Jeu Kaleidos"),
                const SizedBox(height: 16),
                Text(
                  "Merci à tous les joueurs pour leurs précieux retours et tests lors de nos soirées !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditRow(String role, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          role,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        Text(
          name,
          style: TextStyle(
            color: GameVariables.generalInformation.isDarkMode.value ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _reconnectAsGuest() {
    // Generate guest token
    final guestToken = math.Random().nextInt(100000).toString().padLeft(5, '0');
    GameVariables.generalInformation.token.value = guestToken;

    // Disconnect auth socket
    authSocketService.disconnect();

    // Reconnect game socket
    final serverType = GameVariables.serverType.value;
    String gameUrl;
    if (serverType == ServerType.local) {
      gameUrl = GameVariables.localUrl;
    } else if (serverType == ServerType.production) {
      gameUrl = GameVariables.productionUrl;
    } else {
      final ip = GameVariables.customServerIp.value;
      final port = GameVariables.customServerPort.value;
      gameUrl = 'wss://$ip:$port';
    }
    socketService.connectTo(gameUrl);
  }
}
