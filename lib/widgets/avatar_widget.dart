import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kboom/models/avatar_model.dart';
import 'package:kboom/utils/svg_cache.dart';

class AvatarWidget extends StatefulWidget {
  final AvatarData avatarData;
  final double size;
  final bool showShadow;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.avatarData,
    this.size = 120,
    this.showShadow = true,
    this.onTap,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  // Positions de base (avatar référence 160px)
  static const double _hatTop = 15;
  //static const double _eyesTop = 45;
  //static const double _eyesTopWithHat = 62;
  //static const double _mouthTopFactor = 0.74;

  static const double _defaultHatWidth = 54;
  static const double _defaultHatHeight = 54;

  //static const double _defaultEyesWidth = 36;
  //static const double _defaultEyesHeight = 36;

  //static const double _defaultMouthWidth = 32;
  //static const double _defaultMouthHeight = 32;

  @override
  Widget build(BuildContext context) {
    final hatItem = AvatarRegistry.getItem(widget.avatarData.hatId);

    //final eyesItem = AvatarRegistry.getItem(widget.avatarData.eyesId);

    //final mouthItem = AvatarRegistry.getItem(widget.avatarData.mouthId);

    final scaleFactor = widget.size / 160.0;

    /*final hatSize = _resolveItemSize(
      item: hatItem,
      fallbackWidth: _defaultHatWidth,
      fallbackHeight: _defaultHatHeight,
    );*/

    /*final eyesSize = _resolveItemSize(
      item: eyesItem,
      fallbackWidth: _defaultEyesWidth,
      fallbackHeight: _defaultEyesHeight,
    );*/

    //final mouthSize = _resolveItemSize(
    //  item: mouthItem,
    //  fallbackWidth: _defaultMouthWidth,
    //  fallbackHeight: _defaultMouthHeight,
    //);

    final backgroundItem = AvatarRegistry.getItem(
      widget.avatarData.backgroundId,
    );

    final backgroundPath =
        backgroundItem?.imageAsset ??
        'assets/images/backgrounds/deer_background.svg';

    final backgroundWidget = backgroundPath.toLowerCase().endsWith('.svg')
        ? FutureBuilder<String?>(
            future: SvgCache.load(backgroundPath),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return Container(color: Colors.grey);
              }

              return SvgPicture.string(
                snapshot.data!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
              );
            },
          )
        : Image.asset(
            backgroundPath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
          );

    const double overflowFactor = 1.6;

    final canvasSize = widget.size * overflowFactor;
    final avatarOffset = (canvasSize - widget.size) / 2;

    return GestureDetector(
      onTap: widget.onTap,

      child: SizedBox(
        width: canvasSize,
        height: canvasSize,

        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ==============================
            // BACKGROUND
            // ==============================
            Positioned(
              left: avatarOffset,
              top: avatarOffset,

              child: ClipOval(
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: backgroundWidget,
                ),
              ),
            ),

            // ==============================
            // HAT
            // ==============================
            /*if (hatItem != null && hatItem.id.isNotEmpty)
              Positioned(
                top:
                    avatarOffset +
                    (_hatTop * scaleFactor) -
                    (hatSize.height * hatItem.anchor.dy) +
                    (hatItem.offset.dy * scaleFactor),

                left:
                    avatarOffset +
                    (widget.size / 2) -
                    (hatSize.width * hatItem.anchor.dx) +
                    (hatItem.offset.dx * scaleFactor),

                child: _buildItemWidget(
                  hatItem,
                  width: hatSize.width,
                  height: hatSize.height,
                ),
              ),*/

            // ==============================
            // EYES
            // ==============================

            /*Positioned(
          top:
              avatarOffset +
              (((hatItem != null && hatItem.id.isNotEmpty)
                          ? _eyesTopWithHat
                          : _eyesTop) *
                      scaleFactor) -
              (eyesSize.height * (eyesItem?.anchor.dy ?? 0.5)) +
              ((eyesItem?.offset.dy ?? 0) * scaleFactor),

          left:
              avatarOffset +
              (widget.size / 2) -
              (eyesSize.width * (eyesItem?.anchor.dx ?? 0.5)) +
              ((eyesItem?.offset.dx ?? 0) * scaleFactor),

          child: eyesItem != null && eyesItem.id.isNotEmpty
              ? _buildItemWidget(
                  eyesItem,
                  width: eyesSize.width,
                  height: eyesSize.height,
                )
              : Text(
                  '👁️👁️',
                  style: TextStyle(
                    fontSize: 32 * scaleFactor,
                  ),
                ),
        ),*/

            // ==============================
            // MOUTH
            // ==============================

            /*Positioned(
          top:
              avatarOffset +
              (widget.size * _mouthTopFactor) -
              (mouthSize.height * (mouthItem?.anchor.dy ?? 0.5)) +
              ((mouthItem?.offset.dy ?? 0) * scaleFactor),

          left:
              avatarOffset +
              (widget.size / 2) -
              (mouthSize.width * (mouthItem?.anchor.dx ?? 0.5)) +
              ((mouthItem?.offset.dx ?? 0) * scaleFactor),

          child: mouthItem != null && mouthItem.id.isNotEmpty
              ? _buildItemWidget(
                  mouthItem,
                  width: mouthSize.width,
                  height: mouthSize.height,
                )
              : Text(
                  '👄',
                  style: TextStyle(
                    fontSize: 28 * scaleFactor,
                  ),
                ),
        ),*/
          ],
        ),
      ),
    );
  }

  Size _resolveItemSize({
    required AvatarItem? item,
    required double fallbackWidth,
    required double fallbackHeight,
  }) {
    if (item == null) {
      return Size(fallbackWidth, fallbackHeight);
    }

    final scale = widget.size / 160.0;

    return Size(
      (item.width ?? fallbackWidth) * scale * item.scale,

      (item.height ?? fallbackHeight) * scale * item.scale,
    );
  }

  Widget _buildItemWidget(
    AvatarItem item, {
    required double width,
    required double height,
  }) {
    final shouldTint = item.useTintColor && item.color != null;

    final tint = shouldTint ? item.color : null;

    switch (item.assetType) {
      // ==================================
      // IMAGE PNG / WEBP / SVG
      // ==================================

      case AvatarAssetType.imageAsset:
        if (item.imageAsset == null || item.imageAsset!.isEmpty) {
          return Text(item.emoji ?? '', style: TextStyle(fontSize: width));
        }

        final path = item.imageAsset!.toLowerCase();

        if (path.endsWith('.svg')) {
          return FutureBuilder<String?>(
            future: SvgCache.load(item.imageAsset!),

            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  width: width,
                  height: height,

                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                return SizedBox(
                  width: width,
                  height: height,

                  child: SvgPicture.string(snapshot.data!, fit: BoxFit.contain),
                );
              }

              return Text(item.emoji ?? '❓', style: TextStyle(fontSize: width));
            },
          );
        }

        return Image.asset(
          item.imageAsset!,

          width: width,
          height: height,

          fit: BoxFit.contain,

          color: tint,

          colorBlendMode: tint != null ? BlendMode.srcIn : BlendMode.dst,

          errorBuilder: (context, error, stackTrace) {
            return Text(item.emoji ?? '❓', style: TextStyle(fontSize: width));
          },
        );

      // ==================================
      // SPRITESHEET
      // ==================================

      case AvatarAssetType.spriteSheet:
        if (item.imageAsset != null && item.spriteSourceRect != null) {
          final rect = item.spriteSourceRect!;

          return SizedBox(
            width: width,
            height: height,

            child: ClipRect(
              child: Align(
                alignment: Alignment(
                  -(rect.left / rect.width) * 2 + 1,

                  -(rect.top / rect.height) * 2 + 1,
                ),

                child: Image.asset(item.imageAsset!, fit: BoxFit.none),
              ),
            ),
          );
        }

        return Text(item.emoji ?? '', style: TextStyle(fontSize: width));

      // ==================================
      // EMOJI
      // ==================================

      case AvatarAssetType.emoji:
      default:
        return Text(item.emoji ?? '', style: TextStyle(fontSize: width));
    }
  }
}
