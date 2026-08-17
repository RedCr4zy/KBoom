import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/pages/create_page.dart';
import 'package:kboom/pages/join_page.dart';
import 'package:kboom/pages/parameters.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/widgets/friends_list_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GameVariables.generalInformation.isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: context.backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const SizedBox(height: 30),

                          ValueListenableBuilder<SocketConnectionState>(
                            valueListenable: socketService.connectionState,
                            builder: (context, state, _) {
                              Color statusColor;
                              String statusText;
                              IconData statusIcon;
                              String? subText;

                              switch (state) {
                                case SocketConnectionState.connected:
                                  statusColor = context.successColor;
                                  statusText = 'connected'.tr;
                                  statusIcon = Icons.check_circle;
                                  break;

                                case SocketConnectionState.connecting:
                                  statusColor = context.warningColor;
                                  statusText = 'loading'.tr;
                                  statusIcon = Icons.sync;
                                  subText = 'wake_up_message'.tr;
                                  break;

                                case SocketConnectionState.error:
                                  statusColor = context.dangerColor;
                                  statusText = 'conn_error'.tr;
                                  statusIcon = Icons.error;
                                  subText = socketService.errorMessage.value;
                                  break;

                                default:
                                  statusColor = context.mutedColor;
                                  statusText = 'disconnected'.tr;
                                  statusIcon = Icons.cloud_off;
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      state == SocketConnectionState.connecting
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation(statusColor),
                                              ),
                                            )
                                          : Icon(
                                              statusIcon,
                                              color: statusColor,
                                              size: 16,
                                            ),
                                      const SizedBox(width: 8),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (subText != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: context.mutedColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          Text(
                            'Kboom',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'app_subtitle'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 18,
                            ),
                          ),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.login),
                              label: Text(
                                'join_room'.tr,
                                style: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const JoinPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: context.buttonTextColor,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(
                                'create_room'.tr,
                                style: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CreatePage()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.primaryColor,
                                side: BorderSide(color: context.primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: context.surfaceColor,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: IconButton(
                          icon: const Icon(Icons.people),
                          color: context.successColor,
                          onPressed: () {
                            final token = GameVariables.generalInformation.token.value ?? '';
                            if (token.contains('.')) {
                              FriendsListSheet.show(context);
                            } else {
                              _showLoginRequiredAlert(context, 'la liste d\'amis');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: context.surfaceColor,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: IconButton(
                          icon: const Icon(Icons.settings),
                          color: context.textColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParametersPage()),
                            );
                          },
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

  void _showLoginRequiredAlert(BuildContext context, String featureName) {
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
            'Compte requis',
            style: TextStyle(
              color: dialogContext.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Pour accéder à $featureName, veuillez vous connecter ou créer un compte global dans les paramètres !',
            style: TextStyle(color: dialogContext.textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Fermer',
                style: TextStyle(color: dialogContext.mutedColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: dialogContext.primaryColor),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParametersPage()),
                );
              },
              child: const Text('Aller aux paramètres', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
