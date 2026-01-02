import '../search/data/datasources/sqlite_search_impl.dart';
import '../search/data/repositories/search_repository_impl.dart';
import '../search/domain/usecases/build_index.dart';
import '../search/domain/usecases/get_index_status.dart';
import '../search/domain/usecases/search_files.dart';
import '../search/domain/usecases/update_index.dart';

/// Initialise les dépendances du module de recherche
({
  SearchFiles searchFiles,
  BuildIndex buildIndex,
  UpdateIndex updateIndex,
  GetIndexStatus getIndexStatus,
})
initializeSearchModule() {
  // Initialiser la base de données
  final database = SqliteSearchDatabase();
  // Note: L'initialisation asynchrone se fera lors du premier appel à search/build

  // Créer le repository
  final searchRepository = SearchRepositoryImpl(database);

  // Créer les usecases
  final searchFiles = SearchFiles(searchRepository);
  final buildIndex = BuildIndex(searchRepository);
  final updateIndex = UpdateIndex(searchRepository);
  final getIndexStatus = GetIndexStatus(searchRepository);

  return (
    searchFiles: searchFiles,
    buildIndex: buildIndex,
    updateIndex: updateIndex,
    getIndexStatus: getIndexStatus,
  );
}
