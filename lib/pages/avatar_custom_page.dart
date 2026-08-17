import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kboom/colors.dart';
import 'package:kboom/game_variable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kboom/models/avatar_model.dart';
import 'package:kboom/widgets/avatar_widget.dart';
import 'package:kboom/services/socket_service.dart';
import 'package:kboom/utils/avatar_utils.dart';
import 'package:kboom/utils/svg_cache.dart';

class AvatarCustomPage extends StatefulWidget {
  const AvatarCustomPage({super.key});

  @override
  State<AvatarCustomPage> createState() => _AvatarCustomPageState();
}

class _AvatarCustomPageState extends State<AvatarCustomPage> {
  bool _isLoading = true;
  int _userLevel = 1;

  // Customization State
  String _selectedBackground = '';
  String _selectedHat = '';
  //String _selectedEyes = '';
  //String _selectedMouth = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    // First, load from local GameVariables/SharedPreferences
    final localAvatar = GameVariables.generalInformation.avatarData.value;
    _selectedBackground = localAvatar['equipped_background'] ?? '';
    _selectedHat = localAvatar['equipped_hat'] ?? '';
    //_selectedEyes = localAvatar['equipped_eyes'] ?? '';
   // _selectedMouth = localAvatar['equipped_mouth'] ?? '';

    final token = GameVariables.generalInformation.token.value;
    if (token == null || token.isEmpty || !token.contains('.')) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final httpUrl = GameVariables.centralAuthHttpUrl;
      final response = await http.get(
        Uri.parse("$httpUrl/api/profile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _userLevel = profile['level'] ?? 1;
            final serverBackground = profile['equipped_background'];
            final serverHat = profile['equipped_hat'];
            //final serverEyes = profile['equipped_eyes'];
            //final serverMouth = profile['equipped_mouth'];

            if (AvatarRegistry.exists(serverHat)) {
              _selectedHat = serverHat;
            }

            /*if (AvatarRegistry.exists(serverEyes)) {
              _selectedEyes = serverEyes;
            }*/

            //if (AvatarRegistry.exists(serverMouth)) {
            //  _selectedMouth = serverMouth;
            //}
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    // Check if player is in a room and is ready
    final players = socketService.playersNotifier.value;
    final myToken = GameVariables.generalInformation.token.value;
    final mine = players.where((p) => p['token'] == myToken).toList();
    if (mine.isNotEmpty && mine.first['isReady'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Vous devez retirer votre état 'Prêt' pour modifier votre avatar !",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final avatarMap = {
      'equipped_background': _selectedBackground,
      'equipped_hat': _selectedHat,
      //'equipped_eyes': _selectedEyes,
      //'equipped_mouth': _selectedMouth,
    };

    // 1. Update GameVariables
    GameVariables.generalInformation.avatarData.value = avatarMap;

    // 2. Persist locally to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_avatar_data', jsonEncode(avatarMap));
    } catch (e) {
      debugPrint("Error saving avatar to SharedPreferences: $e");
    }

    // 3. Update game server via WebSocket
    socketService.sendJson({
      'type': 'update',
      'token': myToken,
      'pseudo': GameVariables.generalInformation.pseudo.value,
      'avatarData': avatarMap,
    });

    // 4. Update auth service if authenticated
    final token = GameVariables.generalInformation.token.value;
    if (token != null && token.contains('.')) {
      try {
        final httpUrl = GameVariables.centralAuthHttpUrl;
        await http.post(
          Uri.parse("$httpUrl/api/profile/equip"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "token": token,
            "hat": _selectedHat,
            //"eyes": _selectedEyes,
            //"mouth": _selectedMouth,
          }),
        );
      } catch (e) {
        debugPrint("Error syncing avatar with auth-service: $e");
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Avatar sauvegardé avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatarData = AvatarData(
      backgroundId: _selectedBackground,
      hatId: _selectedHat,
      //eyesId: _selectedEyes,
      //mouthId: _selectedMouth,
    );

    final categories = [
      (
        " ",
        AvatarCategory.background,
        _selectedBackground,
        (String id) {
          setState(() {
            _selectedBackground = id;
          });
        },
      ),

      /*(
        "Chapeau",
        AvatarCategory.hat,
        _selectedHat,
        (String id) {
          setState(() {
            _selectedHat = id;
          });
        },
      ),*/

      /*(
        "Yeux",
        AvatarCategory.eyes,
        _selectedEyes,
        (String id) {
          setState(() {
            _selectedEyes = id;
          });
        },
      ),*/

      /*(
        "Bouche",
        AvatarCategory.mouth,
        _selectedMouth,
        (String id) {
          setState(() {
            _selectedMouth = id;
          });
        },
      ),*/
    ];

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Mon Avatar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: context.textColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==========================
                  // AVATAR PREVIEW WIDGET
                  // ==========================
                  AvatarWidget(avatarData: currentAvatarData, size: 160),
                  const SizedBox(height: 12),
                  Text(
                    "Niveau $_userLevel",
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // ==========================
                  // HATS SELECTION
                  // ==========================
                  for (final category in categories) ...[
                    _buildSectionHeader(category.$1),

                    const SizedBox(height: 10),

                    _buildCategoryGrid(
                      AvatarRegistry.getCategoryItems(category.$2),

                      category.$3,

                      category.$4,
                    ),

                    const SizedBox(height: 24),
                  ],

                  // ==========================
                  // SAVE BUTTON
                  // ==========================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saveChanges,
                      child: const Text(
                        "Sauvegarder mon profil",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: context.textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildItemPreview(AvatarItem item) {
    final path = item.imageAsset?.toLowerCase() ?? '';

    if (path.endsWith('.svg')) {
      return FutureBuilder<String?>(
        future: SvgCache.load(item.imageAsset!),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return SvgPicture.string(
              snapshot.data!,

              width: 48,

              height: 48,

              fit: BoxFit.contain,
            );
          }

          return const SizedBox(width: 48, height: 48);
        },
      );
    }

    return Image.asset(
      item.imageAsset!,

      width: 48,

      height: 48,

      fit: BoxFit.contain,
    );
  }

  Widget _buildCategoryGrid(
    List<AvatarItem> items,
    String selectedId,
    Function(String) onSelect,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedId == item.id;
        final isLocked = item.unlockedLevel > _userLevel;

        return GestureDetector(
          onTap: isLocked ? null : () => onSelect(item.id),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? context.primaryColor.withValues(alpha:0.15)
                  : context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? context.primaryColor : context.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (item.assetType == AvatarAssetType.imageAsset &&
                    item.imageAsset != null &&
                    item.imageAsset!.isNotEmpty)
                  _buildItemPreview(item)
                else
                  Text(
                    item.emoji ?? '',
                    style: TextStyle(
                      fontSize: item.id.isEmpty ? 14 : 32,
                      color: item.id.isEmpty
                          ? context.textSecondaryColor
                          : null,
                    ),
                  ),
                if (isLocked)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.55),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, color: Colors.amber, size: 20),
                          const SizedBox(height: 2),
                          Text(
                            "Niv. ${item.unlockedLevel}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
