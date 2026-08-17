import 'package:flutter/services.dart';

class SvgCache {
  SvgCache._();

  static final Map<String, Future<String?>> _cache = {};

  static Future<String?> load(String assetPath) {
    return _cache.putIfAbsent(
      assetPath,
      () async {
        try {
          final rawSvg =
              await rootBundle.loadString(assetPath);

          return _prepareSvg(rawSvg);
        } catch (_) {
          return null;
        }
      },
    );
  }


  static String _prepareSvg(String svgContent) {

    final styleMatches =
        RegExp(
          r'\.([A-Za-z0-9_-]+)\s*\{([^{}]+)\}',
        ).allMatches(svgContent);


    if (styleMatches.isEmpty) {
      return svgContent;
    }


    final styles = <String, String>{};


    for (final match in styleMatches) {

      final className =
          match.group(1);

      final declarations =
          match.group(2)?.trim();


      if (className != null &&
          declarations != null &&
          declarations.isNotEmpty) {

        styles[className] =
            declarations;
      }
    }


    return svgContent.replaceAllMapped(
      RegExp(
        r'class="([^"]*)"',
      ),

      (match) {

        final classes =
            match
                .group(1)
                ?.split(
                  RegExp(r'\s+'),
                ) ??
            [];


        final declarations =
            classes
                .where(
                  styles.containsKey,
                )
                .map(
                  (e) => styles[e]!,
                )
                .join('; ');


        if (declarations.isEmpty) {
          return match.group(0)!;
        }


        return 'style="$declarations"';
      },
    );
  }
}