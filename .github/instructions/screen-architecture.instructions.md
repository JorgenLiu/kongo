---
applyTo: "lib/screens/**/*.dart"
description: "Use when editing Flutter screen files in Kongo. Keep screens thin composition layers, extract page actions into sibling action files, and split major sections into dedicated widgets before files grow large."
---

# Screen Architecture Guardrails

- Treat screen files as wiring and state-orchestration layers, not as long-term homes for business logic, persistence access, or large amounts of UI assembly code.
- Prefer page-level providers and `services/read/` for aggregate reads. Do not reintroduce screen-level service-locator or direct repository access patterns.
- When a screen already has a sibling `*_actions.dart` file, put page actions there instead of adding more private action handlers into the screen.
- When a page contains multiple major sections, move them into dedicated widget files under the appropriate `lib/widgets/` subtree instead of keeping large private builder blocks in the screen.
- If a change adds multiple section builders, formatting helpers, or page actions, perform the extraction in the same task rather than deferring cleanup.
- Follow the current default pattern for aggregate/detail pages: screen for wiring, sibling action file for page actions, dedicated widgets for section rendering.