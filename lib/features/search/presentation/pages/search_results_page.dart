import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;

import '../../domain/entities/search_result.dart';

class SearchResultsPage extends StatelessWidget {
  final List<SearchResult> results;
  final String query;
  final bool isLoading;
  final VoidCallback? onResultTap;

  const SearchResultsPage({
    super.key,
    required this.results,
    required this.query,
    required this.isLoading,
    this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Résultats pour "$query"'), elevation: 0),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Recherche en cours...'),
                ],
              ),
            )
          : results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    lucide.LucideIcons.search,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat trouvé',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez avec des mots-clés différents',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return _SearchResultTile(result: result, onTap: onResultTap);
              },
            ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isLight = brightness == Brightness.light;

    final icon = result.isDirectory
        ? lucide.LucideIcons.folder
        : lucide.LucideIcons.file;

    final backgroundColor = isLight
        ? Colors.white.withOpacity(0.5)
        : Colors.white.withOpacity(0.05);

    final relevanceColor = _getRelevanceColor(result.relevance);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            leading: Icon(icon, color: relevanceColor),
            title: Text(result.name),
            subtitle: Text(
              result.parentPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Tooltip(
              message:
                  'Pertinence: ${(result.relevance * 100).toStringAsFixed(0)}%',
              child: Chip(
                label: Text(
                  '${(result.relevance * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: relevanceColor.withOpacity(0.2),
                labelStyle: TextStyle(color: relevanceColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getRelevanceColor(double relevance) {
    if (relevance >= 0.9) return Colors.green;
    if (relevance >= 0.7) return Colors.yellow.shade700;
    if (relevance >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
