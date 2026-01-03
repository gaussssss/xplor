import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_utils;

import 'local_search_database.dart';

class SqliteSearchDatabase implements LocalSearchDatabase {
  late Database _db;
  static const String _dbName = 'search_index.db';
  static const int _dbVersion = 1;

  @override
  Future<void> initialize() async {
    final dbPath = await _getDatabasePath();
    print('🔍 SQLite: Initializing database at: $dbPath');
    try {
      _db = await openDatabase(dbPath, version: _dbVersion, onCreate: _onCreate);
      print('✅ SQLite: Database initialized successfully');
    } catch (e) {
      print('❌ SQLite: Initialization error: $e');
      rethrow;
    }
  }

  Future<String> _getDatabasePath() async {
    // Utiliser le répertoire cache de l'app (plus persistant que /tmp)
    // Sur macOS: ~/Library/Caches/<app_id>/
    final homeDir = Platform.environment['HOME'];
    if (homeDir == null || homeDir.isEmpty) {
      throw Exception('Cannot determine home directory');
    }
    
    final cacheDir = Directory('$homeDir/.xplor_cache');
    print('🔍 SQLite: Cache directory: ${cacheDir.path}');
    
    if (!await cacheDir.exists()) {
      print('🔍 SQLite: Creating cache directory...');
      await cacheDir.create(recursive: true);
      print('✅ SQLite: Cache directory created');
    }
    
    final dbPath = path_utils.join(cacheDir.path, _dbName);
    print('🔍 SQLite: Database path: $dbPath');
    return dbPath;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table pour les fichiers/dossiers indexés
    await db.execute('''
      CREATE TABLE file_index (
        id INTEGER PRIMARY KEY,
        path TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        name_lower TEXT NOT NULL,
        parent_path TEXT,
        is_directory INTEGER NOT NULL,
        size INTEGER DEFAULT 0,
        last_modified INTEGER DEFAULT 0,
        indexed_at INTEGER NOT NULL
      )
    ''');

    // Index pour les recherches rapides
    await db.execute('CREATE INDEX idx_name_lower ON file_index(name_lower)');

    await db.execute('CREATE INDEX idx_path ON file_index(path)');

    // Table pour les métadonnées d'indexation
    await db.execute('''
      CREATE TABLE index_metadata (
        root_path TEXT PRIMARY KEY,
        last_indexed_at INTEGER,
        file_count INTEGER DEFAULT 0
      )
    ''');
  }

  @override
  Future<void> createIndex(List<Map<String, dynamic>> nodes) async {
    final batch = _db.batch();

    for (final node in nodes) {
      batch.insert(
        'file_index',
        node,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<List<Map<String, dynamic>>> queryIndex(
    String rootPath, {
    required String query,
  }) async {
    final queryLower = query.toLowerCase();

    final results = await _db.query(
      'file_index',
      where: '(path = ? OR path LIKE ?) AND name_lower LIKE ?',
      whereArgs: [rootPath, '$rootPath/%', '%$queryLower%'],
      orderBy: 'name_lower ASC',
      limit: 100,
    );

    return results;
  }

  @override
  Future<void> deleteIndex(String rootPath) async {
    // Supprimer tous les fichiers du chemin
    await _db.delete(
      'file_index',
      where: 'path = ? OR path LIKE ?',
      whereArgs: [rootPath, '$rootPath/%'],
    );

    // Supprimer les métadonnées
    await _db.delete(
      'index_metadata',
      where: 'root_path = ?',
      whereArgs: [rootPath],
    );
  }

  @override
  Future<DateTime?> getLastIndexTime(String rootPath) async {
    final result = await _db.query(
      'index_metadata',
      where: 'root_path = ?',
      whereArgs: [rootPath],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final timestamp = result.first['last_indexed_at'] as int?;
    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  Future<void> setLastIndexTime(String rootPath, DateTime time) async {
    final fileCount = await getFileCount(rootPath);

    await _db.insert('index_metadata', {
      'root_path': rootPath,
      'last_indexed_at': time.millisecondsSinceEpoch,
      'file_count': fileCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<int> getFileCount(String rootPath) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM file_index WHERE path = ? OR path LIKE ?',
      [rootPath, '$rootPath/%'],
    );

    if (result.isEmpty) return 0;
    return result.first['count'] as int? ?? 0;
  }

  Future<void> close() async {
    await _db.close();
  }
}
