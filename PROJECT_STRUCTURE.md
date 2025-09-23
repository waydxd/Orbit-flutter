# Orbit Calendar - Project Structure

This document outlines the Flutter project structure for the Orbit intelligent calendar application.

## Architecture

The project follows the **MVVM (Model-View-ViewModel)** architecture pattern as recommended by Flutter documentation.

## Directory Structure

```
lib/
├── app.dart                    # Main application widget
├── main.dart                   # Application entry point
├── config/                     # Configuration files
│   ├── app_config.dart        # App constants and configuration
│   └── environment.dart       # Environment-specific settings
├── data/                      # Data layer
│   ├── models/                # Data models and entities
│   │   └── base_model.dart    # Base model class
│   ├── repositories/          # Repository implementations
│   │   └── base_repository.dart # Base repository interface
│   └── services/              # Data services
│       ├── api_client.dart    # HTTP API client
│       └── local_storage_service.dart # Local storage service
├── domain/                    # Domain layer (optional)
├── ui/                        # Presentation layer
│   ├── auth/                  # Authentication screens
│   │   ├── view/             # Auth view widgets
│   │   └── widgets/          # Auth-specific widgets
│   └── core/                  # Core UI components
│       ├── themes/           # Theme configuration
│       │   ├── app_theme.dart # Main theme configuration
│       │   └── app_colors.dart # Color palette
│       └── ui/               # Reusable UI components
│           ├── base_view_model.dart # Base ViewModel class
│           ├── loading_widget.dart  # Loading components
│           ├── error_widget.dart    # Error components
│           └── app_scaffold.dart    # Base scaffold
└── utils/                     # Utility classes
    ├── constants.dart         # App constants
    ├── extensions.dart        # Dart extensions
    ├── validators.dart        # Form validators
    └── logger.dart           # Logging utility
```

## Key Components

### Configuration Layer
- **AppConfig**: Contains application constants, API URLs, and feature flags
- **EnvironmentConfig**: Manages different build environments (dev, staging, prod)

### Data Layer
- **Models**: Data transfer objects and domain entities with Hive annotations for local storage
- **Repositories**: Abstract interfaces for data access following repository pattern
- **Services**: Concrete implementations for API communication and local storage

### UI Layer
- **Views**: Flutter widgets that display data to users
- **ViewModels**: Business logic and state management using ChangeNotifier
- **Themes**: Consistent design system with Material 3 and neumorphic elements

### Utils
- **Extensions**: Helpful extensions for String, DateTime, BuildContext, etc.
- **Validators**: Form validation utilities
- **Logger**: Centralized logging system
- **Constants**: Application-wide constants

## Dependencies

### Core Dependencies
- `provider`: State management
- `hive` & `hive_flutter`: Local database
- `dio`: HTTP client
- `flutter_secure_storage`: Secure token storage

### UI Dependencies
- `google_fonts`: Typography
- `table_calendar`: Calendar widget
- `cached_network_image`: Image caching
- `shimmer`: Loading animations

### Feature Dependencies
- `geolocator` & `google_maps_flutter`: Location services
- `image_picker` & `camera`: Image capture
- `flutter_local_notifications`: Push notifications
- `connectivity_plus`: Network connectivity

### Development Dependencies
- `build_runner`: Code generation
- `hive_generator`: Hive adapter generation
- `json_serializable`: JSON serialization
- `mockito`: Testing mocks

## Architecture Patterns

### MVVM Pattern
- **View**: Stateless/Stateful widgets that display UI
- **ViewModel**: ChangeNotifier classes that manage business logic and state
- **Model**: Data classes that represent application data

### Repository Pattern
- Abstract repository interfaces define data access contracts
- Concrete implementations handle API calls and local storage
- ViewModels depend on repository abstractions, not implementations

### Dependency Injection
- Use Provider for dependency injection
- Repositories and services are provided at the app level
- ViewModels are provided at the screen level

## Code Generation

The project uses code generation for:
- **Hive Adapters**: `@HiveType` and `@HiveField` annotations
- **JSON Serialization**: `@JsonSerializable` annotations

Run code generation with:
```bash
flutter packages pub run build_runner build
```

## Testing Strategy

- **Unit Tests**: Test ViewModels and Repository logic
- **Widget Tests**: Test individual UI components
- **Integration Tests**: Test complete user flows
- **Golden Tests**: Visual regression testing

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Generate code (when models are added):
   ```bash
   flutter packages pub run build_runner build
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Next Steps

This foundation provides:
- ✅ Project structure following MVVM architecture
- ✅ Dependency management with pubspec.yaml
- ✅ Theme system with Material 3 and neumorphic design
- ✅ Local storage setup with Hive
- ✅ API client configuration with Dio
- ✅ Utility classes and extensions
- ✅ Linting rules and code quality setup

Ready for implementation of specific features according to the task list.