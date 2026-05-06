---
name: migrate-packages
description: Migrate the next batch of suites to the gradle pipeline. Drops per-suite build.gradle.kts marker, ensures .npmrc, runs ./gradlew :<vendor>:<suite>:gate, fixes drift, major-bumps the version (1.x → 2.0.0), commits per-suite.
argument-hint: "[<vendor>/<suite>...] [--batch=N] [--dry-run]"
---

# Migrate Suite Packages

Per-repo companion to `/migrate-content-to-zbb` (which bootstrapped this repo onto gradle). Use this skill to migrate suites **one at a time** within `org/suite`. Layout: `package/<vendor>/<suite>/` (depth 2).

## Trigger

```
/migrate-packages [<vendor>/<suite>...] [--batch=N] [--dry-run]
```

Examples:
- `/migrate-packages` — pick the next N pending suites from `MIGRATION_STATUS.md` (or `find` if no tracker).
- `/migrate-packages aicpa/soc2 atlassian/cloud iso/27001` — migrate exactly these.
- `/migrate-packages --batch=5 --dry-run` — show the next 5 candidates without changing anything.

## Pre-flight

1. `git status` — must be on a feature branch, not `main`.
2. Confirm gradle bootstrap is in place: root `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `gradle-ci.properties` exist; `.github/workflows/publish.yml` uses `zbb-publish-reusable.yml`. If anything is missing, abort and direct the user to `/migrate-content-to-zbb`.
3. Identify candidates: directories matching `package/<vendor>/<suite>/` WITHOUT a `build.gradle.kts` marker. Check `MIGRATION_STATUS.md` for pending vs flagged.
4. Order: simplest first (smallest `index.yml`, no logo edge cases). Skip anything in `MIGRATION_STATUS.md`'s `Flagged` section — fix that drift in a separate commit before migrating.
5. Confirm the **parent vendor exists** in `org/vendor` and is on the gradle line. Suites depend on a vendor row at load time; if the vendor isn't published, the dataloader gate will fail with a vendor-lookup error.

## Per-suite loop

For each suite in the batch, do steps 1–6 in order, then commit and move on.

### 1. Drop the marker
Create `package/<vendor>/<suite>/build.gradle.kts`:
```kotlin
plugins { id("zb.content") }
```

### 2. Ensure `.npmrc`
The validator requires `package/<vendor>/<suite>/.npmrc`. If absent, copy from a sibling already-migrated suite (e.g. `package/adobe/ccf/.npmrc`).

### 3. Run **full** `:gate` (NOT just `:validateContent`)
```bash
./gradlew :<vendor>:<suite>:gate
```
**Why full `:gate` matters:** the publish workflow's preflight rejects any suite without a committed `gate-stamp.json` (`gate-stamp.json is missing or invalid — run zbb gate locally and commit the stamp before publishing`). The stamp is written by the `:writeGateStamp` task that runs at the end of `:gate`. Running only `:validateContent` does NOT produce a stamp — the suite will pass local file-checks but fail in CI.

`:gate` chains: `validate` → `lint` → `compile` → `test*` → `buildArtifacts` → `testIntegrationDataloader` → `writeGateStamp`. Without `NEON_API_KEY` / `NEON_PROJECT_ID` in env, `testIntegrationDataloader` is **skipped** (not failed) — the stamp still gets written, and CI re-runs the dataloader test against an ephemeral Neon branch on push. Locally not having Neon creds is fine; just confirm the stamp file appears at `package/<vendor>/<suite>/gate-stamp.json` after the build.

The validator surfaces drift one error at a time. Common fixes for suites:

- **`package.json name`** must equal `@zerobias-org/suite-<vendor>-<suite>` (matching the path segments). Fix the `name` to match the directory; do NOT rename the directory.
- **`zerobias.package`** must equal `<vendor>.<suite>` (dot-separated). Legacy `auditmation.package` is accepted but should be renamed.
- **`vendorId` mismatch** — the dataloader looks up the parent vendor by id and rejects if `vendor.code != index.yml.vendorCode`. Run `npm install` in the suite dir, then copy the parent vendor's `id` from `node_modules/@zerobias-org/vendor-<vendorCode>/index.yml` into `index.yml.vendorId`.
- **Missing `.npmrc`** — see step 2.
- **Logo issues**:
  - Multiple logo files (`logo.svg` + `logo.png`) — keep one.
  - Magic-byte mismatch (e.g. `logo.svg` is actually an HTML S3 error page) — re-fetch the original or remove.
  - Size out of range (<500B / >5MB) — replace.
  - `package.json` `files` array doesn't include the logo — add `"logo.*"` (or the exact filename).
  - Suites without a logo are valid (logos are optional in this validator) — early-return path; no action needed.
- **Duplicate `id` UUID** (`:validateUniqueIds` collision) — investigate which other suite owns that UUID. The newcomer needs a fresh UUID via `uuidgen`. Existing UUIDs are stable — don't change them.
- **Template placeholder leftovers** (`{vendor}`, `${vendor}`, `{code}` still in any field) — replace with the actual values. The validator will catch most via `requireNonBlankString`'s placeholder check.

Re-run `:gate` after each fix until it passes.

### 4. Major-bump version
```bash
# package/<vendor>/<suite>/package.json: bump major.
# 1.x.x → 2.0.0    (most existing suites)
# 0.x.x → 1.0.0    (rare)
# 2.x.x — no-op    (already on the gradle line)
```
Universal repo rule: every suite's first gradle publish gets a major bump. This is the version-line transition, not a content change.

### 5. (Optional) Re-run `:gate` after the version bump
Cheap sanity check.

### 6. Commit
One commit per suite. Conventional commit format:
```
feat(suite-<vendor>-<suite>)!: migrate to gradle pipeline (<oldVer> → 2.0.0)
```
The `!` marks the major bump as breaking. Stage exactly: `package/<vendor>/<suite>/build.gradle.kts`, `package/<vendor>/<suite>/.npmrc` (if you added it), `package/<vendor>/<suite>/package.json` (version bump), **`package/<vendor>/<suite>/gate-stamp.json`** (mandatory — the publish preflight rejects without it), and any drift fixes (e.g. `index.yml`, `logo.svg`).

### 7. (After the batch) Verify on a feature branch
```bash
gh workflow run publish.yml --ref <branch>
```
On a feature branch, `version` (single-writer) is skipped and `publish` runs in pre-release mode (no `latest` dist-tag). Confirm `detect` lists exactly the suites you bumped, then validate the published artifacts before merging to main.

## Picking the next batch

Order rules of thumb:
1. Skip the `MIGRATION_STATUS.md` `Flagged` section until its drift is fixed in a separate PR.
2. Group suites by parent vendor when possible — failure modes (stale `vendorId`, drifted vendor reference) are shared.
3. Start with simple, single-version frameworks (`adobe/ccf`, `aicpa/gapp`) before tackling multi-region offerings (`amazon/aws`, `microsoft/azure`).
4. Cap each PR at ~10 suites. Easier to review, easier to bisect.
5. Run `./scripts/migration-status.sh` after each batch to refresh the tracker.

## What NOT to do

- Do NOT change suite `id` UUIDs. Stable identifiers; changing one detaches existing DB rows.
- Do NOT change `vendorId` to "fix" a mismatch — fix the `vendorCode` in your suite or update the parent vendor's `index.yml`. Whichever side is wrong.
- Do NOT rename directories to make `package.json name` match. Metadata follows the directory.
- Do NOT skip the major bump because "no source changed". The bump reflects the publish-pipeline transition.
- Do NOT batch unrelated suites into one commit. One commit per suite keeps `git revert` precise.
- Do NOT touch `.husky/` if present — empty placeholder, not part of canonical pattern.

## Reference files

- `package/adobe/ccf/`, `package/amazon/aws/`, `package/avigilon/alta/`, `package/google/gcp/`, `package/google/workspace/` — already migrated; use as drop-in references.
- `templates/index.yml`, `templates/package.json` — what a NEW suite looks like (single-curly placeholders: `{vendor}`, `{code}`, `{name}`).
- `MIGRATION_STATUS.md` — pending / done / flagged tracker. Regenerate via `./scripts/migration-status.sh`.
- Root `build.gradle.kts:9-37` — validator philosophy comment.
- `org/vendor/` — parent dependency repo. Suites' `vendorId` must point to a vendor `id` from there.
- `org/util/packages/build-tools/.../SchemaPrimitives.kt` — validator helpers and error message shapes.

## See also

- `/migrate-content-to-zbb` — meta-repo skill that bootstrapped this repo. Use only when migrating a new repo onto gradle, not for per-suite work here.
- `.claude/skills/create-suite.md` — sibling skill for creating a NEW suite from a ZeroBias task. Different workflow.
