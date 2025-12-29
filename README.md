# xplor

Prototype d explorateur de fichiers macOS construit avec Flutter.

## Architecture
- Clean Architecture + MVVM
- `lib/app.dart` : bootstrap et theming
- `lib/core/` : theme et ressources partagees
- `lib/features/explorer/domain/` : entites, repository abstrait, use cases
- `lib/features/explorer/data/` : data source locale et implementation du repository
- `lib/features/explorer/presentation/` : ViewModel et UI (page Explorer)

## Lancer
- `flutter run -d macos` pour la cible desktop
- ou `flutter run` pour cibler l emulateur mobile
