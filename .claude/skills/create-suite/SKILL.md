---
name: create-suite
description: >-
  Create a new suite package in the zerobias-org catalog and take it through
  the full content SDLC — scaffold → gradle gate → publishOrg + org load →
  user verifies the org artifact → PR to dev only after explicit sign-off.
  USE THIS when the user says "add suite X", "I need a suite for Y",
  "register <vendor>'s <family> as a suite", or a ZeroBias task asks for a
  suite package. Standalone: works in this repo alone (no meta-repo), and no
  platform task is required (task-driven mode is optional).
---

# create-suite — new suite package, org-first SDLC

Suites sit one level below vendors in the catalog dependency chain
(vendor → **suite** → product → …). This skill produces ONE suite package
and delivers it **org-first**: the default deliverable is the suite loaded
into the user's own org; the PR to `dev` happens only after the user signs
off on the org-loaded result.

```
Phase 0 prerequisites (hard gate — /prerequisites must report READY)
Phase 1 resolve + existence check (suite AND its vendor)
Phase 2 branch (from dev)
Phase 3 scaffold + author content
Phase 4 gate                        ← git add BEFORE gating
Phase 5 publishOrg + org load
Phase 6 user verifies org artifact  ← 🙋 explicit sign-off required
Phase 7 PR --base dev               ← only after sign-off
```

**Suite-vs-no-suite (author's judgment, verify before authoring).** A
suite must be a REAL grouping the vendor itself markets (a platform,
family, or bundle of products) — never an invented bucket. If the vendor
just sells N unrelated products, they don't get a suite. When in doubt,
research the vendor's own taxonomy and ask the user.

**Modes.** Default is **request-driven**: the user names a vendor + suite;
no platform task needed. If the user references a ZeroBias task (UUID or
task name), additionally follow the **task-driven appendix** at the end.

**Headless runs (`claude -p "make suite x"`).** Same flow, three hard rules:
- **Pre-flight first**: run the `prerequisites` skill (Phase 0) before
  touching anything. If anything is missing, print the exact setup
  instructions and exit — never fail mid-flow.
- **The run ENDS after Phase 5** (org load). Print what was created, the
  verification link, and: *"verify the org artifact, then run
  `claude -p 'open the PR for suite <vendor>/<code>'` (or continue
  interactively)"*. Phases 6–7 are human-gated and never run headless.
- **Decision forks stop the run**: suite already exists, vendor missing,
  no official logo found, gate conflict → print a structured report of the
  state and the decision needed, exit cleanly, change nothing further.

**Skill-vs-reality conflicts.** If observed tool behavior contradicts this
skill, STOP: verify against the primary source (`settings.gradle.kts`,
build-tools source in `util`, the workflow YAML), act on what the source
says, and queue a fix to this skill in the same session — never force
reality to match stale text.

## Phase 0 — prerequisites (hard gate)

Invoke this repo's [`prerequisites` skill](../prerequisites/SKILL.md)
(`/prerequisites`) and get `READY` before ANYTHING else — interactive or
headless. If something is missing there are exactly two permitted actions:
install it (with consent) or stop and wait. Never work around it — no
substitute tooling, no raw HTTP instead of the `zb` MCP, no partial
continuation.

This gate applies for the WHOLE flow, not just at the start: if any
prerequisite fails mid-flow (401s, expired token, org load refused, tool
vanished), treat it as a prerequisite regression — STOP the phase you're
in, re-run `/prerequisites`, and resume only from `READY`. Never improvise
past a mid-flow credential failure.

## Phase 1 — resolve inputs + existence check

Needed: **vendor** and **suite name** (natural language). Derive:
- `vendorCode` — must match an existing vendor package code.
- `suiteCode` — lowercase, matching `^[\d_a-z]+$`; prefer plain lowercase
  alphanumeric (the UI's `vspCodeValidator` rejects underscores).
- Official product-family URL and logo URL (research if not provided).

Check both via the `zb` MCP `store` ops (the `portal.*.search` ops found
in older docs do NOT exist):

```
zerobias_execute("store.Vendor.get", { vendorCode: "<vendorCode>" })
    // 404 = vendor missing → STOP; create it first (vendor repo's
    //        /create-vendor), org-first into the SAME target org
zerobias_execute("store.Suite.get", { vendorCode: "<vendorCode>",
                                      suiteCode: "<suiteCode>" })
    // 404 = suite free
```

An **org-only vendor is fine** as the dependency: the suite's
`dependencies` entry resolves via the npm registry, and a first-ever
`publishOrg` of a vendor force-assigns the `latest` dist-tag to its rc, so
`"latest"` resolves to it. Verify the vendor is loaded in the TARGET org
(the `store.Vendor.get` above runs against it).

Also check locally: `ls package/<vendorCode>/ | grep <suiteCode>`. If the
suite exists (platform or local), STOP and ask the user what to do
(update / nothing).

The `zb` MCP is a hard prerequisite (see Prerequisites) — do NOT substitute
raw HTTP calls if it's missing; stop and have it installed instead.

## Phase 2 — branch first (never commit on main)

```bash
git fetch origin
git switch -c feat/suite-<vendorCode>-<suiteCode> origin/dev
```

Content PRs target **`dev`** (org convention: local → org → PR to dev →
promotion toward main), so the branch is cut from `origin/dev`.

## Phase 3 — scaffold + author

```bash
./scripts/createNewSuite.sh package/<vendorCode>/<suiteCode>
echo 'plugins { id("zb.content") }' > package/<vendorCode>/<suiteCode>/build.gradle.kts
```

The scaffold script creates the directory, copies the templates, and fills
`{code}`/`{vendor}`/`{id}`; you fill the remaining
`{name}`/`{description}`/`{url}` placeholders. **Verify the scaffold
immediately**: the file set from `ls -A templates/` must all be present in
`ls -A package/<vendorCode>/<suiteCode>/` (dotfiles included), and
spot-check the layout against a recently-merged suite (e.g.
`ls -A package/cyberab/sca`) — a scaffold bug caught here costs seconds;
caught by the gate it costs a full cycle. Required files in
`package/<vendorCode>/<suiteCode>/`:

```
package.json          # @zerobias-org/suite-<vendor>-<code>
index.yml             # suite metadata
logo.{svg|png|jpg}    # official suite/vendor logo (SVG preferred, unmodified)
build.gradle.kts      # one-line zb.content marker (REQUIRED for publish detect)
.npmrc                # REQUIRED — validator hard-fails with ".npmrc missing"
```

**`.npmrc`** is REQUIRED (`templates/.npmrc` has it, but verify the
scaffold actually copied it — dotfiles are easy to miss):

```
@zerobias-org:registry=https://pkg.zerobias.org
//pkg.zerobias.org/:_authToken=${ZB_TOKEN}
```

**package.json** (matches the existing corpus — keep conventions):

```json
{
  "name": "@zerobias-org/suite-<vendorCode>-<suiteCode>",
  "version": "1.0.0",
  "description": "Suite package <suiteCode> for vendor <vendorCode>.",
  "author": "team@zerobias.com",
  "license": "ISC",
  "type": "module",
  "repository": {
    "type": "git",
    "url": "git@github.com:zerobias-org/suite.git",
    "directory": "package/<vendorCode>/<suiteCode>/"
  },
  "publishConfig": { "registry": "https://pkg.zerobias.org/" },
  "files": ["index.yml", "logo.*"],
  "dependencies": {
    "@zerobias-org/vendor-<vendorCode>": "latest"
  },
  "zerobias": {
    "dataloader-version": "1.0.0",
    "import-artifact": "suite",
    "package": "<vendorCode>.<suiteCode>",
    "orgId": "<target-org-uuid>"
  }
}
```

- Never hand-edit `version` afterwards — CI owns bumps.
- The vendor dependency is the ONLY dependency — suites are otherwise
  pure metadata.
- `zerobias.package` MUST equal `<vendorCode>.<suiteCode>` (dot-joined
  directory path under `package/`).
- **Set `zerobias.orgId: "<org-uuid>"` already now, before the first gate.**
  The gate's Neon step behaves differently with it: orgId present → the
  ephemeral branch is seeded with the org and the load runs org-scoped
  (`dataloaderExec: Seeding org … (zerobias.orgId present)`), matching how
  org-scoped tokens authorize; orgId absent → the package is treated as
  global-catalog and org-scoped tokens can 401 the step. The gate-stamp's
  sourceHash does NOT cover `package.json`, so setting (and later, in
  Phase 7, deleting) orgId never invalidates the stamp — there is no
  reason to defer it to Phase 5.

**index.yml**:

```yaml
id: <fresh-uuid-v4-lowercase>
name: <Suite Full Name>
description: >-
  <What the product family/platform is.>
imageUrl: https://cdn.auditmation.io/logos/<vendorCode>-<suiteCode>.<ext>
logo: https://cdn.auditmation.io/logos/<vendorCode>-<suiteCode>.<ext>
code: <suiteCode>
type: suite
ownerId: 00000000-0000-0000-0000-000000000000
vendorCode: <vendorCode>
vendorId: <the vendor's UUID>
status: active
url: https://<suite-page-url>
tags: []
aliases:
  - <common alternate name>
```

- No `created`/`updated` fields — the dataloader stamps them server-side.
  Fresh UUID v4 lowercase; `status: active` (corpus convention).
- `imageUrl`/`logo` extension must match the actual logo file; note the
  CDN name is `<vendorCode>-<suiteCode>.<ext>` for suites.
- `vendorCode` binds the suite to its vendor — must equal the parent
  directory name and the vendor dependency's code.
- `vendorId` MUST be the vendor's real UUID — take it from the Phase 1
  `store.Vendor.get` result (`id` field). The dataloader looks the vendor
  up by id and REJECTS the load when `vendor.code !== vendorCode`. (Legacy
  fallback: `npm install` in the package dir and copy `id` from
  `node_modules/@zerobias-org/vendor-<code>/index.yml`.)

**Logo**: download the official asset (vendor press-kit / brand pages).
Never modify SVG content. A suite without its own mark uses the vendor
logo. If none found, note it in the PR.

## Phase 4 — gate (git add FIRST, always via zbb)

All builds go through `zbb` — **never invoke `./gradlew` directly**. Only
zbb injects the slot env (token, URLs) into the build; a bare gradle run
silently misses it.

```bash
ls -A package/<vendorCode>/<suiteCode>   # completeness check BEFORE first gate:
                                         # all required files incl. DOTFILES
                                         # (.npmrc!) — a miss costs a gate cycle
git add package/<vendorCode>/<suiteCode>/  # BEFORE gating — the gate-stamp's
                                         # sourceHash enumerates git ls-files;
                                         # untracked files are invisible to it
zbb --slot <slot> stack add "$(git rev-parse --show-toplevel)"  # once per slot,
                                         # else "no added stack is reachable"
cd "$(git rev-parse --show-toplevel)/package/<vendorCode>/<suiteCode>" && zbb --slot <slot> gate
zbb gate --check                         # validate the stamp (no slot needed)
```

⚠ Write EVERY `zbb gate` / `publishOrg` as `cd <absolute-path> && zbb …`
in ONE command — never rely on inherited shell cwd (background shells
reset it, and a repo-root `publishOrg` targets the wrong project).

`gate` = `validateContent` (schema + package-identity + logo checks) +
the Neon dataloader step — which runs **iff `ZB_TOKEN` is present** in the
slot env. With the org-owner setup from Phase 0 it runs for real, resolving
the vendor dependency from the registry. On success it writes
`package/<vendorCode>/<suiteCode>/gate-stamp.json` — **commit that file**;
CI's publishGuard rejects publishes without a valid committed stamp. CI
does not rerun your tests — it validates the committed stamp.

If you gated before adding new files, re-gate after `git add`.
Legacy `npm install` / `npm shrinkwrap` / `npm run validate` are gone —
zbb owns the lifecycle. Don't commit a shrinkwrap.

## Phase 5 — publishOrg + load into the user's org

Publishes an org-private rc version (`<X.Y.Z+1>-rc.<orgIdStripped>.<n>`,
computed by zbb — never hand-authored) and queues a dataloader job into
the target org — no PR, no shared catalog involved.

1. Confirm the target is set in `package.json`: `"zerobias": { …, "orgId":
   "<org-uuid>" }` — already done in Phase 3 (before the gate), where it
   belongs; set it now only if it was somehow missed.
2. Environment — must be in the **slot/stack env** (a plain shell `export`
   does not reach the gradle build); the `prerequisites` skill and
   `./scripts/setup-org-credentials.sh` own the full reference
   (`ZB_API_KEY` org key, `ZB_TOKEN` registry key, `ZB_PLATFORM_URL`,
   `NPM_CONFIG_TAG`, and the DATALOADER_SERVICE_URL leave-unset rule).
   ⚠ **Slot-env mutation gate:** changing any slot value that redirects
   traffic or identity (URLs, `ZB_ORG_ID`, keys) MID-FLOW requires showing
   the user the evidence and the exact `env set`, and getting confirmation
   BEFORE running it — even when source code proves the change correct.
   Never silently repoint an environment.
3. Run as ONE command with an absolute path — never rely on inherited cwd:
   `cd <repo>/package/<vendorCode>/<suiteCode> && zbb --slot <slot> publishOrg`
   (never bare `./gradlew` — zbb injects the slot env)
4. Verify it landed (by **codes**, not UUID):
   `zerobias_execute("store.Suite.get", { vendorCode: "<vendorCode>", suiteCode: "<suiteCode>" })`
   — and show the user in the app catalog.
5. **Iterate here**: edit → re-gate → re-run `zbb --slot <slot> publishOrg`
   until the user is satisfied. Loading happens ONLY through
   `zbb publishOrg` — never POST the dataloader API directly, and never
   use the MCP to load artifacts (MCP ops are for reads/verification
   only).

⚠ **Dist-tag landmine on iteration (verified in platform source
2026-08-18).** The dataloader's load guard compares the requested version
against the target env's dist-tag, falling back to `latest`. A FIRST
`publishOrg` of a package works because the registry force-assigns
`latest` to that rc. But subsequent rc's only get the `NPM_CONFIG_TAG`
tag (`dev`) while `latest` stays on the first rc — so the org load of
`-rc.<org>.1+` can be REJECTED ("greater than latest"). Until build-tools
moves the env tag itself, the fix is a one-time
`npm dist-tag add <pkg>@<new-rc> latest --registry=https://pkg.zerobias.org`
(run by the user) before re-loading, or ask platform to relax the guard
for org rc versions.

Notes: org users can only queue org-private (`-rc.<org>`) loads — a plain
catalog-semver load is 403 (platform-admin only). The `zb.content` plugin
resolves **mavenLocal-first** (`settings.gradle.kts` never uses
`includeBuild`): a locally-published build-tools in `~/.m2` is what
actually loads. Verify plugin capabilities by grepping the `~/.m2` jar,
not the util checkout.

## Phase 6 — user verification + sign-off  ⭐

Show the user the org-loaded suite (catalog UI or the `store.Suite.get`
result). ⚠️ The logo will render BROKEN in the UI at this stage —
`cdn.auditmation.io/logos/<vendor>-<code>.<ext>` 404s until the suite
reaches `main`, where the publish workflow's `cdn-update` job uploads it
(the dataloader never touches the CDN). Tell the user up front; have them
judge the data fields (name, description, vendor binding, url), and verify
the logo locally (it must be inside the published rc tarball). **Do NOT
proceed to the PR until the user explicitly confirms** (e.g. "looks good,
ship it"). Silence or further tweak requests are NOT sign-off — if
unclear, ask. Headless runs never reach this phase — they stop after
Phase 5 by design.

## Phase 7 — PR to dev (after sign-off only)

1. Flip ownership to the shared catalog: **delete `zerobias.orgId` from
   `package.json`**. No re-gate needed — for content packages the
   gate-stamp's sourceHash covers the `files` payload (`index.yml`,
   `logo.*`), not `package.json`. Leftover `-rc.<org>.<n>` npm versions
   don't collide with catalog semver.
2. Commit — selective staging, conventional message, no co-authors:

```bash
git add package/<vendorCode>/<suiteCode>/
git commit -m "feat(<vendorCode>-<suiteCode>): add <Suite Name> suite package"
git push -u origin feat/suite-<vendorCode>-<suiteCode>
```

3. PR against **dev**:

```bash
gh pr create --base dev \
  --title "feat(<vendorCode>-<suiteCode>): add <Suite Name> suite" \
  --body "…summary, validation checklist (gate ✓, gate-stamp committed ✓,
          org-loaded + user-verified ✓), and anything needing SME review
          (placeholder logo, suite-vs-no-suite judgment, naming calls)…"
```

The PR is how content reaches the shared catalog; the org-private artifact
from Phase 5 stays in the user's org either way. ⚠ If the suite's vendor
is itself org-only, the suite PR must WAIT until the vendor has merged and
published to the shared catalog — CI resolves the `latest` vendor
dependency from the registry, and a shared-catalog suite must not depend
on an org-private vendor rc.

## Common issues

**First rule for any SERVER-side failure** (dataloader jobs, platform
calls): re-run the identical command ONCE before diagnosing or escalating —
pod-side state (secret re-syncs, deploys) changes independently of your
session, and a retry is far cheaper than a wrong escalation.

- **`stack add` from a git worktree fails "Stack 'suite' already exists"** →
  harmless: zbb resolves stacks by `zbb.yaml` name, not path, so a worktree
  of an added repo reaches the slot env without any `stack add`. Skip it.
- **Publish workflow skips the suite** → missing `build.gradle.kts`
  marker; add the one-liner and push.
- **`validateContent` fails** → `code` regex / dir / `zerobias.package`
  mismatch (must be `<vendor>.<code>`), UUID not v4 lowercase, or logo
  file vs `files`/extension mismatch.
- **Vendor dependency unresolvable during gate/publish** → the vendor
  package has no published version visible to your `ZB_TOKEN` (or the
  org rc's `latest` tag was reassigned). Check with
  `npm view @zerobias-org/vendor-<code> dist-tags` from the package dir.
- **`testIntegrationDataloader` errors locally** (instead of skipping) →
  slot misconfigured; check the stack is added to the slot and the slot env
  holds `ZB_TOKEN` + `ZB_PLATFORM_URL` (`zbb --slot <slot> env get … | tail -n1`
  from INSIDE the repo — zbb may prefix a vault banner, value = last line).
- **`publishOrg` 401 on `/dana/me` or the org load is refused** →
  the ORG key (`ZB_API_KEY`, fallback `ZB_TOKEN`) is not an org OWNER key
  of the org in `zerobias.orgId` — member keys authenticate but cannot
  load; non-prod targets REQUIRE `ZB_API_KEY` (see prerequisites).
- **Org load rejected "greater than latest"** → the dist-tag landmine in
  Phase 5 — the new rc isn't covered by the env tag / `latest`.
- **`dataloaderOrgJob` fails with `npm … 401 Unauthorized … Invalid API
  key`** (server-side, `/root/.npm` in the log) → the TARGET env's
  `platform-dataloader-service` pod fetches the package with its OWN
  `ZB_TOKEN` — no client-side change can fix it. Retry `publishOrg`
  cheaply first; if it persists, escalate to platform infra.
- **`publishOrg` rejects the name** → the package name/code already exists
  in the shared catalog; org-publish only works for brand-new / org-owned
  names.

## Task-driven appendix (only when the user references a ZeroBias task)

- Fetch: `platform.Task.get` (UUID). Task code is not searchable.
- Assign + start: `platform.Party.getMyParty` → `platform.Task.update` with
  `assigned` (party id), `customFields` (`artifactType: suite`, `repoUrl`,
  `branchName`), and the Start transition — **always take transition IDs
  from `task.nextTransitions`**, never hardcode them.
- Comment progress at start and completion (`platform.Task.addComment`).
- After the PR: transition to Peer Review. Link to a parent task with
  `platform.Resource.linkResources` (`fromResource`/`toResource`) if this
  suite was created as a dependency (e.g. for a product).

## References (this repo only)

- [`CLAUDE.md`](../../../CLAUDE.md) — repo conventions, publish workflow,
  validator philosophy.
- [`scripts/createNewSuite.sh`](../../../scripts/createNewSuite.sh) —
  scaffold script.
