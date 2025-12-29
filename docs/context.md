# Xplor  
## Cahier des spécifications fonctionnelles

---

## 1. Vision du produit

**Nom provisoire :** Xplor

**Objectif :**  
Créer un gestionnaire de fichiers pour macOS destiné à remplacer Finder, en proposant :
- une ergonomie inspirée de l’Explorateur Windows
- une interface moderne et futuriste
- une expérience fluide, rapide et personnalisable

**Proposition de valeur :**  
> Un explorateur de fichiers macOS moderne, élégant et productif, pensé pour les utilisateurs qui veulent plus que Finder.

---

## 2. Utilisateurs cibles

### 2.1 Profil utilisateur principal
- Utilisateur macOS
- Étudiant, développeur, créatif ou power user
- Utilisation intensive du système de fichiers
- Sensible à l’esthétique et à la personnalisation

### 2.2 Objectifs utilisateur
- Naviguer rapidement dans les fichiers
- Avoir une organisation claire des dossiers
- Réduire le nombre de clics pour les actions courantes
- Travailler dans un environnement visuellement agréable

---

## 3. Fonctionnalités de base

### 3.1 Navigation dans les fichiers
- Accès complet au système de fichiers selon permissions macOS
- Navigation par clic, double-clic et raccourcis clavier
- Boutons :
  - Retour
  - Suivant
  - Dossier parent
- Barre de chemin (breadcrumb) cliquable

---

### 3.2 Modes d’affichage
- Vue liste détaillée :
  - Nom
  - Type
  - Taille
  - Date de modification
- Vue icônes
- Vue colonnes (optionnelle)

---

### 3.3 Actions sur les fichiers
- Créer un dossier
- Renommer
- Copier / Couper / Coller
- Supprimer (via la corbeille)
- Glisser-déposer
- Sélection multiple (Shift / Cmd)

---

### 3.4 Recherche
- Barre de recherche intégrée
- Recherche par :
  - nom de fichier
  - extension
- Résultats affichés en temps réel

---

## 4. Interface utilisateur (UX / UI)

### 4.1 Direction artistique
- Inspiration : Windows Explorer (Windows 11)
- Style futuriste / moderne
- Thème sombre par défaut
- Coins arrondis
- Animations fluides
- Effets de profondeur légers

---

### 4.2 Structure de l’interface

#### Barre latérale gauche
- Favoris :
  - Bureau
  - Documents
  - Téléchargements
- Disques
- Dossiers épinglés
- Ajout / suppression de favoris

#### Barre supérieure
- Barre de chemin
- Barre de recherche
- Boutons de changement de vue

#### Zone centrale
- Liste ou grille des fichiers
- Icônes personnalisées
- Aperçu rapide optionnel

---

### 4.3 Personnalisation
- Choix du thème (dark / light / neon)
- Taille des icônes
- Police
- Densité d’affichage (compact / confortable)

---

## 5. Fonctionnalités avancées

### 5.1 Gestion des onglets
- Plusieurs dossiers ouverts dans une même fenêtre
- Glisser-déposer pour réorganiser les onglets
- Détacher un onglet dans une nouvelle fenêtre

---

### 5.2 Aperçu intelligent
- Aperçu images
- Aperçu PDF
- Aperçu fichiers texte / code (lecture seule)

---

### 5.3 Actions rapides
- Menu contextuel personnalisé
- Actions adaptées au type de fichier
- Raccourcis clavier configurables

---

### 5.4 Historique
- Dossiers récents
- Fichiers récemment modifiés

---

### 5.5 Mode développeur (optionnel)
- Affichage des chemins complets
- Copie rapide du chemin d’un fichier
- Affichage des permissions Unix

---

## 6. Contraintes techniques

### 6.1 Système
- Application macOS uniquement
- Respect des règles de sandboxing Apple
- Gestion explicite des permissions utilisateur

---

### 6.2 Performance
- Chargement rapide des dossiers volumineux
- Interface toujours réactive
- Traitement asynchrone des opérations lourdes

---

### 6.3 Sécurité
- Confirmation avant suppression
- Utilisation de la corbeille système
- Respect strict des permissions système

---

## 7. MVP et versions futures

### 7.1 MVP (Minimum Viable Product)
- Navigation dans les dossiers
- Vue liste et vue icônes
- Actions de base (copie, suppression, renommage)
- Interface moderne simple
- Barre latérale et recherche

---

### 7.2 Version finale
- Onglets
- Aperçus avancés
- Personnalisation complète
- Animations avancées
- Mode développeur

---

## 8. Évolutions possibles
- Plugins
- Synchronisation cloud
- Raccourcis automatisés
- Mode plein écran productivité

---

**Document destiné à servir de base au design, au développement et aux tests de l’application Xplor.**
