# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Open-source repository under `@zerobias-org` containing **suite** content artifacts — every suite represents a regulatory framework, standard, or compliance offering organized by vendor (e.g. `adobe/ccf`, `amazon/aws`, `iso/27001`). Suites are linked to a parent vendor (from `zerobias-org/vendor`) at load time.

## Essential Commands

### Development Setup
```bash
# Root devDeps (commitlint, tsx for scripts/correctDeps.ts)
npm install

# Reset workspace
npm run reset
```

### Migration Status

[`MIGRATION_STATUS.md`](./MIGRATION_STATUS.md) is the running tracker of which suites are on the gradle pipeline vs the lerna-era 1.x line, plus pre-flight `flagged` suites that will fail gate as-is (bad URL, malformed code, etc.). Regenerate with:

```bash
./scripts/migration-status.sh        # rewrite the tracker
./scripts/migration-status.sh --check # exit non-zero if out of date (CI-friendly)
```

When picking the next batch to migrate, work from the `pending` rows; skip anything in the `Flagged` section until its index.yml / package.json drift is fixed.

### Working with Suites

```bash
# Create a new suite package: copy template + add gradle marker
cp -r templates/ package/[vendor]/[suite]
echo 'plugins { id("zb.content") }' > package/[vendor]/[suite]/build.gradle.kts
# Then update package.json, index.yml, .npmrc, add appropriate logo

# Validate via gradle (validate + dataloader)
./gradlew :[vendor]:[suite]:gate

# List all auto-discovered suite projects
./gradlew projectPaths
```

### Publishing and Version Management

Publishing is driven by the gradle `Publish` GitHub Actions workflow, triggered on push to `main` / `qa` / `dev` / `uat`. It:

1. `detect` — diffs `package/**/build.gradle.kts` against `origin/main` to find changed suites
2. matrix `publish (<vendor>/<suite>)` — runs `zbb publish` per suite (gate preflight via committed `gate-stamp.json` → `npm publish --tag next` → cumulative `promoteAll` to dev/qa/uat/latest)
3. `sync` — propagates main → uat → qa → dev after a successful main publish

```bash
# Manually trigger the workflow on a branch
gh workflow run publish.yml --repo zerobias-org/suite --ref dev

# Local dry-run of the publish flow for one suite
./gradlew :[vendor]:[suite]:publish -PdryRun=true
```

### Git Workflow

Conventional Commits (validated by commitlint):

```
feat(suite-{vendor}-{code}): ...
fix(suite-{vendor}-{code}): ...
chore(suite-{vendor}-{code}): ...
```

## Architecture

### Package Layout

Suites live two directories deep under `package/`:

```
package/
├── adobe/
│   └── ccf/
│       ├── package.json       # @zerobias-org/suite-adobe-ccf
│       ├── index.yml          # Suite metadata (id, code, vendorId, vendorCode, ...)
│       ├── logo.svg
│       ├── build.gradle.kts   # one-line marker: plugins { id("zb.content") }
│       ├── gate-stamp.json    # written by ./gradlew :<vendor>:<suite>:gate
│       └── .npmrc
├── amazon/
│   └── aws/
└── ...
```

The npm package name is `@zerobias-org/suite-{vendorCode}-{suiteCode}` and the `zerobias.package` field is `{vendorCode}.{suiteCode}` (the dataloader's `SuiteFileHandler` enforces both).

### What the validator enforces

The dataloader is the source of truth for schema rules (UUID format, code regex, `VspStatusEnum`, URL parse, vendor lookup, tag UUIDs, etc.). Re-validating those at gate time would just create drift risk — when the dataloader tightens a rule, the gate gets stale. The full schema is exercised by `testIntegrationDataloader` against an ephemeral Neon Postgres branch as part of `gate`.

The inline validator at `build.gradle.kts` (`extra["contentValidator"]`) only enforces what the dataloader **cannot** or **does not** check:

1. **Filesystem ↔ npm ↔ zerobias-block triangulation** — for a suite at `package/{vendor}/{suite}/`, both the npm `name` and the `zerobias.package` field are derived deterministically from the directory path:
   - `package.json` `name` must equal `@zerobias-org/suite-{vendor}-{suite}`
   - `zerobias.package` (or legacy `auditmation.package`) must equal `{vendor}.{suite}`
   - The dataloader reads `zerobias.package` but never the npm `name` field — a wrong name would publish under the wrong package and only surface in production.

2. **Logo file correctness** — the dataloader doesn't crack open the actual logo file:
   - Exactly one `logo.{svg,png,jpg}` file must be present (never zero, never two)
   - File magic bytes must match the extension (catches HTML error pages or S3 `AccessDenied` masquerading as `logo.svg`)
   - File size in `[500B, 5MB]`
   - `package.json` `files` array must include the logo

3. **Repo-wide unique `id` UUIDs** — registered as `:validateUniqueIds` at the root, automatically a dependency of every per-suite `validateContent`. The dataloader processes one artifact at a time, so collisions only surface when the second one tries to load to the same DB row.

Everything else (UUID parse, code regex, `VspStatusEnum`, URL parse, `vendorCode`/`vendorId` lookup, tag UUID list, `zerobias.dataloader-version` non-blank, etc.) is delegated to the dataloader running during `gate`.

### Vendor linkage

Every suite carries `vendorId` + `vendorCode` and a `dependencies: { @zerobias-org/vendor-{vendorCode}: latest }` entry. At load time the dataloader looks up the vendor by id and rejects if `vendor.code !== vendorCode`. Locally during development you `npm install` to pull the vendor's `index.yml` and copy its `id` into your suite's `vendorId`.

### Key Technologies

- **Gradle (zb.content plugin)**: Drives validate / gate / publishNpm / promoteAll per suite. Plugin lives in `zerobias-org/util` and resolves via `settings.gradle.kts`.
- **zbb**: Lifecycle CLI used by CI (`zbb publish`).
- **TypeScript**: `scripts/correctDeps.ts` (executed via `tsx`). Validation rules live in the root `build.gradle.kts` (`extra["contentValidator"]`) composed from `SchemaPrimitives` shipped by `zerobias-org/util` build-tools.
- **Lerna (legacy)**: Still referenced in root `package.json` scripts (`lerna:dry-run`, `lerna:version`) but unused — the gradle pipeline has superseded it. Don't add new lerna config. Nx has been removed entirely.
- **Conventional Commits**: Enforced via commitlint.

### Settings auto-discovery

`settings.gradle.kts` walks `package/` looking for `build.gradle.kts` markers at any depth. Because suites live two levels deep, the project path mirrors the filesystem: `package/adobe/ccf` → `:adobe:ccf`. To add a new suite to the gradle pipeline, drop the marker.

## Important Notes

- **Authentication**: `ZB_TOKEN` (or `NPM_TOKEN` / `GITHUB_TOKEN`) for npm registry; `NEON_API_KEY` + `NEON_PROJECT_ID` for the dataloader integration step (sourced from vault via `zbb.yaml`).
- **Commit Format**: All commits must follow Conventional Commits.
- **Private Registry**: Packages publish to `npm.pkg.github.com/@zerobias-org`.
- **No Direct npm publish**: Driven by the gradle `Publish` workflow. Locally use `./gradlew :<v>:<s>:gate` before push.
- **Naming**: `@zerobias-org/suite-{vendor}-{suite}` for npm; `{vendor}.{suite}` for `zerobias.package`.

## Migration major-bump rule

Suites that existed pre-gradle (`1.x.x` lerna-managed) must bump to `2.0.0` when migrated to the gradle pipeline. Skip the bump for suites already on `2.x`. Same rule applied to `org/vendor` and `zerobias-com/tag`.

## ZeroBias Task Integration

For creating suites from ZeroBias tasks, use the skill:

```
/create-suite [task-id]
```

See **[.claude/skills/create-suite.md](.claude/skills/create-suite.md)** for the complete workflow.

### Dependency Chain

```
vendor → suite → framework/standard/benchmark → crosswalk
```

Suites REQUIRE vendors. Always check/create vendor first.

### Key APIs

```javascript
// Check if vendor exists (REQUIRED before suite)
zerobias_execute("store.Vendor.get", { vendorCode: "vendor" })

// Get your party ID for assignment
zerobias_execute("platform.Party.getMyParty", {})

// Transition task to in_progress (use transitionId, NOT status)
zerobias_execute("platform.Task.update", {
  id: taskId,
  updateTask: {
    assigned: partyId,
    transitionId: "7f140bbe-4c10-54ac-922c-460c66392fad"
  }
})
```

### vendorId lookup

After `npm install` in a suite directory, the parent vendor's `index.yml` is materialized at `node_modules/@zerobias-org/vendor-{vendor}/index.yml`. Copy its `id` into your suite's `index.yml` `vendorId` field — the dataloader rejects mismatches.

## See Also

- **[.claude/skills/create-suite.md](.claude/skills/create-suite.md)** — full new-suite walkthrough (task-driven)
- **`build.gradle.kts`** — validator implementation
- **`com/platform/dataloader/src/processors/suite/`** (in the meta-repo) — source of truth for what loads on prod
- **`org/vendor/CLAUDE.md`** — sibling content repo on the same gradle pipeline; useful reference when patterns drift
- **`zerobias-com/tag/CLAUDE.md`** — sibling repo, simpler shape
