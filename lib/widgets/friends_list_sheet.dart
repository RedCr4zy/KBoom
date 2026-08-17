import 'package:flutter/material.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:kboom/services/auth_socket_service.dart';

class FriendsListSheet extends StatefulWidget {
  const FriendsListSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FriendsListSheet(),
    );
  }

  @override
  State<FriendsListSheet> createState() => _FriendsListSheetState();
}

class _FriendsListSheetState extends State<FriendsListSheet> {
  final TextEditingController _addFriendController = TextEditingController();

  void _handleAddFriend() {
    final pseudo = _addFriendController.text.trim();
    if (pseudo.isNotEmpty) {
      authSocketService.addFriend(pseudo);
      _addFriendController.clear();
    }
  }

  Color _parseHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse("FF$cleaned", radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'En ligne':
        return context.successColor;
      case 'En partie':
        return context.warningColor;
      default:
        return context.mutedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardHeight),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: context.mutedColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Mes Amis",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Add Friend Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addFriendController,
                  decoration: InputDecoration(
                    hintText: "Ajouter par pseudo...",
                    hintStyle: TextStyle(color: context.textSecondaryColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: context.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: context.textColor),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleAddFriend,
                child: const Icon(Icons.person_add),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Friends List
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: authSocketService.friendsList,
                builder: (context, friends, _) {
                  if (friends.isEmpty) {
                    return Center(
                      child: Text(
                        "Vous n'avez pas encore d'amis.",
                        style: TextStyle(color: context.mutedColor, fontStyle: FontStyle.italic),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final friendId = friend['id'] as String;
                      final pseudo = friend['pseudo'] as String;
                      final colorHex = friend['color'] as String? ?? '#FF5733';
                      final level = friend['level'] as int? ?? 1;
                      final status = friend['status'] as String? ?? 'Hors ligne';

                      // Can invite if friend is online and client is in a game room
                      final currentRoomCode = GameVariables.gameInformation.roomCode.value;
                      final canInvite = status == 'En ligne' && currentRoomCode != null;

                      return Row(
                        children: [
                          // Friend avatar circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _parseHex(colorHex),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                pseudo.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Pseudo & Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pseudo,
                                  style: TextStyle(
                                    color: context.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(context, status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$status • Niv. $level",
                                      style: TextStyle(
                                        color: context.textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          if (canInvite)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: context.successColor,
                              ),
                              onPressed: () {
                                authSocketService.inviteFriend(friendId, currentRoomCode);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Invitation envoyée à $pseudo !"),
                                    backgroundColor: context.successColor,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.send, size: 16),
                              label: const Text("Inviter"),
                            ),

                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: context.dangerColor,
                            onPressed: () {
                              authSocketService.removeFriend(friendId);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
