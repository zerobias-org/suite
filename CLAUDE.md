# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Open-source repository under `@zerobias-org` containing **suite** content artifacts — every suite represents a regulatory framework, standard, or compliance offering organized by vendor (e.g. `adobe/ccf`, `amazon/aws`, `iso/27001`). Suites are linked to a parent vendor (from `zerobias-org/vendor`) at load time.

## Essential Commands

### Development Setup
```bash
# Root devDeps (commitlint hooks)
npm install
```

All suites are on the gradle pipeline as of May 2026 — every package carries a `build.gradle.kts` marker and committed `gate-stamp.json`. No lerna/nx infrastructure remains.

### Working with Suites

```bash
# Create a new suite package: scripts/createNewSuite.sh + gradle marker
./scripts/createNewSuite.sh [vendor] [suite]
echo 'plugins { id("zb.content") }' > package/[vendor]/[suite]/build.gradle.kts
# Then fill in package.json, index.yml, .npmrc, add appropriate logo

# Validate (per-package validator + dataloader) — ALWAYS via zbb (injects slot env)
zbb --slot <slot> gate            # run from package/[vendor]/[suite]; never bare ./gradlew

# List all auto-discovered suite projects
./gradlew projectPaths

# Cross-cut: ensure no two suites share an id UUID
./gradlew validateUniqueIds
```

### Publishing and Version Management

Publishing is driven by `zbb-publish-reusable.yml` (in `zerobias-org/devops`), triggered on push to `main` / `qa` / `dev` / `uat`:

1. `detect` — diffs `event.before..HEAD -- package/**` to find changed suites.
2. `version` (main only) — single-writer; `zbb version` patch-bumps changed suites in one commit before the matrix.
3. matrix `publish (<vendor>/<suite>)` — per-suite gate preflight via committed `gate-stamp.json` → `npm publish --tag next` → cumulative `promoteAll` to dev/qa/uat/latest.
4. `update-bundle` — refreshes `@zerobias-org/suite-bundle` deps from npm and patch-bumps + publishes.
5. `sync` — propagates `main → uat → qa → dev` after success.

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
- **Lerna/nx (removed)**: Fully removed in the post-migration cleanup — the gradle pipeline is the build/publish system. Root `package.json` no longer carries any `lerna:*` / `nx:*` scripts. Don't reintroduce lerna or nx config.
- **Conventional Commits**: Enforced via commitlint.

### Settings auto-discovery

`settings.gradle.kts` walks `package/` looking for `build.gradle.kts` markers at any depth. Because suites live two levels deep, the project path mirrors the filesystem: `package/adobe/ccf` → `:adobe:ccf`. To add a new suite to the gradle pipeline, drop the marker.

## Important Notes

- **Authentication**: `ZB_TOKEN` (or `NPM_TOKEN` / `GITHUB_TOKEN`) for npm registry; `NEON_API_KEY` + `NEON_PROJECT_ID` for the dataloader integration step (sourced from vault via `zbb.yaml`).
- **Commit Format**: All commits must follow Conventional Commits.
- **Private Registry**: Packages publish to `pkg.zerobias.org` (`@zerobias-org` scope).
- **No Direct npm publish**: Driven by the gradle `Publish` workflow. Locally use `zbb --slot <slot> gate` (from the package dir) before push.
- **Naming**: `@zerobias-org/suite-{vendor}-{suite}` for npm; `{vendor}.{suite}` for `zerobias.package`.

## Migration major-bump rule

Suites that existed pre-gradle (`1.x.x` lerna-managed) must bump to `2.0.0` when migrated to the gradle pipeline. Skip the bump for suites already on `2.x`. Same rule applied to `org/vendor` and `zerobias-com/tag`.

## Content SDLC & skills

**Creating a suite?** Say "add suite X for vendor Y" / "make suite X" (or
run `/create-suite`) — the
[create-suite skill](.claude/skills/create-suite/SKILL.md) handles the
whole flow; a ZeroBias task id is optional. Headless works too:
`claude -p "make suite x for vendor y"` pre-flights credentials, runs to
org load, and stops there (sign-off and PR stay human).

Hard prerequisites live in the
[`prerequisites` skill](.claude/skills/prerequisites/SKILL.md) — run
`/prerequisites` to pre-flight the repo (tools, MCPs, credentials — the
API key must be an **org owner** key; member keys can't load artifacts to
the org). If one is missing: **install it or wait — never work around it**
(no substitute tooling, no alternative paths).

The content SDLC (the skill owns the details — don't restate them here):

1. scaffold → `zbb --slot <slot> gate` (never bare `./gradlew`) → commit `gate-stamp.json`
2. `publishOrg` → load into YOUR org → verify → 🙋 explicit user sign-off
3. only then PR → base **`dev`**

**No ZeroBias org?** (external contributors): stop after the gate and open
the PR against `dev` — maintainers run the org verification on their side.
See [CONTRIBUTING.md](CONTRIBUTING.md).

### Dependency Chain

```
vendor → suite → framework/standard/benchmark → crosswalk
```

Suites REQUIRE vendors. Always check/create vendor first.

### Key APIs (zb MCP)

```javascript
// Check if vendor exists (REQUIRED before suite) — the portal.*.search
// ops found in older docs do NOT exist; vendorId for index.yml comes
// from this result's `id`
zerobias_execute("store.Vendor.get", { vendorCode: "vendor" })

// Suite existence check
zerobias_execute("store.Suite.get", { vendorCode: "vendor", suiteCode: "suite" })

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

Preferred: take `vendorId` from the `store.Vendor.get` result (`id` field). Legacy fallback: after `npm install` in a suite directory, the parent vendor's `index.yml` is materialized at `node_modules/@zerobias-org/vendor-{vendor}/index.yml` — copy its `id`. The dataloader rejects mismatches.

## See Also

- **[.claude/skills/create-suite/SKILL.md](.claude/skills/create-suite/SKILL.md)** — full new-suite walkthrough (org-first SDLC)
- **`build.gradle.kts`** — validator implementation
- **`com/platform/dataloader/src/processors/suite/`** (in the meta-repo) — source of truth for what loads on prod
- **`org/vendor/CLAUDE.md`** — sibling content repo on the same gradle pipeline; useful reference when patterns drift
- **`zerobias-com/tag/CLAUDE.md`** — sibling repo, simpler shape

---

## Sessions, credentials & MCPs — slot-first

<!-- Synced section: identical in vendor, suite, product, module.
     The zerobias meta-repo's CLAUDE.md carries the same rules in its
     own words. Edit in one repo, copy to all. -->

All org credentials (platform ORG key, registry key, org/env identity)
live in a **zbb slot**; Claude Code sessions are launched THROUGH the
slot so the committed `.mcp.json` templates (`${VAR}` refs — no
secrets) and the zb `env` profile resolve that identity.

- **One-time setup (per org/env):** the user runs
  `./scripts/setup-org-credentials.sh` themselves in a normal terminal
  (never inside a Claude session). Check-first and re-runnable: it
  creates the slot (`<env>-<org-prefix>`), stores the keys, and wires
  `~/.npmrc` + the zb profile.
- **Launch:** `./scripts/setup-org-credentials.sh --launch [args…]`,
  or `zbb --slot <slot> --stack <stack> exec claude` from anywhere
  (`<stack>` = this repo's `zbb.yaml` `name:` short form, e.g.
  `vendor` in the vendor repo); from this repo's root plain
  `zbb --slot <slot> exec claude` works too (cwd infers the stack).
  NEVER launch stackless from outside a `zbb.yaml` directory: a slot
  holds NO user vars of its own (only `ZB_SLOT*` identity) — every
  credential is **stack-scoped**, stored per stack inside the slot,
  and the setup script seeds every content stack it finds with the
  same creds. Add `--continue` to resume the previous session under
  another slot (sessions are keyed by cwd, not by slot).
- **Missing MCP tools / 401 / `MISSING_ENV_VAR` / `NOT SET`** means
  the session wasn't launched through a slot WITH a stack context.
  Check inside the session: `echo ${ZB_SLOT:-no-slot} ${ZB_ORG_ID:-no-stack}`
  (`no-slot` = not launched through zbb; `no-stack` = launched
  stackless). Fix the launch — exit and relaunch; `/mcp` reconnect can
  never pick up new env (it is captured once at claude startup). Do NOT
  register MCPs with pasted literal keys (a baked key silently
  overrides every slot identity, connecting as the wrong org) and do
  NOT export creds into the session as a workaround.
- **Multi-org / multi-env = one slot each**, chosen at launch time;
  switching identity means restarting claude through the other slot
  (env is read once at startup). A second IDENTITY (another API key)
  for the same org gets its own named slot too — a preset `SLOT` skips
  the reuse-by-content scan:
  `SLOT=<name> ZB_API_KEY=<other-key> ./scripts/setup-org-credentials.sh`.
  With several slots holding one org, always pass `--slot` explicitly —
  the auto-reuse scan just takes the first match.

Deep dive: the meta-repo's
[docs/MCPs.md](https://github.com/zerobias-org/zerobias/blob/main/docs/MCPs.md).

## Windows — WSL2 only

Everything here runs only on Ubuntu (`zbb` fails on native Windows).
On Windows, work inside WSL2 end-to-end — user walkthrough:
[docs/WindowsWSLSetup.md](https://github.com/zerobias-org/zerobias/blob/main/docs/WindowsWSLSetup.md).

- **If this session runs on NATIVE Windows** (prompt `PS C:\`, paths
  under `C:\` or `/mnt/c/...`): your ONLY job is getting WSL2 + Ubuntu
  installed. Refuse repo work — no cloning, editing, git, or builds —
  and point the user to their WSL session. Never relay work between a
  Windows agent and a WSL agent.
- **In WSL:** logins and credential setup happen in the Ubuntu
  terminal (`gh auth login`, claude's first-run login,
  `setup-org-credentials.sh`). Once setup is green, offer Remote
  Control (`/remote-control`, or `--launch --remote-control`) to
  continue from the Claude desktop / mobile app.
