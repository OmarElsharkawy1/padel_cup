# Padel Cup

A Padel Tournament Management App built with Flutter. Manage a full tournament lifecycle — from team setup and round-robin scheduling to live scoring, standings, and finals.

## Features

- Create tournaments with 2 groups (A & B), 5 teams per group
- Automatic round-robin schedule generation (4 matches per team, 1 rest per team)
- 4 courts (2 per group) with balanced scheduling
- Live score entry with set-based scoring
- Real-time standings with points and set difference tiebreaker
- Automatic finals generation (1st and 3rd place matches)
- Light/Dark theme with persistence
- Arabic/English localization with full RTL support
- Responsive layout for phones and tablets
- All data persisted locally (no backend required)

## Tech Stack

| Category             | Technology                     |
|----------------------|--------------------------------|
| Framework            | Flutter 3.x                    |
| Language             | Dart                           |
| State Management     | Riverpod (StateNotifierProvider) |
| Routing              | GoRouter (StatefulShellRoute)  |
| Local Storage        | Hive                           |
| Design System        | Material 3                     |
| Internationalization | flutter_localizations (ARB)    |
| Icons                | flutter_launcher_icons         |

## Architecture

The project follows **Clean Architecture** with a feature-based folder structure:

```
lib/
├── core/
│   ├── config/          # App flavors (dev, staging, profile, release)
│   ├── constants/       # Tournament rules & Hive box names
│   ├── router/          # GoRouter configuration
│   └── theme/           # Material 3 light/dark themes
├── features/
│   ├── tournament/
│   │   ├── data/
│   │   │   ├── datasources/    # Hive local data source
│   │   │   ├── models/         # Hive TypeAdapter models
│   │   │   └── repositories/   # Repository implementation
│   │   ├── domain/
│   │   │   ├── entities/       # Team, Match, Tournament, Standing
│   │   │   ├── repositories/   # Repository interfaces
│   │   │   └── usecases/       # Business logic (scheduling, scoring, standings)
│   │   └── presentation/
│   │       ├── providers/      # Riverpod state providers
│   │       ├── screens/        # Setup, Scoreboard, Standings, Finals
│   │       └── widgets/        # Reusable UI components
│   └── settings/
│       ├── data/               # Theme & locale persistence
│       └── presentation/       # Settings screen & providers
├── l10n/                       # ARB files & generated localizations
├── app.dart                    # Root MaterialApp.router
├── bootstrap.dart              # Hive init & adapter registration
└── main*.dart                  # Flavor entry points
```

### Layer Responsibilities

- **Domain** — Entities, repository interfaces, and use cases. Pure Dart with no framework dependencies.
- **Data** — Hive models with TypeAdapters, local data sources, and repository implementations.
- **Presentation** — Riverpod providers, screens, and widgets. Consumes use cases via providers.

## Tournament Rules

| Rule            | Detail                                              |
|-----------------|-----------------------------------------------------|
| Groups          | 2 (A & B), 5 teams each                             |
| Courts          | 4 total (2 per group)                                |
| Format          | Round Robin (each team plays 4, rests 1)             |
| Scoring         | User-defined timer or first to 4 sets                |
| Points          | Win = 3, Tie = 1, Loss = 0                           |
| Tiebreaker      | Total Points, then Set Difference (won - lost)       |
| Finals          | 1st Place: Winner A vs Winner B                      |
|                 | 3rd Place: 2nd A vs 2nd B                            |

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# Run (release flavor)
flutter run

# Run (dev flavor)
flutter run -t lib/main_dev.dart
```

## Flavors

| Flavor   | Entry Point           | App Name             |
|----------|-----------------------|----------------------|
| Dev      | `lib/main_dev.dart`     | Padel Cup [DEV]      |
| Staging  | `lib/main_staging.dart` | Padel Cup [STG]      |
| Profile  | `lib/main_profile.dart` | Padel Cup [PROFILE]  |
| Release  | `lib/main.dart`         | Padel Cup            |
