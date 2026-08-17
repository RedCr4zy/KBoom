import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/main.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final AuthSocketService authSocketService = AuthSocketService();

class AuthSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;

  final ValueNotifier<List<Map<String, dynamic>>> friendsList = ValueNotifier([]);

  void connect() {
    final token = GameVariables.generalInformation.token.value;
    if (token == null || token.isEmpty) {
      print("⚠️ AuthSocketService: Impossible de se connecter, pas de token");
      return;
    }

    if (_isConnected) {
      disconnect();
    }

    final wsUrl = "${GameVariables.centralAuthWsUrl}?token=$token";
    print("🔌 AuthSocketService: Connexion vers $wsUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            print("📨 AuthSocketService Reçu: $data");
            _handleMessage(data);
          } catch (e) {
            print("⚠️ AuthSocketService: Erreur de parsing du message: $e");
          }
        },
        onError: (err) {
          print("❌ AuthSocketService: Erreur WebSocket: $err");
          _isConnected = false;
        },
        onDone: () {
          print("🔌 AuthSocketService: Connexion fermée");
          _isConnected = false;
        },
      );
    } catch (e) {
      print("❌ AuthSocketService: Échec de connexion: $e");
      _isConnected = false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    friendsList.value = [];
  }

  void sendJson(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      print("⚠️ AuthSocketService: Impossible d'envoyer, non connecté");
    }
  }

  // API Methods
  void addFriend(String pseudo) {
    sendJson({
      "type": "addFriend",
      "pseudo": pseudo,
    });
  }

  void removeFriend(String friendId) {
    sendJson({
      "type": "removeFriend",
      "friendId": friendId,
    });
  }

  void inviteFriend(String friendId, String roomCode) {
    sendJson({
      "type": "inviteFriend",
      "friendId": friendId,
      "roomCode": roomCode,
    });
  }

  void changeStatus(String status) {
    sendJson({
      "type": "changeStatus",
      "status": status,
    });
  }

  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'friendList':
        friendsList.value = List<Map<String, dynamic>>.from(data['friends'] ?? []);
        break;

      case 'friendInviteReceived':
        final senderPseudo = data['senderPseudo'];
        final roomCode = data['roomCode'];
        _showInGameInvitation(senderPseudo, roomCode);
        break;

      case 'error':
        final msg = data['message'] ?? 'Une erreur est survenue';
        _showToast(msg, isError: true);
        break;

      case 'info':
        final msg = data['message'] ?? '';
        _showToast(msg, isError: false);
        break;
    }
  }

  void _showInGameInvitation(String senderPseudo, String roomCode) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierColor: context.modalOverlayColor,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: dialogContext.borderColor),
          ),
          title: Text(
            "Invitation de partie",
            style: TextStyle(
              color: dialogContext.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            "$senderPseudo vous invite à rejoindre sa partie (salle $roomCode) !",
            style: TextStyle(color: dialogContext.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Refuser",
                style: TextStyle(color: dialogContext.mutedColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogContext.successColor,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                
                // Join room via game socket service
                socketService.sendJson({
                  "type": "joinRoom",
                  "roomCode": roomCode,
                  "pseudo": GameVariables.generalInformation.pseudo.value,
                  "token": GameVariables.generalInformation.token.value,
                });
              },
              child: const Text(
                "Rejoindre",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showToast(String message, {required bool isError}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.dangerColor : context.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
