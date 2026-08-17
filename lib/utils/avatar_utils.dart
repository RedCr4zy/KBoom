import 'package:flutter/material.dart';

class AvatarUtils {
  AvatarUtils._();

  static Color parseHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(
        int.parse(
          "FF$cleaned",
          radix: 16,
        ),
      );
    } catch (_) {
      return const Color(0xFFFF5733);
    }
  }
}