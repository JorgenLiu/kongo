# Kongo Project Guidelines

## Source Of Truth

- Start with `doc/INDEX.md` for navigation and current project status.
- Use `doc/API_SPECIFICATION.md` for service, repository, provider, and exception contracts.
- Use `doc/DATABASE_DESIGN.md` for schema and persistence decisions.
- Use `doc/UI_DESIGN_GUIDE.md` for colors, spacing, typography, and component intent.
- Use `doc/DEVELOPMENT_GUIDE.md` for layering, naming, import order, environment setup, project structure, and key technical decisions.
- Use `doc/PROJECT_PLAN.md` for overall requirements, feature scope, and phased roadmap.
- Prefer current code for actual runtime behavior, and use the docs as the target architecture when the two differ.

## Current Project State

- This is a Flutter and Dart app for contact and event management, with macOS as the currently verified development target.
- The repo contains `macos/`, `ios/`, and `windows/` platform folders, but only macOS has been validated end to end.
- Core persistence is implemented: SQLite init/migrations, default event types, and repositories/services for contacts, tags, events, summaries, and attachments are in place.
- Read-side aggregation has replaced the earlier query-service approach. Use `lib/services/read/` as the current read-model entry point, especially `ContactReadService` and `EventReadService`.
- Implemented providers include `ContactProvider`, `ContactDetailProvider`, `EventsListProvider`, and `EventDetailProvider`, plus shared `BaseProvider` / `ProviderError` infrastructure. `TagProvider` and a write-side `EventProvider` are still not implemented.
- Implemented UI includes contacts list, contact create/edit form, contact detail, events list, and event detail. These pages already use shared common/error/empty/detail-section widgets.
- Not yet implemented in UI: event create/edit/delete flow, tag management/search screens, summary/attachment CRUD screens, and the main home/tags/settings modules.
- Current dependencies already include `provider`, `sqflite`, `path`, `path_provider`, and `uuid`; tests use `sqflite_common_ffi`. Do not describe these as planned additions anymore.
- Real tests exist and are part of the current baseline: provider tests, read-service tests, service tests, widget tests, and a SQLite FFI test harness.
- User-facing text, many comments, and project documentation are in Chinese. Preserve that style unless a file is already clearly English-first.
- Treat these as the core project docs to prioritize: INDEX.md, PROJECT_PLAN.md, DATABASE_DESIGN.md, API_SPECIFICATION.md, UI_DESIGN_GUIDE.md, DEVELOPMENT_GUIDE.md. Additional historical or analysis docs may also exist under `doc/`.

## Architecture Expectations

- Keep the current layer boundaries: `screens` -> `widgets/actions` -> `providers` -> `read services/services` -> `repositories` -> `models`.
- Do not move business logic or persistence concerns into screens or reusable widgets. Read-heavy page aggregation belongs in page providers backed by `services/read/`, not directly in screens.
- Avoid reintroducing screen-level service-locator usage. New aggregate pages should follow the existing pattern used by contact detail, events list, and event detail.
- Contact and event detail screens are intentionally becoming composition/state layers. Prefer extracting page-specific actions to sibling action files and rendering sections to dedicated widgets instead of growing the screen file again.
- When extending an existing page, check for an existing sibling `*_actions.dart` file or page-specific section widgets first. Prefer adding behavior there instead of adding more private helpers and orchestration logic into the screen file.
- Do not postpone decomposition until a screen becomes obviously oversized. If a screen starts accumulating multiple section builders, action handlers, or formatting helpers, extract them during the same task.
- New detail or aggregate pages should follow the same pattern by default: screen for wiring and state orchestration, sibling action file for page actions, dedicated widgets for major sections.
- Reuse existing design tokens from `lib/config/app_colors.dart`, `lib/config/app_constants.dart`, and `lib/config/app_theme.dart` before creating new ones.
- Reuse existing shared UI/state helpers when possible, especially `ErrorState`, `EmptyState`, display formatters, and the existing contact/event section widgets.
- Follow existing naming conventions: snake_case files, PascalCase types, camelCase members.
- Keep changes incremental. Do not rewrite large planned areas of the app unless the task explicitly requires it.

## Code And UI Conventions

- Favor Material 3 and stay aligned with the existing blue/cyan design language already encoded in the config files.
- Keep UI responsive and desktop-friendly for macOS first.
- When touching production-facing files, remove temporary debug `print` statements unless they are still actively needed for the task.
- Avoid adding dependencies unless the task really needs them and they fit the documented architecture.
- If you add a feature in one layer, update the adjacent layer contracts or tests when practical instead of leaving the app half-wired.
- For list/detail states, prefer the existing shared empty/error components over re-implementing ad hoc placeholders.
- For display formatting or repeated screen actions, prefer adding or extending shared helpers in `lib/utils/` or screen-scoped action files rather than duplicating logic.

## Environment And Network Rules

- Do not assume Homebrew is available or appropriate on this machine.
- The working Flutter SDK path is `~/development/flutter`.
- Before commands that may contact Google-hosted or similarly restricted resources, run `source ~/.zshrc && proxyon` first.
- Swift Package Manager support is enabled for Flutter in this environment. Prefer plugin and platform choices that do not force CocoaPods unless necessary.
- If a requested dependency requires CocoaPods or native platform integration that is likely to be fragile on Ventura with system Ruby 2.6, call that out explicitly before proceeding.

## Useful Commands

- `source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter pub get`
- `source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter analyze`
- `source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter test`
- `source ~/.zshrc && cd /Users/jordan.liu/dev/kongo && flutter run -d macos`
- `source ~/.zshrc && proxyon && cd /Users/jordan.liu/dev/kongo && flutter doctor -v`

## When Implementing Planned Features

- Map new work back to the planning docs instead of inventing parallel structures.
- Prefer the documented exception model over nullable async returns.
- Keep contact, tag, event, and search concepts consistent with the terminology already used throughout `doc/`.
- When adding new read-heavy pages or aggregates, extend the read-side service/provider pattern and add tests around the aggregate path.
- When updating docs, keep `doc/INDEX.md` and `doc/PROJECT_PLAN.md` aligned with the actual implemented state; they can drift quickly after architecture work.
- If a document is clearly outdated compared with the code you are changing, update the relevant doc as part of the same task when feasible.