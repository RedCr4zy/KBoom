import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/services/socket_service.dart';

class ServerConfigWidget extends StatefulWidget {
  const ServerConfigWidget({super.key});

  @override
  State<ServerConfigWidget> createState() => _ServerConfigWidgetState();
}

class _ServerConfigWidgetState extends State<ServerConfigWidget> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  bool _hasChanges = false;

  static const String _localIp = '192.168.1.13';
  static const int _localPort = 3000;

  static const String _prodIp = '87.106.105.24';
  static const int _prodPort = 12127;

  @override
  void initState() {
    super.initState();

    _ipController.text = GameVariables.customServerIp.value;
    _portController.text =
        GameVariables.customServerPort.value.toString();

    GameVariables.serverType.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    GameVariables.serverType.removeListener(_onConfigChanged);
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (!mounted) return;
    setState(() {
      _hasChanges = true;
    });
  }

  /* ===========================
     APPLY CHANGES
  =========================== */

  void _applyChanges() {
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

    print('🔄 Application de la nouvelle config : $url');

    // Reconnecter avec la nouvelle URL
    socketService.disconnect();

    Future.delayed(const Duration(milliseconds: 500), () {
      socketService.connectTo(url);
    });

    if (mounted) {
      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconnexion au serveur...'),
          backgroundColor: context.warningColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.warningColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _getServerConfig(ServerType type) {
    switch (type) {
      case ServerType.local:
        return {'ip': _localIp, 'port': _localPort};

      case ServerType.production:
        return {'ip': _prodIp, 'port': _prodPort};

      case ServerType.custom:
        return {
          'ip': GameVariables.customServerIp.value,
          'port': GameVariables.customServerPort.value,
        };
    }
  }

  /* ===========================
     BUILD
  =========================== */

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Serveur',
            style: TextStyle(
              color: context.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ValueListenableBuilder<ServerType>(
            valueListenable: GameVariables.serverType,
            builder: (context, selectedType, _) {
              final config = _getServerConfig(selectedType);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<ServerType>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type de serveur',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ServerType.local,
                        child: Text('Serveur Local (PC)'),
                      ),
                      DropdownMenuItem(
                        value: ServerType.production,
                        child: Text('Serveur Production (WispByte)'),
                      ),
                      DropdownMenuItem(
                        value: ServerType.custom,
                        child: Text('Serveur Personnalisé'),
                      ),
                    ],
                    onChanged: (newType) {
                      if (newType == null) return;
                      GameVariables.serverType.value = newType;
                    },
                  ),

                  const SizedBox(height: 16),

                  if (selectedType != ServerType.custom)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Adresse : ${config['ip']}:${config['port']}',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                  if (selectedType == ServerType.custom) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse IP',
                        hintText: '192.168.1.1',
                      ),
                      onChanged: (value) {
                        GameVariables.customServerIp.value = value;
                        setState(() => _hasChanges = true);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '3000',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        final port = int.tryParse(value);
                        if (port != null) {
                          GameVariables.customServerPort.value = port;
                          setState(() => _hasChanges = true);
                        }
                      },
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasChanges ? _applyChanges : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Appliquer et reconnecter'),
            ),
          ),

          const SizedBox(height: 12),

          ValueListenableBuilder<SocketConnectionState>(
            valueListenable: socketService.connectionState,
            builder: (context, state, _) {
              String statusText;

              switch (state) {
                case SocketConnectionState.connected:
                  statusText = 'Connecté';
                  break;
                case SocketConnectionState.connecting:
                  statusText = 'Connexion en cours...';
                  break;
                case SocketConnectionState.error:
                  statusText = 'Erreur de connexion';
                  break;
                default:
                  statusText = 'Déconnecté';
              }

              return Text(
                statusText,
                style: TextStyle(color: context.textSecondaryColor),
              );
            },
          ),
        ],
      ),
    );
  }
}
