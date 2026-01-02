/// Feature flags pour activer/désactiver progressivement les nouvelles fonctionnalités
/// Permet un rollback facile et un déploiement incrémental
class FeatureFlags {
  FeatureFlags._();

  // ============================================================================
  // PHASE 1 & 2: DESIGN SYSTEM & GLASSMORPHISM
  // ============================================================================

  /// Utiliser le nouveau système de palettes de couleurs configurables
  /// TRUE = 4 palettes disponibles (Modern Tech, Neon Cyberpunk, Warm Sunset, Deep Ocean)
  /// FALSE = Utiliser l'ancien système de couleurs
  static const bool useColorPalettes = true;

  /// Utiliser le nouveau Glassmorphism V2 avec BackdropFilter
  /// TRUE = GlassPanelV2 avec blur et effets avancés
  /// FALSE = Utiliser l'ancien GlassPanel simple
  static const bool useNewGlassmorphism = true; // Activé pour Phase 2

  // ============================================================================
  // PHASE 3: ANIMATIONS RICHES
  // ============================================================================

  /// Utiliser les animations riches (micro-interactions, hover effects, etc.)
  /// TRUE = Animations fluides et élégantes partout
  /// FALSE = Animations minimales (performances)
  static const bool useRichAnimations = false; // Désactivé par défaut, activé en Phase 3

  /// Utiliser les effets de glow sur les éléments interactifs
  /// (Particulièrement prononcé avec Neon Cyberpunk)
  /// TRUE = Glows actifs selon la palette
  /// FALSE = Pas d'effets de glow
  static const bool useGlowEffects = false; // Désactivé par défaut

  // ============================================================================
  // PHASE 4: MODE COMPACT
  // ============================================================================

  /// Activer le mode compact (vue dense)
  /// TRUE = Toggle compact mode disponible dans la toolbar
  /// FALSE = Seulement mode normal
  static const bool enableCompactMode = false; // Désactivé par défaut, activé en Phase 4

  // ============================================================================
  // PHASE 5: FEATURES AVANCÉES
  // ============================================================================

  /// Activer la command palette (Cmd+K)
  /// TRUE = Command palette disponible
  /// FALSE = Pas de command palette
  static const bool enableCommandPalette = false; // Désactivé par défaut, activé en Phase 5

  /// Activer le preview panel (aperçu de fichiers)
  /// TRUE = Preview panel disponible
  /// FALSE = Pas de preview
  static const bool enablePreviewPanel = false; // Désactivé par défaut, activé en Phase 5

  /// Utiliser les rich tooltips (avec shortcuts et descriptions)
  /// TRUE = Tooltips riches avec glassmorphism
  /// FALSE = Tooltips basiques Flutter
  static const bool useRichTooltips = false; // Désactivé par défaut

  /// Activer le drag & drop de tags sur les fichiers
  /// TRUE = Tags assignables et persistants
  /// FALSE = Tags seulement pour filtrage (pas assignables)
  static const bool enableDraggableTags = false; // Désactivé par défaut

  /// Utiliser les loading states élégants (skeleton loaders, etc.)
  /// TRUE = Loading states animés et stylisés
  /// FALSE = Loading states basiques (CircularProgressIndicator)
  static const bool useAdvancedLoadingStates = false; // Désactivé par défaut

  // ============================================================================
  // PHASE 6: POLISH & OPTIMISATIONS
  // ============================================================================

  /// Activer le sélecteur de palette (Cmd+T)
  /// TRUE = Widget de sélection de palette disponible
  /// FALSE = Changement de palette seulement via code/settings
  static const bool enablePaletteSelector = false; // Désactivé par défaut, activé en Phase 6

  /// Activer le mode "Reduce Motion" (accessibilité)
  /// TRUE = Désactive les animations complexes pour performances/accessibilité
  /// FALSE = Toutes les animations actives
  static const bool reduceMotion = false;

  /// Activer le mode performance (désactive certains effets coûteux)
  /// TRUE = Désactive blur, glows et ombres complexes
  /// FALSE = Tous les effets visuels actifs
  static const bool performanceMode = false;

  // ============================================================================
  // DÉVELOPPEMENT & DEBUG
  // ============================================================================

  /// Afficher des logs de debug pour le theme provider
  /// TRUE = Console logs pour les changements de palette
  /// FALSE = Pas de logs
  static const bool debugThemeChanges = false;

  /// Afficher des overlays de debug pour les animations
  /// TRUE = Indicateurs visuels des zones animées
  /// FALSE = Pas d'overlays
  static const bool debugAnimations = false;

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Vérifie si toutes les features de la Phase 1 sont actives
  static bool get isPhase1Complete => useColorPalettes;

  /// Vérifie si toutes les features de la Phase 2 sont actives
  static bool get isPhase2Complete => isPhase1Complete && useNewGlassmorphism;

  /// Vérifie si toutes les features de la Phase 3 sont actives
  static bool get isPhase3Complete =>
      isPhase2Complete && useRichAnimations && useGlowEffects;

  /// Vérifie si toutes les features de la Phase 4 sont actives
  static bool get isPhase4Complete => isPhase3Complete && enableCompactMode;

  /// Vérifie si toutes les features de la Phase 5 sont actives
  static bool get isPhase5Complete =>
      isPhase4Complete &&
      enableCommandPalette &&
      enablePreviewPanel &&
      useRichTooltips &&
      enableDraggableTags &&
      useAdvancedLoadingStates;

  /// Vérifie si toutes les features de la Phase 6 sont actives
  static bool get isPhase6Complete =>
      isPhase5Complete && enablePaletteSelector;

  /// Vérifie si TOUTES les features sont actives (redesign complet)
  static bool get isRedesignComplete => isPhase6Complete;
}
