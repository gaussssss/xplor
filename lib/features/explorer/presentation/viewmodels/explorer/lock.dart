part of '../explorer_view_model.dart';

extension ExplorerLockOps on ExplorerViewModel {
  static const String _lockedExtension = '.xplrlock';
  static const String _magicV1 = 'XPLR1';
  static const String _magicV2 = 'XPLR2';
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _macLength = 16;
  static const int _payloadTypeFile = 0;
  static const int _payloadTypeDirectory = 1;

  static final _cipher = AesGcm.with256bits();
  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 150000,
    bits: 256,
  );

  static final Random _secureRandom = Random.secure();

  bool isLockedEntry(FileEntry entry) => isLockedPath(entry.path);

  bool isLockedPath(String path) => path.endsWith(_lockedExtension);

  Future<bool> lockEntry(FileEntry entry, String password) async {
    if (_blockArchiveWrite('Verrouillage non supporte dans une archive')) {
      return false;
    }
    if (isLockedEntry(entry)) {
      _state = _state.copyWith(statusMessage: 'Fichier deja verrouille');
      notifyListeners();
      return false;
    }
    if (password.trim().isEmpty) {
      _state = _state.copyWith(statusMessage: 'Cle de chiffrement requise');
      notifyListeners();
      return false;
    }

    final sourceType = entry.isDirectory
        ? FileSystemEntityType.directory
        : FileSystemEntityType.file;
    final exists = entry.isDirectory
        ? await Directory(entry.path).exists()
        : await File(entry.path).exists();
    if (!exists) {
      _state = _state.copyWith(
        statusMessage:
            sourceType == FileSystemEntityType.directory
                ? 'Dossier introuvable'
                : 'Fichier introuvable',
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isLoading: true, clearStatus: true, clearError: true);
    notifyListeners();

    try {
      final data = entry.isDirectory
          ? await _zipDirectoryBytes(Directory(entry.path))
          : await File(entry.path).readAsBytes();
      final salt = _randomBytes(_saltLength);
      final nonce = _randomBytes(_nonceLength);
      final key = await _deriveKey(password, salt);
      final payload = _buildPayload(entry, data);
      final secretBox = await _cipher.encrypt(
        payload,
        secretKey: key,
        nonce: nonce,
      );

      final targetPath = _uniqueLockedPath(entry.path);
      final output = <int>[
        ...utf8.encode(_magicV2),
        ...salt,
        ...nonce,
        ...secretBox.mac.bytes,
        ...secretBox.cipherText,
      ];
      await File(targetPath).writeAsBytes(output, flush: true);
      if (entry.isDirectory) {
        await Directory(entry.path).delete(recursive: true);
      } else {
        await File(entry.path).delete();
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage:
            entry.isDirectory ? 'Dossier verrouille' : 'Fichier verrouille',
      );
      return true;
    } catch (_) {
      _state = _state.copyWith(statusMessage: 'Echec du verrouillage');
      return false;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<bool> unlockEntry(FileEntry entry, String password) async {
    if (_blockArchiveWrite('Deverrouillage non supporte dans une archive')) {
      return false;
    }
    if (!isLockedEntry(entry)) {
      _state = _state.copyWith(statusMessage: 'Fichier non verrouille');
      notifyListeners();
      return false;
    }
    final source = File(entry.path);
    if (!await source.exists()) {
      _state = _state.copyWith(statusMessage: 'Fichier introuvable');
      notifyListeners();
      return false;
    }
    if (password.trim().isEmpty) {
      _state = _state.copyWith(statusMessage: 'Cle de dechiffrement requise');
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isLoading: true, clearStatus: true, clearError: true);
    notifyListeners();

    try {
      final data = await source.readAsBytes();
      final headerSize =
          _magicV1.length + _saltLength + _nonceLength + _macLength;
      if (data.length <= headerSize) {
        throw Exception('Invalid data');
      }
      final magicBytes = data.sublist(0, _magicV1.length);
      final magic = utf8.decode(magicBytes);
      if (magic != _magicV1 && magic != _magicV2) {
        throw Exception('Invalid header');
      }
      final saltStart = _magicV1.length;
      final nonceStart = saltStart + _saltLength;
      final macStart = nonceStart + _nonceLength;
      final cipherStart = macStart + _macLength;

      final salt = data.sublist(saltStart, nonceStart);
      final nonce = data.sublist(nonceStart, macStart);
      final mac = data.sublist(macStart, cipherStart);
      final cipherText = data.sublist(cipherStart);

      final key = await _deriveKey(password, salt);
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(mac),
      );
      final clearText = await _cipher.decrypt(
        secretBox,
        secretKey: key,
      );

      final parentDir = Directory(entry.path).parent.path;
      final fallbackName = p.basename(
        entry.path.substring(0, entry.path.length - _lockedExtension.length),
      );

      var unlockedDirectory = false;
      if (magic == _magicV1) {
        final targetPath = _uniqueUnlockedPath(
          p.join(parentDir, fallbackName),
        );
        await File(targetPath).writeAsBytes(clearText, flush: true);
      } else {
        final payload = _decodePayload(clearText);
        final resolvedName = _sanitizeName(payload.name).isEmpty
            ? fallbackName
            : _sanitizeName(payload.name);
        final basePath = p.join(parentDir, resolvedName);
        if (payload.isDirectory) {
          final targetPath = _uniqueUnlockedPath(
            basePath,
          );
          await Directory(targetPath).create(recursive: true);
          await _extractZipBytes(payload.data, targetPath);
          unlockedDirectory = true;
        } else {
          final targetPath = _uniqueUnlockedPath(
            basePath,
          );
          await File(targetPath).writeAsBytes(payload.data, flush: true);
        }
      }
      await source.delete();
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage:
            unlockedDirectory ? 'Dossier deverrouille' : 'Fichier deverrouille',
      );
      return true;
    } on SecretBoxAuthenticationError {
      _state = _state.copyWith(statusMessage: 'Mot de passe incorrect');
      return false;
    } catch (_) {
      _state = _state.copyWith(statusMessage: 'Echec du deverrouillage');
      return false;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      debugPrint('[Xplor][Unlock] Fin du flux pour ${entry.path}');
    }
  }

  List<int> _buildPayload(FileEntry entry, List<int> body) {
    final type = entry.isDirectory ? _payloadTypeDirectory : _payloadTypeFile;
    final name = _sanitizeName(entry.name);
    final nameBytes = utf8.encode(name);
    return <int>[
      type,
      ..._encodeUint32(nameBytes.length),
      ...nameBytes,
      ...body,
    ];
  }

  _LockPayload _decodePayload(List<int> bytes) {
    if (bytes.length < 5) {
      throw Exception('Invalid payload');
    }
    final type = bytes[0];
    if (type != _payloadTypeFile && type != _payloadTypeDirectory) {
      throw Exception('Invalid payload');
    }
    final nameLength = _decodeUint32(bytes, 1);
    final nameStart = 1 + 4;
    final contentStart = nameStart + nameLength;
    if (contentStart > bytes.length) {
      throw Exception('Invalid payload');
    }
    final nameBytes = bytes.sublist(nameStart, contentStart);
    final name = utf8.decode(nameBytes, allowMalformed: true).trim();
    final data = bytes.sublist(contentStart);
    return _LockPayload(
      isDirectory: type == _payloadTypeDirectory,
      name: name,
      data: data,
    );
  }

  List<int> _encodeUint32(int value) {
    return <int>[
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  int _decodeUint32(List<int> data, int offset) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  String _sanitizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return p.basename(trimmed);
  }

  Future<List<int>> _zipDirectoryBytes(Directory directory) async {
    final archive = Archive();
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      final relativePath = p.relative(entity.path, from: directory.path);
      if (relativePath.isEmpty || relativePath == '.') continue;
      final normalized = relativePath.replaceAll('\\', '/');
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(normalized, bytes.length, bytes));
      } else if (entity is Directory) {
        final dirName = normalized.endsWith('/') ? normalized : '$normalized/';
        final dirEntry = ArchiveFile(dirName, 0, const <int>[]);
        dirEntry.isFile = false;
        archive.addFile(dirEntry);
      }
    }
    return ZipEncoder().encode(archive) ?? <int>[];
  }

  Future<void> _extractZipBytes(List<int> zipBytes, String destination) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive) {
      final sanitizedName = file.name.replaceAll('\\', '/');
      final targetPath = p.normalize(p.join(destination, sanitizedName));
      if (!p.isWithin(destination, targetPath) &&
          targetPath != destination) {
        continue;
      }
      if (file.isFile) {
        final content = file.content;
        final bytes = content is List<int>
            ? content
            : content is String
                ? utf8.encode(content)
                : const <int>[];
        final output = File(targetPath);
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes, flush: true);
      } else {
        await Directory(targetPath).create(recursive: true);
      }
    }
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _secureRandom.nextInt(256));
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) {
    return _kdf.deriveKeyFromPassword(password: password, nonce: salt);
  }

  String _uniqueLockedPath(String basePath) {
    var target = '$basePath$_lockedExtension';
    if (_pathAvailable(target)) return target;
    var counter = 1;
    while (!_pathAvailable('$basePath ($counter)$_lockedExtension')) {
      counter++;
    }
    return '$basePath ($counter)$_lockedExtension';
  }

  String _uniqueUnlockedPath(String basePath) {
    if (_pathAvailable(basePath)) return basePath;
    final dir = Directory(basePath).parent.path;
    final name = p.basename(basePath);
    final stem = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    var counter = 1;
    String candidate;
    do {
      candidate = p.join(dir, '$stem ($counter)$ext');
      counter++;
    } while (!_pathAvailable(candidate));
    return candidate;
  }

  bool _pathAvailable(String path) {
    return FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound;
  }
}

class _LockPayload {
  const _LockPayload({
    required this.isDirectory,
    required this.name,
    required this.data,
  });

  final bool isDirectory;
  final String name;
  final List<int> data;
}
