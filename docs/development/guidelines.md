# Development Guidelines

## Architecture Overview
We follow a modified Clean Architecture combined with Feature-driven structure.

- **`lib/app/`**: Global application configuration, routing, and bootstrapping.
- **`lib/core/`**: Shared infrastructure (networking, logging, storage, errors).
- **`lib/features/`**: Independent product modules.
- **`lib/shared/`**: Reusable UI components, extensions, and models.

## Layer Responsibilities

### Presentation Layer
- Contains UI (Screens, Widgets) and State Management (Riverpod).
- UI should be "dumb" and only react to state.
- Use `ConsumerWidget` for screens.

### Domain Layer (within features)
- Business logic, Entities, and Repository interfaces.
- Should have NO dependency on external libraries or frameworks.

### Data Layer (within features)
- Concrete implementations of Repository interfaces.
- Depends on `core/networking` and `core/storage`.
- Handles data mapping from JSON/External models to Domain Entities.

## Error Handling
- Never throw raw exceptions in repositories. 
- Return a `Failure` object from the domain layer.
- Use the `AppException` hierarchy for internal data-layer errors.

## Logging
- Use `AppLogger` instead of `print`.
- Redact sensitive data using `AppLogger.logSensitive`.
- Never log passwords, tokens, or PII.
