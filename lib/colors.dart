// lib/colors.dart
// Palette complète pour ton jeu : clair + sombre
// Chaque couleur a son équivalent Dark et une courte explication de son usage

import 'package:flutter/material.dart';
import 'package:kboom/game_variable.dart';


// === COULEURS PRINCIPALES ===
const Color kPrimary = Color(0xFF3B82F6); // Bleu principal - boutons, accents, éléments interactifs
const Color kPrimaryDark = Color(0xFF2563EB); // Variante foncée du bleu - état pressé/hover
const Color kPrimaryDarkTheme = Color(0xFF60A5FA); // Bleu plus clair pour contraste sur fond sombre

const Color kAccent = Color(0xFFF59E0B); // Jaune/orangé - éléments d'attention (timers, surbrillance)
const Color kAccentDark = Color(0xFFFACC15); // Jaune clair - bon contraste sur fond sombre

// === COULEURS D'ÉTAT ===
const Color kSuccess = Color(0xFF10B981); // Vert - validation, votes positifs
const Color kSuccessDark = Color(0xFF34D399); // Vert clair - succès sur fond sombre

const Color kDanger = Color(0xFFEF4444); // Rouge - refus, erreurs, éliminations
const Color kDangerDark = Color(0xFFF87171); // Rouge clair - danger sur fond sombre

const Color kWarning = Color(0xFFF97316); // Orange - malus, avertissement, timer critique
const Color kWarningDark = Color(0xFFFFA94D); // Orange plus doux - lisible sur fond sombre

// === FONDS ET SURFACES ===
const Color kBg = Color(0xFFF8FAFC); // Fond global clair - arrière-plan principal
const Color kBgDark = Color(0xFF0F172A); // Fond sombre - fond principal du thème sombre

const Color kSurface = Color(0xFFFFFFFF); // Fond des cartes, modales, panneaux
const Color kSurfaceDark = Color(0xFF1E293B); // Fond des surfaces sombres - cartes, menus

const Color kBorder = Color(0xFFE2E8F0); // Lignes, séparateurs, contours
const Color kBorderDark = Color(0xFF334155); // Bordures discrètes mais visibles sur fond sombre

// === TEXTE ===
const Color kTextPrimary = Color(0xFF0F172A); // Texte principal - titres, texte important
const Color kTextPrimaryDark = Color(0xFFF8FAFC); // Texte clair - sur fond sombre

const Color kTextSecondary = Color(0xFF475569); // Texte secondaire - descriptions, labels
const Color kTextSecondaryDark = Color(0xFFCBD5E1); // Texte secondaire clair - lisible sans éblouir

const Color kMuted = Color(0xFF94A3B8); // Éléments désactivés, placeholder, inactifs
const Color kMutedDark = Color(0xFF64748B); // Désactivés sur fond sombre

const Color kTextButton = Color(0xFF475569);
const Color kTextButtonDark = Color(0XFF1C2942);

// === ÉLÉMENTS SPÉCIAUX ===
const Color kModalOverlay = Color(0x80000000); // Fond semi-transparent pour modals / overlays
const Color kModalOverlayDark = Color(0x80FFFFFF); // Overlay clair pour fond sombre

// === FONCTIONS RAPIDES ===
// Ces getters te permettent de choisir automatiquement la bonne couleur
// selon le thème clair ou sombre (utile si tu veux simplifier ton code)

///Color adaptiveColor(Color light, Color dark, bool isDarkMode) =>
///    isDarkMode ? dark : light;

// Exemple d'utilisation dans ton code :
// backgroundColor: adaptiveColor(kBg, kBgDark, Theme.of(context).brightness == Brightness.dark),



// Ajoute ça à la fin de ton fichier colors.dart

extension ThemeColors on BuildContext {
  bool get isDark => GameVariables.generalInformation.isDarkMode.value;

  // === COULEURS PRINCIPALES ===
  Color get primaryColor => isDark ? kPrimaryDark : kPrimary;
  Color get primaryDarkColor => isDark ? kPrimaryDarkTheme : kPrimaryDark;

  Color get accentColor => isDark ? kAccentDark : kAccent;

  // === COULEURS D'ÉTAT ===
  Color get successColor => isDark ? kSuccessDark : kSuccess;
  Color get dangerColor => isDark ? kDangerDark : kDanger;
  Color get warningColor => isDark ? kWarningDark : kWarning;

  // === FONDS ET SURFACES ===
  Color get backgroundColor => isDark ? kBgDark : kBg;
  Color get surfaceColor => isDark ? kSurfaceDark : kSurface;
  Color get borderColor => isDark ? kBorderDark : kBorder;

  // === TEXTE ===
  Color get textColor => isDark ? kTextPrimaryDark : kTextPrimary;
  Color get textSecondaryColor => isDark ? kTextSecondaryDark : kTextSecondary;
  Color get mutedColor => isDark ? kMutedDark : kMuted;
  Color get buttonTextColor => isDark ? kTextButtonDark : kTextButton;
  Color get modalTextColor => isDark ? kPrimaryDark : kTextButtonDark;

  // === ÉLÉMENTS SPÉCIAUX ===
  Color get modalOverlayColor => isDark ? kModalOverlayDark : kModalOverlay;

  Color get whiteColor => Colors.white;
}