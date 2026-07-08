---
trigger: always_on
---

# Git Commit Rules

## Conventional Commits
Each commit MUST follow: `<type>(<scope>): <message>`
- **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **Scope**: The module or area being changed (e.g., `auth`, `api`)
- **Message**: Concise, imperative mood

### Commit Body
Include a detailed body when the change involves logic, breaking changes, or multiple steps. Explain the What, Why, and How.

## Atomic Commits
- **One Scope per Commit**: Perform separate commits for different scopes.
- **Stage Selectively**: Stage only the files belonging to the current scope.

## Execution Flow
1. Run `git status --short` to identify all changes.
2. Group files by logical scope.
3. For each scope group:
   - Stage only that group's files.
   - Commit with a conventional message (subject + body).
4. Verify with `git log -n 5`.
