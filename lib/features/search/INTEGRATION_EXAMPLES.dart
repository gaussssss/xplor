// EXEMPLE D'INTÉGRATION COMPLET

// 1. Dans main.dart
// ==============
/*
import 'package:flutter/material.dart';
import 'features/search/injection.dart';
import 'features/explorer/presentation/pages/explorer_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le module de recherche
  final searchDeps = await initializeSearchModule();

  runApp(MyApp(
    searchDeps: searchDeps,
  ));
}

class MyApp extends StatelessWidget {
  final ({
    SearchFiles searchFiles,
    BuildIndex buildIndex,
    UpdateIndex updateIndex,
    GetIndexStatus getIndexStatus,
  }) searchDeps;

  const MyApp({required this.searchDeps});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExplorerPage(
        searchFiles: searchDeps.searchFiles,
        buildIndex: searchDeps.buildIndex,
        updateIndex: searchDeps.updateIndex,
        getIndexStatus: searchDeps.getIndexStatus,
      ),
    );
  }
}
*/

// 2. Dans explorer_page.dart
// ===========================
/*
class ExplorerPage extends StatefulWidget {
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

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  late ExplorerViewModel _explorerViewModel;
  late SearchViewModel _searchViewModel;

  @override
  void initState() {
    super.initState();

    // Initialiser les ViewModels
    final initialPath = Platform.environment['HOME'] ?? '/';
    final repository = FileSystemRepositoryImpl(LocalFileSystemDataSource());

    _explorerViewModel = ExplorerViewModel(
      // ... autre usecases ...
      searchFiles: widget.searchFiles,
      buildIndex: widget.buildIndex,
      updateIndex: widget.updateIndex,
      getIndexStatus: widget.getIndexStatus,
      initialPath: initialPath,
    );

    _searchViewModel = SearchViewModel(
      searchFiles: widget.searchFiles,
      buildIndex: widget.buildIndex,
      updateIndex: widget.updateIndex,
      getIndexStatus: widget.getIndexStatus,
    );

    // Initialiser le bootstrap
    _explorerViewModel.bootstrap();
  }

  // Fonction pour ouvrir la recherche globale
  Future<void> _openGlobalSearch() async {
    final query = await _showSearchDialog();
    if (query == null || query.trim().isEmpty) return;

    // Effectuer la recherche
    await _explorerViewModel.globalSearch(query);

    // Afficher les résultats
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            results: _explorerViewModel.globalSearchResults,
            query: query,
            isLoading: false,
            onResultTap: (result) {
              // Naviguer vers le fichier/dossier
              if (result.isDirectory) {
                _explorerViewModel.loadDirectory(result.path);
              } else {
                // Ouvrir le dossier parent
                _explorerViewModel.loadDirectory(result.parentPath);
              }
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  Future<String?> _showSearchDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche globale'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Entrez votre recherche...',
            prefixIcon: Icon(LucideIcons.search),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... votre UI habituelle ...
      floatingActionButton: FloatingActionButton(
        onPressed: _openGlobalSearch,
        tooltip: 'Recherche globale',
        child: const Icon(LucideIcons.search),
      ),
    );
  }

  @override
  void dispose() {
    _explorerViewModel.dispose();
    super.dispose();
  }
}
*/

// 3. Utilisation avancée
// =======================
/*
// Dans un ViewModel custom
class AdvancedSearchViewModel extends ChangeNotifier {
  final SearchViewModel searchViewModel;

  AdvancedSearchViewModel(this.searchViewModel);

  Future<void> searchByExtension(String extension, String rootPath) async {
    final allResults = await searchViewModel._searchFiles(
      '*.$extension',
      rootPath: rootPath,
    );
    // Filtrer les résultats...
  }

  Future<void> searchBySize({
    required int minSize,
    required int maxSize,
    required String rootPath,
  }) async {
    final allResults = await searchViewModel._searchFiles(
      '*',
      rootPath: rootPath,
      maxResults: 1000,
    );
    
    final filtered = allResults
        .where((r) => r.size >= minSize && r.size <= maxSize)
        .toList();
    
    notifyListeners();
  }
}
*/
