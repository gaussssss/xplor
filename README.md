# 🗂️ Xplor

Un gestionnaire de fichiers moderne et élégant pour macOS, construit avec Flutter. Xplor redéfinit l'expérience de navigation dans le système de fichiers avec une interface inspirée de Windows Explorer et un design futuriste.

> **Une ergonomie Windows Explorer + Design moderne = Productivité macOS**

---

## ✨ Caractéristiques principales

### 📁 Navigation intuitive
- Accès complet au système de fichiers
- **Breadcrumbs** cliquables pour navigation rapide
- Barre de chemin complète
- Boutons de navigation (Retour, Suivant, Dossier parent)
- Favoris et dossiers épinglés

### 👁️ Modes d'affichage
- **Vue Liste** : affichage détaillé avec nom, type, taille et date de modification
- **Vue Grille** : affichage d'icônes compacts
- Basculement facile entre les modes

### 🔍 Recherche puissante
- Recherche en temps réel par nom ou extension
- Filtrage sur le dossier courant
- Résultats instantanés

### ⚡ Actions fichiers complètes
- Créer un dossier
- Renommer fichiers et dossiers
- Copier / Couper / Coller
- Supprimer (gestion de la corbeille)
- Glisser-déposer entre dossiers
- **Sélection multiple** (Cmd/Shift)
- Menu contextuel au clic droit
- Ouverture avec double-clic
- Affichage dans Finder
- Duplication de fichiers
- Déplacement vers un autre chemin
- Rafraîchissement manuel

### 🎨 Design moderne et productif
- **Thème sombre futuriste** par défaut
- Composants reutilisables (GlassPanel, ToolbarButton, etc.)
- Interface inspirée de Windows 11
- Animations fluides et réactives
- Effets visuels épurés

### 🛡️ Gestion d'état robuste
- Affichage des états de chargement
- Messages d'erreur clairs avec retry
- Gestion des dossiers vides
- Affichage des restrictions d'accès

---

## 🏗️ Architecture

Le projet suit une architecture **Clean Architecture + MVVM** avec séparation claire des responsabilités :

```
lib/
├── app.dart                           # Bootstrap et configuration du thème
├── main.dart                          # Point d'entrée
├── core/                              # Code partagé
│   ├── config/                        # Configuration
│   ├── constants/                     # Constantes globales
│   ├── providers/                     # Providers partagés
│   ├── theme/                         # Thème et styles
│   └── widgets/                       # Composants réutilisables
└── features/explorer/                 # Feature Explorer
    ├── domain/                        # Logique métier
    │   ├── entities/                  # Modèles de domaine
    │   ├── repositories/              # Interfaces des repositories
    │   └── usecases/                  # Cas d'usage
    ├── data/                          # Accès aux données
    │   ├── datasources/               # Sources de données locales
    │   └── repositories/              # Implémentation des repositories
    └── presentation/                  # Interface utilisateur
        ├── viewmodels/                # ViewModels (état et logique UI)
        ├── pages/                     # Pages principales
        └── widgets/                   # Composants UI
```

### Principes d'architecture
- **Séparation des préoccupations** : Domain → Data → Presentation
- **Dépendance inversée** : les couches supérieures ne dépendent que des abstractions
- **Réutilisabilité** : composants et logique partagés dans `core/`
- **Testabilité** : repositories abstraits facilitent les tests unitaires

---

## 🚀 Démarrage rapide

### Prérequis
- **Flutter SDK** : `^3.9.2`
- **macOS** : cible desktop
- **Xcode** : pour la compilation sur macOS

### Installation

1. **Cloner le repository**
   ```bash
   git clone <repository-url>
   cd xplor
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   # Sur macOS (desktop)
   flutter run -d macos
   
   # Ou simplement
   flutter run
   ```

### Build de release
```bash
flutter build macos --release
```

L'application compilée se trouve dans `build/macos/Build/Products/Release/Runner.app`

---

## 📦 Dépendances principales

| Dépendance | Utilisation |
|-----------|-------------|
| **provider** | Gestion d'état et injection de dépendances |
| **shared_preferences** | Persistance des préférences utilisateur |
| **path_provider** | Accès aux chemins du système |
| **file_picker** | Sélection de fichiers |
| **file_selector** | Sélection avancée de fichiers |
| **fluent_ui** | Composants UI style Fluent (Windows) |
| **macos_ui** | Composants natifs macOS |
| **lucide_icons** | Bibliothèque d'icônes modernes |
| **bitsdojo_window** | Configuration fenêtre desktop |
| **another_flushbar** | Notifications visuelles |
| **mix** | Styling avancé |
| **shadcn_ui** | Composants UI modernes |

---

## 🎯 Flux utilisateur principal

1. **Ouverture** → Affichage du dossier d'accueil
2. **Navigation** → Clic sur dossier ou breadcrumb
3. **Actions** → Menu contextuel ou glisser-déposer
4. **Recherche** → Filtrage en temps réel
5. **Résultat** → Affichage et modification des fichiers

---

## 🔧 Utilisation courante

### Raccourcis clavier (à implémenter)
- `Cmd + N` : Nouveau dossier
- `Cmd + F` : Recherche
- `Cmd + C` : Copier
- `Cmd + X` : Couter
- `Cmd + V` : Coller
- `Cmd + ↑` : Dossier parent

### Sélection multiple
- `Cmd + Clic` : Ajouter à la sélection
- `Shift + Clic` : Sélectionner plage
- `Clic long` : Sélectionner

---

## 📱 Plates-formes supportées

- ✅ **macOS** (cible principale)
- 🔄 **iOS** (structure préparée)
- 🔄 **Linux** (structure préparée)
- 🔄 **Windows** (structure préparée)
- 🔄 **Web** (structure préparée)

---

## 📂 Structure des fichiers importants

- [lib/app.dart](lib/app.dart) : Configuration et théming de l'application
- [lib/main.dart](lib/main.dart) : Point d'entrée
- [lib/features/explorer/presentation/pages/](lib/features/explorer/presentation/pages/) : Pages principales
- [lib/core/theme/](lib/core/theme/) : Thème et constantes UI
- [lib/core/widgets/](lib/core/widgets/) : Composants réutilisables

---

## 🐛 Dépannage

### L'application ne démarre pas
```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter run -d macos
```

### Erreur de compilation
```bash
# Vérifier les prérequis
flutter doctor -v

# Mettre à jour les dépendances
flutter pub upgrade
```

### Problèmes de permissions
- Vérifier que l'app a les permissions d'accès aux fichiers dans Système > Sécurité et confidentialité

---

## 📝 Conventions de code

- **Nommage** : camelCase pour les variables/méthodes, PascalCase pour les classes
- **Fichiers** : snake_case pour les noms de fichiers
- **Commentaires** : Documenter le "pourquoi", pas le "quoi"
- **Tests** : Un fichier test par fichier source

---

## 🎨 Personnalisation

### Modifier le thème
Éditer [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) pour ajuster :
- Couleurs primaires
- Polices de caractères
- Taille des composants
- Animations

### Ajouter un nouveau dossier favori
Éditer la liste dans [lib/features/explorer/presentation/](lib/features/explorer/presentation/)

---

## 📚 Documentation additionnelle

- [Spécifications fonctionnelles](docs/context.md) - Vision produit détaillée
- [Fonctionnalités implémentées](docs/features.md) - État d'avancement
- [Architecture Clean Architecture + MVVM](https://resocoder.com/flutter-clean-architecture)

---

## 🤝 Contribution

Les contributions sont bienvenues ! Pour proposer une amélioration :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📄 Licence

Ce projet est privé. Tous les droits sont réservés.

---

## 👨‍💻 Auteur

Développé avec ❤️ pour macOS

---

## 🗺️ Roadmap future

- [ ] Raccourcis clavier complets
- [ ] Historique de navigation
- [ ] Dossiers personnalisables
- [ ] Thème clair
- [ ] Synchronisation cloud
- [ ] Recherche avancée (contenu, métadonnées)
- [ ] Actions batch
- [ ] Extensions plugins
- [ ] Support iOS/Linux/Windows

---

**Dernière mise à jour :** janvier 2026
