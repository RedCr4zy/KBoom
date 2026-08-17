import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kboom/pages/create_page.dart';
import 'package:kboom/pages/home_page.dart';
import 'package:kboom/pages/waiting.dart';
import 'package:kboom/pages/splash_page.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/services/translation_service.dart';
import 'package:kboom/game_variable.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  // ========================================
  // AJOUT : Fonction pour réveiller tous les serveurs (jeu et auth)
  // ========================================
  Future<void> _wakeUpAllServers() async {
    final serverType = GameVariables.serverType.value;

    Future<bool> wakeGame() async {
      if (serverType == ServerType.local) return true;
      String pingUrl = serverType == ServerType.production
          ? '${GameVariables.productionHttpUrl}/ping'
          : 'https://${GameVariables.customServerIp.value}:${GameVariables.customServerPort.value}/ping';
      try {
        print('🔔 Réveil du serveur de jeu : $pingUrl');
        final response = await http.get(Uri.parse(pingUrl)).timeout(const Duration(seconds: 45));
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    }

    Future<bool> wakeAuth() async {
      if (serverType == ServerType.local) return true;
      String pingUrl = '${GameVariables.centralAuthHttpUrl}/ping';
      try {
        print('🔔 Réveil du serveur d\'authentification : $pingUrl');
        final response = await http.get(Uri.parse(pingUrl)).timeout(const Duration(seconds: 45));
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    }

    await Future.wait([wakeGame(), wakeAuth()]);
    print('✅ Tentative de réveil des serveurs terminée');
  }

  // ========================================
  // AJOUT : Fonction pour se connecter au serveur de jeu
  // ========================================
  void _connectToServer() {
    final serverType = GameVariables.serverType.value;
    String url;

    switch (serverType) {
      case ServerType.local:
        url = GameVariables.localUrl;
        break;
      case ServerType.production:
        url = GameVariables.productionUrl;
        break;
      case ServerType.custom:
        final ip = GameVariables.customServerIp.value;
        final port = GameVariables.customServerPort.value;
        url = 'wss://$ip:$port';
        break;
    }

    print('🔌 Connexion au serveur : $url');
    socketService.connectTo(url);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialisation des variables
    GameVariables.code.value = "";
    GameVariables.gameInformation.letter.value = "";

    // Lancer le réveil des serveurs en arrière-plan dès le démarrage
    _wakeUpAllServers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 Application de retour au premier plan (resumed)');
      if (socketService.connectionState.value != SocketConnectionState.connected) {
        print('🔄 Reconnexion automatique du WebSocket au retour au premier plan...');
        socketService.reconnect();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      translations: KboomTranslations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const SplashPage(),
      routes: {
        '/create': (_) => const CreatePage(),
        '/waiting': (_) => const WaitingPage(),
      },
    );
  }
}