# Architecture Rules

## Layering
- Features: SwiftUI Views + ViewModels. Depend only on Core utilities, Service protocols, and Repository protocols.
- Services: Business workflows. Depend only on Repository protocols.
- Data: CoreData stack and repository implementations.
- Core: Stateless utilities (formatters, date/money policy, theme).

## Dependency Direction
Features -> Services -> Repositories -> Data.
Core utilities are shared and can be used by all layers.
Core has no dependency on other layers.

## Dependency Injection
- All concrete implementations are created in `DIContainer` and passed down via `AppEnvironment`.
- ViewModels never instantiate repository/service implementations directly.

## Forbidden In Feature/ViewModel Files
- `NSManagedObjectContext`
- `NSFetchRequest`
- `PersistenceController`

## Project Placement
- New files must live under `App/`, `Core/`, `Data/`, `Services/`, `Features/`, or `Resources/`.
