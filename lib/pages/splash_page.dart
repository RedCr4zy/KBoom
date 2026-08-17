// ========================================
// SPLASH PAGE (ÉCRAN DE CHARGEMENT INITIAL)
// ========================================

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/pages/home_page.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/services/auth_socket_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialConfig();
  }

  void _connectSockets() {
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
    
    // Always connect to the game server
    socketService.connectTo(gameUrl);

    // Only connect to auth service if using a central account (JWT)
    final token = GameVariables.generalInformation.token.value ?? '';
    if (token.contains('.')) {
      authSocketService.connect();
    }
  }

  Future<void> _loadInitialConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Étape 1 : Charger et appliquer le mode sombre/clair sauvegardé
    final isDark = prefs.getBool('is_dark_mode') ?? true;
    GameVariables.generalInformation.isDarkMode.value = isDark;

    // Étape 2 : Charger et appliquer la langue sauvegardée
    final langCode = prefs.getString('language_code');
    if (langCode != null) {
      Get.updateLocale(Locale(langCode));
    }

    // Étape 3 : Charger le token d'authentification ou générer un token d'invité
    final token = prefs.getString('auth_token');
    final hasToken = token != null && token.isNotEmpty;

    if (hasToken) {
      GameVariables.generalInformation.token.value = token;
    } else {
      // Guest mode fallback (Random 5-digit number)
      GameVariables.generalInformation.token.value =
          Random().nextInt(100000).toString().padLeft(5, '0');
    }

    final savedPseudo = prefs.getString('saved_pseudo');
    if (savedPseudo != null && savedPseudo.isNotEmpty) {
      GameVariables.generalInformation.pseudo.value = savedPseudo;
    }

    final savedAvatarJson = prefs.getString('saved_avatar_data');
    if (savedAvatarJson != null && savedAvatarJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedAvatarJson);
        if (decoded is Map<String, dynamic>) {
          GameVariables.generalInformation.avatarData.value = decoded;
        }
      } catch (_) {}
    }

    _connectSockets();

    // Étape 4 : Délai pour afficher la barre de progression
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Étape 5 : Transition en fondu vers la HomePage (l'inscription n'est plus obligatoire au lancement)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 600;

            final verticalPadding = isSmallScreen ? 24.0 : 48.0;
            final titleFontSize = isSmallScreen ? 48.0 : 64.0;
            final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: verticalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 1),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "KBOOM",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w900,
                                color: context.textColor,
                                letterSpacing: 6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "app_subtitle".tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: subtitleFontSize,
                              color: context.textSecondaryColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 8,
                              width: MediaQuery.of(context).size.width < 360 ? 180 : 220,
                              child: LinearProgressIndicator(
                                value: _isLoading ? null : 1.0,
                                backgroundColor: context.borderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "loading".tr,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 13,
                              color: context.mutedColor,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
