// ========================================
// TRANSLATION SERVICE FOR KBOOM
// ========================================

import 'package:get/get.dart';

class KboomTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        // ========================================
        // FRENCH TRANSLATIONS
        // ========================================
        'fr': {
          // =======================
          // GENERAL & STATES
          // =======================
          'app_title': 'Kboom',
          'loading': 'Connexion en cours...',
          'connected': 'Connecté',
          'disconnected': 'Déconnecté',
          'conn_error': 'Erreur de connexion',
          'cancel': 'Annuler',
          'validate': 'Valider',

          // =======================
          // HOME PAGE
          // =======================
          'app_subtitle': 'Un jeu multijoueur inspiré de Kaleidos',
          'join_room': 'Rejoindre une partie',
          'create_room': 'Créer une partie',
          'wake_up_message': 'Le serveur peut prendre jusqu\'à 60 secondes\npour démarrer s\'il était en veille',

          // =======================
          // CREATE PAGE
          // =======================
          'create_title': 'Créer une partie',
          'create_btn': 'Créer',

          // =======================
          // JOIN PAGE
          // =======================
          'join_title': 'Rejoindre une salle',
          'room_code_hint': 'Code de la salle',
          'room_code_empty': 'Entre un code de salle avant de continuer',
          'join_btn': 'Rejoindre',

          // =======================
          // PSEUDO DIALOG & ERRORS
          // =======================
          'pseudo_dialog_title': 'Choisis ton pseudo',
          'pseudo_hint': 'Entre ton pseudo ici',
          'pseudo_warning': '3-15 caractères recommandés',
          'pseudo_empty_error': 'Le pseudo ne peut pas être vide',
          'pseudo_short_error': 'Le pseudo doit faire au moins 3 caractères',
          'pseudo_exists_error': 'Pseudo déjà choisi',

          // =======================
          // PARAMETERS PAGE
          // =======================
          'settings': 'Paramètres',
          'save': 'Enregistrer',
          'pseudo': 'Pseudo',
          'language_label': 'Langue de l\'application',
          'language_fr': 'Français',
          'language_en': 'English',
          'lang_changed': 'Langue modifiée en Français',
          'rules': 'Règles du Jeu',
          'credits': 'Crédits',
        },

        // ========================================
        // ENGLISH TRANSLATIONS
        // ========================================
        'en': {
          // =======================
          // GENERAL & STATES
          // =======================
          'app_title': 'Kboom',
          'loading': 'Connecting...',
          'connected': 'Connected',
          'disconnected': 'Disconnected',
          'conn_error': 'Connection error',
          'cancel': 'Cancel',
          'validate': 'Validate',

          // =======================
          // HOME PAGE
          // =======================
          'app_subtitle': 'A multiplayer game inspired by Kaleidos',
          'join_room': 'Join a game',
          'create_room': 'Create a game',
          'wake_up_message': 'The server may take up to 60 seconds\nto start if it was asleep',

          // =======================
          // CREATE PAGE
          // =======================
          'create_title': 'Create a game',
          'create_btn': 'Create',

          // =======================
          // JOIN PAGE
          // =======================
          'join_title': 'Join a room',
          'room_code_hint': 'Room code',
          'room_code_empty': 'Enter a room code before continuing',
          'join_btn': 'Join',

          // =======================
          // PSEUDO DIALOG & ERRORS
          // =======================
          'pseudo_dialog_title': 'Choose your nickname',
          'pseudo_hint': 'Enter your nickname here',
          'pseudo_warning': '3-15 characters recommended',
          'pseudo_empty_error': 'Nickname cannot be empty',
          'pseudo_short_error': 'Nickname must be at least 3 characters',
          'pseudo_exists_error': 'Nickname already chosen',

          // =======================
          // PARAMETERS PAGE
          // =======================
          'settings': 'Settings',
          'save': 'Save',
          'pseudo': 'Nickname',
          'language_label': 'App Language',
          'language_fr': 'Français',
          'language_en': 'English',
          'lang_changed': 'Language changed to English',
          'rules': 'Rules',
          'credits': 'Credits',
        }
      };
}
