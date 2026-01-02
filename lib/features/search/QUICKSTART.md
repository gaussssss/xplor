# 🚀 Démarrage Rapide - Module de Recherche

## Installation (3 étapes)

### 1. Mettre à jour les dépendances
```bash
cd /Users/pro/Documents/Mes\ projets/Explorer/xplor
flutter pub get
```

### 2. Intégrer dans main.dart
```dart
import 'lib/features/search/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialiser le module de recherche
  final searchDeps = await initializeSearchModule();
  
  runApp(MyApp(searchDeps: searchDeps));
}

class MyApp extends StatelessWidget {
  final ({
    SearchFiles searchFiles,
    BuildIndex buildIndex,
    UpdateIndex updateIndex,
    GetIndexStatus getIndexStatus,
  }) searchDeps;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExplorerPage(
        // Passer les dépendances
        searchFiles: searchDeps.searchFiles,
        buildIndex: searchDeps.buildIndex,
        updateIndex: searchDeps.updateIndex,
        getIndexStatus: searchDeps.getIndexStatus,
      ),
    );
  }
}
```

### 3. Modifier explorer_page.dart
```dart
class ExplorerPage extends StatefulWidget {
  // ✅ Ajouter ces paramètres
  final SearchFiles searchFiles;
  final BuildIndex buildIndex;
  final UpdateIndex updateIndex;
  final GetIndexStatus getIndexStatus;

  const ExplorerPage({
    required this.searchFiles,
    required this.buildIndex,
    required this.updateIndex,
    required this.getIndexStatus,
  });

  // ... reste du code
}

class _ExplorerPageState extends State<ExplorerPage> {
  @override
  void initState() {
    super.initState();
    
    // ✅ Créer le ViewModel avec les dépendances
    _viewModel = ExplorerViewModel(
      // ... autres usecases ...
      searchFiles: widget.searchFiles,
      buildIndex: widget.buildIndex,
      updateIndex: widget.updateIndex,
      getIndexStatus: widget.getIndexStatus,
      initialPath: initialPath,
    );
  }
}
```

## Utilisation basique

### Recherche simple
```dart
// Dans votre ViewModel ou Page
await _viewModel.globalSearch("monFichier");
final results = _viewModel.globalSearchResults;

// Afficher les résultats
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SearchResultsPage(
      results: results,
      query: "monFichier",
      isLoading: false,
    ),
  ),
);
```

### Construire l'index
```dart
// Au premier lancement
await _viewModel.buildSearchIndex();

// Ou manuellement
await _viewModel.updateSearchIndex();
```

## API Rapide

### ExplorerViewModel
```dart
// Recherche globale
Future<void> globalSearch(String query)

// Gestion de l'index
Future<void> buildSearchIndex()
Future<void> updateSearchIndex()

// Accès aux résultats
List<SearchResult> get globalSearchResults
```

### Modèle SearchResult
```dart
class SearchResult {
  String path;          // Chemin complet
  String name;          // Nom du fichier
  bool isDirectory;     // Est un dossier?
  int size;             // Taille en octets
  DateTime lastModified; // Date de modification
  String parentPath;    // Dossier parent
  double relevance;     // Score 0.0-1.0
}
```

## Exemple complet

```dart
import 'package:xplor/features/search/presentation/pages/search_results_page.dart';

class MyExplorerPage extends StatefulWidget {
  @override
  State<MyExplorerPage> createState() => _MyExplorerPageState();
}

class _MyExplorerPageState extends State<MyExplorerPage> {
  late ExplorerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExplorerViewModel(
      // ... configurations
      searchFiles: widget.searchFiles,
      buildIndex: widget.buildIndex,
      updateIndex: widget.updateIndex,
      getIndexStatus: widget.getIndexStatus,
      initialPath: '/Users/pro/Documents',
    );
  }

  Future<void> _handleSearch() async {
    final query = 'fichier important';
    
    // Effectuer la recherche
    await _viewModel.globalSearch(query);
    
    // Naviguer vers la page de résultats
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            results: _viewModel.globalSearchResults,
            query: query,
            isLoading: false,
            onResultTap: (result) {
              // Naviguer vers le fichier trouvé
              if (result.isDirectory) {
                _viewModel.loadDirectory(result.path);
              }
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explorer'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _handleSearch,
            tooltip: 'Recherche globale',
          ),
        ],
      ),
      body: Center(
        child: Text('Explorer content'),
      ),
    );
  }
}
```

## Résolution de problèmes

### "Cannot find 'sqflite'"
```bash
flutter pub get
```

### "Database not initialized"
Vérifier que `initializeSearchModule()` a été appelé dans `main.dart`

### La recherche retourne zéro résultats
1. Vérifier que l'index a été construit
2. Appeler `buildSearchIndex()` manuellement
3. Vérifier les permissions d'accès aux dossiers

### L'indexation est lente
- C'est normal pour les premiers 100k fichiers
- Les recherches suivantes sont rapides (< 100ms)
- L'index se met à jour auto après 1 heure

## Fichiers importants

- 📄 [lib/features/search/README.md](./README.md) - Documentation complète
- 📄 [lib/features/search/IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) - Détails techniques
- 📄 [lib/features/search/INTEGRATION_EXAMPLES.dart](./INTEGRATION_EXAMPLES.dart) - Exemples avancés

## ✅ Checklist de validation

- [ ] `flutter pub get` exécuté
- [ ] `main.dart` intégré
- [ ] `explorer_page.dart` modifié
- [ ] Compilation sans erreur
- [ ] Recherche fonctionne
- [ ] Résultats affichés correctement

## 🆘 Support

Voir les fichiers de documentation dans `lib/features/search/`
