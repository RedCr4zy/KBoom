import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/pages/home_page.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/services/auth_socket_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSignUp = false;
  bool _isLoading = false;

  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final password = _passwordController.text.trim();
    final pseudo = _pseudoController.text.trim();

    debugPrint('[LOGIN-UI] Tentative ${_isSignUp ? 'signup' : 'signin'} avec pseudo=$pseudo');

    try {
      final httpUrl = GameVariables.centralAuthHttpUrl;
      final endpoint = _isSignUp ? "$httpUrl/api/auth/signup" : "$httpUrl/api/auth/signin";
      final body = {
        "pseudo": pseudo,
        "password": password,
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      debugPrint('[LOGIN-UI] Réponse auth ${response.statusCode}: $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] as String;
        final userPseudo = (data['pseudo'] as String?) ?? pseudo;

        // Save token and pseudo locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('saved_pseudo', userPseudo);

        // Update local variables
        GameVariables.generalInformation.token.value = token;
        GameVariables.generalInformation.pseudo.value = userPseudo;

        // Connect Websockets
        _connectSockets();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isSignUp
                  ? "🎉 Compte créé avec succès ! Connexion automatique..."
                  : "👋 Connexion réussie ! Bienvenue $userPseudo !"),
              backgroundColor: context.successColor,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        debugPrint('[LOGIN-UI] Échec auth: ${data['error'] ?? 'Une erreur est survenue'}');
        _showError(data['error'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      debugPrint('[LOGIN-UI] Exception auth: $e');
      _showError("Impossible de contacter le serveur d'authentification");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _connectSockets() {
    // Game socket connection
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

    // Auth socket connection for friends status and invites
    authSocketService.connect();
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.dangerColor,
      ),
    );
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "KBOOM",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: context.primaryColor,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isSignUp ? "Créer un compte" : "Se connecter",
                    style: TextStyle(
                      fontSize: 18,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _pseudoController,
                          decoration: InputDecoration(
                            labelText: "Pseudo",
                            labelStyle: TextStyle(color: context.textSecondaryColor),
                            prefixIcon: Icon(Icons.person, color: context.primaryColor),
                          ),
                          style: TextStyle(color: context.textColor),
                          validator: (val) =>
                              val == null || val.trim().length < 3 ? "Minimum 3 caractères" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Mot de passe",
                            labelStyle: TextStyle(color: context.textSecondaryColor),
                            prefixIcon: Icon(Icons.lock, color: context.primaryColor),
                          ),
                          style: TextStyle(color: context.textColor),
                          validator: (val) =>
                              val == null || val.length < 6 ? "Minimum 6 caractères" : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: context.buttonTextColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isSignUp ? "Créer mon compte" : "Se connecter",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(
                      _isSignUp ? "Déjà un compte ? Connectez-vous" : "Pas de compte ? Inscrivez-vous",
                      style: TextStyle(color: context.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
