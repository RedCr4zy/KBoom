import 'package:flutter/material.dart';

// ============================================================================
// SYSTEME D'AVATARS KBOOM
// ============================================================================
// Modèle central des avatars.
// Les accessoires sont des calques indépendants.
// L'ordre d'affichage est défini par AvatarCategory.order.
// ============================================================================

enum AvatarCategory {
  background(0),
  body(1),
  eyes(2),
  mouth(3),
  hat(4),
  accessory(5);

  final int order;

  const AvatarCategory(this.order);
}

enum AvatarAssetType { color, emoji, imageAsset, spriteSheet }

class AvatarItem {
  final String id;

  final String name;

  final AvatarCategory category;

  final int unlockedLevel;

  final AvatarAssetType assetType;

  final String? emoji;

  final String? imageAsset;

  final Color? color;

  final bool useTintColor;

  final Rect? spriteSourceRect;

  /// Multiplicateur général de taille
  final double scale;

  /// Taille native de l'élément
  final double? width;

  final double? height;

  /// Position relative dans son propre rectangle
  final Offset anchor;

  /// Décalage final sur l'avatar
  final Offset offset;

  const AvatarItem({
    required this.id,

    required this.name,

    required this.category,

    this.unlockedLevel = 1,

    this.assetType = AvatarAssetType.emoji,

    this.emoji,

    this.imageAsset,

    this.color,

    this.useTintColor = false,

    this.spriteSourceRect,

    this.scale = 1.0,

    this.width,

    this.height,

    this.anchor = const Offset(0.5, 0.5),

    this.offset = Offset.zero,
  });

  bool get hasImage =>
      assetType == AvatarAssetType.imageAsset &&
      imageAsset != null &&
      imageAsset!.isNotEmpty;
}

class AvatarData {
  final String colorHex;

  final String hatId;

  final String eyesId;

  final String mouthId;

  final String backgroundId;

  final String accessoryId;

  const AvatarData({
    this.colorHex = '#FF5733',

    this.hatId = '',

    this.eyesId = '',

    this.mouthId = '',

    this.backgroundId = '',

    this.accessoryId = '',
  });

  Map<String, dynamic> toJson() => {
    'equipped_color': colorHex,

    'equipped_hat': hatId,

    'equipped_eyes': eyesId,

    'equipped_mouth': mouthId,

    'background_id': backgroundId,

    'accessory_id': accessoryId,
  };

  factory AvatarData.fromJson(Map<String, dynamic> json) {
    return AvatarData(
      colorHex: json['equipped_color'] ?? '#FF5733',

      hatId: AvatarRegistry.exists(json['equipped_hat'])
          ? json['equipped_hat']
          : '',

      eyesId: AvatarRegistry.exists(json['equipped_eyes'])
          ? json['equipped_eyes']
          : '',

      mouthId: AvatarRegistry.exists(json['equipped_mouth'])
          ? json['equipped_mouth']
          : '',

      backgroundId: AvatarRegistry.exists(json['background_id'])
          ? json['background_id']
          : '',

      accessoryId: AvatarRegistry.exists(json['accessory_id'])
          ? json['accessory_id']
          : '',
    );
  }

  factory AvatarData.fromMap(Map<String, dynamic> json) {
    return AvatarData.fromJson(json);
  }
}

class AvatarRegistry {
  static final List<String> availableColors = [
    '#FF5733',

    '#3357FF',

    '#33FF57',

    '#F1C40F',

    '#9B59B6',

    '#E67E22',

    '#1ABC9C',

    '#E74C3C',
  ];

  static final Map<String, AvatarItem> _items = {
    // ======================================================
    // BACKGROUNDS
    // ======================================================
    'bear_background': const AvatarItem(
      id: 'bear_background',
      name: 'Ours',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/bear_background.svg',
      width: 320,
      height: 320,
    ),

    'brain_background': const AvatarItem(
      id: 'brain_background',
      name: 'Cerveau',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/brain_background.svg',
      width: 320,
      height: 320,
    ),

    'bunny_background': const AvatarItem(
      id: 'bunny_background',
      name: 'Lapin',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/bunny_background.svg',
      width: 320,
      height: 320,
    ),

    'camel_background': const AvatarItem(
      id: 'camel_background',
      name: 'Chameau',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/camel_background.svg',
      width: 320,
      height: 320,
    ),

    'cat_background': const AvatarItem(
      id: 'cat_background',
      name: 'Chat',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/cat_background.svg',
      width: 320,
      height: 320,
    ),

    'deer_background': const AvatarItem(
      id: 'deer_background',
      name: 'Cerf',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/deer_background.svg',
      width: 320,
      height: 320,
    ),

    'dog_background': const AvatarItem(
      id: 'dog_background',
      name: 'Chien',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/dog_background.svg',
      width: 320,
      height: 320,
    ),

    'dragon_background': const AvatarItem(
      id: 'dragon_background',
      name: 'Dragon',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/dragon_background.svg',
      width: 320,
      height: 320,
    ),

    'eagle_background': const AvatarItem(
      id: 'eagle_background',
      name: 'Aigle',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/eagle_background.svg',
      width: 320,
      height: 320,
    ),

    'elf_background': const AvatarItem(
      id: 'elf_background',
      name: 'Elfe',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/elf_background.svg',
      width: 320,
      height: 320,
    ),

    'fox_background': const AvatarItem(
      id: 'fox_background',
      name: 'Renard',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/fox_background.svg',
      width: 320,
      height: 320,
    ),

    'frog_background': const AvatarItem(
      id: 'frog_background',
      name: 'Grenouille',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/frog_background.svg',
      width: 320,
      height: 320,
    ),

    'horse_background': const AvatarItem(
      id: 'horse_background',
      name: 'Cheval',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/horse_background.svg',
      width: 320,
      height: 320,
    ),

    'owl_background': const AvatarItem(
      id: 'owl_background',
      name: 'Chouette',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/owl_background.svg',
      width: 320,
      height: 320,
    ),

    'monster_background': const AvatarItem(
      id: 'monster_background',
      name: 'Monstre',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/monster_background.svg',
      width: 320,
      height: 320,
    ),

    'panda_background': const AvatarItem(
      id: 'panda_background',
      name: 'Panda',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/panda_background.svg',
      width: 320,
      height: 320,
    ),

    'skeleton_background': const AvatarItem(
      id: 'skeleton_background',
      name: 'Squelette',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/skeleton_background.svg',
      width: 320,
      height: 320,
    ),

    'snake_background': const AvatarItem(
      id: 'snake_background',
      name: 'Serpent',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/snake_background.svg',
      width: 320,
      height: 320,
    ),

    'sun_background': const AvatarItem(
      id: 'sun_background',
      name: 'Soleil',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/sun_background.svg',
      width: 320,
      height: 320,
    ),

    'tiger_background': const AvatarItem(
      id: 'tiger_background',
      name: 'Tigre',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/tiger_background.svg',
      width: 320,
      height: 320,
    ),

    'unicorn_background': const AvatarItem(
      id: 'unicorn_background',
      name: 'Licorne',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/unicorn_background.svg',
      width: 320,
      height: 320,
    ),

    'zombie_background': const AvatarItem(
      id: 'zombie_background',
      name: 'Zombie',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/zombie_background.svg',
      width: 320,
      height: 320,
    ),

    'earth_background': const AvatarItem(
      id: 'earth_background',
      name: 'Terre',
      category: AvatarCategory.background,
      unlockedLevel: 0,
      assetType: AvatarAssetType.imageAsset,
      imageAsset: 'images/backgrounds/earth_background.svg',
      width: 320,
      height: 320,
    ),

    // ======================================================
    // HATS
    // ======================================================
    'viking_hat': const AvatarItem(
      id: 'viking_hat',

      name: 'Casque Viking',

      category: AvatarCategory.hat,

      unlockedLevel: 0,

      assetType: AvatarAssetType.imageAsset,

      imageAsset: 'images/hats/viking_hat.svg',

      width: 200,

      height: 200,

      anchor: Offset(0.5, 0.2),
    ),

    // ======================================================
    // EYES
    // ======================================================
    'sunglasses': const AvatarItem(
      id: 'sunglasses',

      name: 'Lunettes de soleil',

      category: AvatarCategory.eyes,

      emoji: '😎',
    ),

    'glasses': const AvatarItem(
      id: 'glasses',

      name: 'Lunettes',

      category: AvatarCategory.eyes,

      unlockedLevel: 2,

      emoji: '👓',
    ),

    'goggles': const AvatarItem(
      id: 'goggles',

      name: 'Masque de plongée',

      category: AvatarCategory.eyes,

      unlockedLevel: 3,

      emoji: '🥽',
    ),

    // ======================================================
    // MOUTHS
    // ======================================================
    'smile': const AvatarItem(
      id: 'smile',

      name: 'Sourire',

      category: AvatarCategory.mouth,

      emoji: '🙂',
    ),

    'tongue': const AvatarItem(
      id: 'tongue',

      name: 'Langue',

      category: AvatarCategory.mouth,

      unlockedLevel: 2,

      emoji: '👅',
    ),

    'moustache': const AvatarItem(
      id: 'moustache',

      name: 'Moustache',

      category: AvatarCategory.mouth,

      unlockedLevel: 3,

      emoji: '👨',
    ),
  };

  static bool exists(String? id) {
    if (id == null || id.isEmpty) {
      return false;
    }

    return _items.containsKey(id);
  }

  static AvatarItem? getItem(String id) {
    return _items[id];
  }

  static List<AvatarItem> getCategoryItems(AvatarCategory category) {
    final result = _items.values
        .where((item) => item.category == category)
        .toList();

    result.sort((a, b) => a.unlockedLevel.compareTo(b.unlockedLevel));

    return result;
  }

  static List<AvatarItem> get orderedItems {
    final list = _items.values.toList();

    list.sort((a, b) => a.category.order.compareTo(b.category.order));

    return list;
  }

  static void registerItem(AvatarItem item) {
    _items[item.id] = item;
  }
}
