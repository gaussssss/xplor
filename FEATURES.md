# Fonctionnalités Xplor

## Structure du projet

### Features implémentées

#### 1. Explorer (`lib/features/explorer/`)
Explorateur de fichiers principal avec :
- Vue grille et liste
- Sélection multiple
- Drag & drop depuis/vers Finder
- Gestion avancée des doublons (remplacer, dupliquer, ignorer)
- Navigation avec historique
- Recherche et filtres

#### 2. Settings (`lib/features/settings/`)
Pages de paramètres et informations :
- **À propos** (`about_page.dart`) : Informations sur le projet et contributeurs
- **CGU** (`terms_of_service_page.dart`) : Conditions générales d'utilisation

#### 3. Onboarding (`lib/features/onboarding/`)
Système d'onboarding au premier lancement :
- **OnboardingPage** : 5 étapes de présentation
- **OnboardingService** : Gestion de l'état (SharedPreferences)
- Affichage automatique au premier lancement
- Mémorisation de la complétion

## Fonctionnalités détaillées

### Gestion des doublons lors du drag & drop

Lorsque vous déposez des fichiers qui existent déjà, un dialogue glassmorphique apparaît avec :

**Options par fichier** :
- **Remplacer** : Écrase le fichier existant
- **Dupliquer** : Crée une copie avec un nouveau nom (ex: "fichier copie.txt")
- **Ne pas copier** : Ignore ce fichier

**Mode batch** :
- Case "Appliquer la même action à tous les fichiers"
- Applique l'action sélectionnée à tous les doublons en une fois
- Champ de renommage pour l'option "Dupliquer"

**Comportement** :
- Les fichiers sans conflit sont copiés automatiquement
- Seuls les fichiers en doublon nécessitent une action
- Interface scrollable pour gérer plusieurs doublons

### Menu latéral

Le menu déplié contient une nouvelle section **AIDE** avec :
- **À propos** : Présentation du projet, version, contributeurs, liens utiles
- **CGU** : Conditions d'utilisation détaillées

### Onboarding

Au premier lancement, l'utilisateur voit 5 écrans :
1. Bienvenue dans Xplor
2. Vue grille ou liste
3. Glisser-déposer
4. Recherche rapide
5. Personnalisation

Navigation :
- Boutons "Précédent" / "Suivant" / "Passer"
- Indicateurs de progression
- Bouton "Terminer" sur la dernière page

## Classes et fichiers clés

### Gestion des doublons

```dart
// Enum pour les types d'actions
enum DuplicateActionType {
  replace,   // Remplacer
  duplicate, // Dupliquer
  skip,      // Ignorer
}

// Classe pour stocker une action
class DuplicateAction {
  final DuplicateActionType type;
  final String? newName; // Utilisé pour 'duplicate'
}
```

**Fichiers** :
- [explorer_page.dart](lib/features/explorer/presentation/pages/explorer_page.dart) : Logique de drag & drop et dialogue
- `_DuplicateDialog` : Widget du dialogue glassmorphique

### Onboarding

**Fichiers** :
- [onboarding_page.dart](lib/features/onboarding/presentation/pages/onboarding_page.dart) : Page principale avec PageView
- [onboarding_service.dart](lib/features/onboarding/data/onboarding_service.dart) : Service de persistance
- [app.dart](lib/app.dart) : Vérification au démarrage

**Méthodes principales** :
```dart
// Vérifier si complété
await OnboardingService.isOnboardingCompleted()

// Marquer comme complété
await OnboardingService.setOnboardingCompleted(true)

// Réinitialiser (debug)
await OnboardingService.resetOnboarding()
```

### Pages Settings

**À propos** : [about_page.dart](lib/features/settings/presentation/pages/about_page.dart)
- Logo et version
- Description du projet
- Liste des contributeurs avec avatars
- Liens utiles (GitHub, bugs, support)

**CGU** : [terms_of_service_page.dart](lib/features/settings/presentation/pages/terms_of_service_page.dart)
- 7 sections : Acceptation, Licence, Utilisation, Données, Responsabilité, Modifications, Contact
- Interface glassmorphique
- Contenu scrollable

## Design

Toutes les interfaces suivent le design glassmorphique de Xplor :
- Fond semi-transparent avec flou (BackdropFilter)
- Bordures subtiles avec couleur primaire
- Animations fluides
- Adaptation aux thèmes clair/sombre
