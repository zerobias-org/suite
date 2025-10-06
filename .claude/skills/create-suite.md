# Create Suite Skill

Create suite packages from ZeroBias tasks with automatic dependency resolution and proper task management.

## Trigger

```
/create-suite [task-id]
```

**Arguments:**
- `task-id` (optional): ZeroBias task UUID or task name. If not provided, will prompt for input.

## Examples

```
/create-suite 9bc9db43-062d-44f9-9942-c88867d06166
/create-suite "Create suite: aiuc/aiuc-1 (AIUC-1 AI Agent Standard)"
/create-suite
```

---

## Workflow

### Step 1: Get Task Details

```javascript
// If UUID provided
const task = zerobias_execute("platform.Task.get", { id: taskId })

// If task name provided (search)
const results = zerobias_execute("portal.Task.search", {
  searchTaskBody: { search: "suite name" }
})
const task = results.items.find(t => t.name.includes("suite"))
```

**Task code is NOT searchable** - use UUID or task name.

### Step 2: Extract Suite Information

| Field | Source | Example |
|-------|--------|---------|
| **Task ID** | `task.id` | `9bc9db43-062d-44f9-9942-c88867d06166` |
| **Task Code** | `task.code` | `contextDev-5` |
| **Vendor Code** | Parse from name | `aiuc` |
| **Suite Code** | Parse from name | `aiuc-1` |
| **Suite Name** | Parse from name | `AIUC-1 AI Agent Standard` |
| **Artifact Type** | `task.customFields.artifactType` | `suite` |
| **Branch Name** | `task.customFields.branchName` | `feat/suite-aiuc-aiuc-1` |
| **Repo URL** | `task.customFields.repoUrl` | `https://github.com/zerobias-org/suite` |
| **Website URL** | Parse from description | `https://aiuc-1.com` |
| **Logo URL** | Parse from description | `https://aiuc-1.com/logo.svg` |

**Parse suite info from task name:**
```javascript
// Task name format: "Create suite: {vendor}/{suite} ({name})"
const match = task.name.match(/Create suite:\s*(\S+)\/(\S+)\s*\(([^)]+)\)/)
const vendorCode = match[1]  // "aiuc"
const suiteCode = match[2]   // "aiuc-1"
const suiteName = match[3]   // "AIUC-1 AI Agent Standard"
```

**Parse additional info from task description:**
```javascript
// Task description may contain website and logo URLs
// Example description:
// "Create suite package for AIUC-1 AI Agent Standard.
//  Website: https://aiuc-1.com
//  Logo: https://aiuc-1.com/assets/logo.svg"

// Extract website URL
const websiteMatch = task.description.match(/website:\s*(https?:\/\/[^\s]+)/i)
  || task.description.match(/(https?:\/\/[^\s]+)/)
const websiteUrl = websiteMatch ? websiteMatch[1] : null

// Extract logo URL (explicit)
const logoMatch = task.description.match(/logo:\s*(https?:\/\/[^\s]+)/i)
const logoUrl = logoMatch ? logoMatch[1] : null
```

### Step 3: Assign and Transition to In Progress

**IMPORTANT:** Set required fields BEFORE applying transition.

```javascript
// Get your party ID
const party = zerobias_execute("platform.Party.getMyParty", {})

// Update task with required fields and transition
zerobias_execute("platform.Task.update", {
  id: task.id,
  updateTask: {
    assigned: party.id,  // Party ID, NOT principal ID
    customFields: {
      artifactType: "suite",
      repoUrl: "https://github.com/zerobias-org/suite",
      branchName: `feat/suite-${vendorCode}-${suiteCode}`
    },
    transitionId: "7f140bbe-4c10-54ac-922c-460c66392fad"  // Start
  }
})
```

**Transition Required Fields:**

| Transition | Required Fields | Required Custom Fields |
|------------|-----------------|------------------------|
| Start | assigned | repoUrl, branchName |
| Peer Review | assigned, approvers | - |
| Accept | assigned | fixVersion |

### Step 4: Add Starting Comment

```javascript
zerobias_execute("platform.Task.addComment", {
  id: task.id,
  newTaskComment: {
    commentMarkdown: `**Started:** Creating suite package.

**Task:** ${task.code}
**Vendor:** ${vendorCode}
**Suite:** ${suiteCode}
**Branch:** feat/suite-${vendorCode}-${suiteCode}
**Repo:** https://github.com/zerobias-org/suite`
  }
})
```

### Step 5: Check Dependencies (MANDATORY)

**CRITICAL:** Suites depend on vendors. The vendor MUST exist first.

```
vendor → suite → framework/standard/benchmark
```

```javascript
// Check if vendor exists
const vendors = zerobias_execute("portal.Vendor.search", {
  searchVendorBody: { search: vendorCode }
})

const vendorExists = vendors.items.some(v =>
  v.code?.toLowerCase() === vendorCode.toLowerCase()
)

if (!vendorExists) {
  // STOP - Vendor must be created first
  // See: docs/orchestration/TASK_MANAGEMENT.md#dependency-management
  // 1. Create vendor subtask
  // 2. Complete with: /create-vendor {vendor-task-id}
  // 3. Then resume this task
}
```

**If vendor is missing:** See [TASK_MANAGEMENT.md](../../../docs/orchestration/TASK_MANAGEMENT.md#dependency-management) for the subtask creation and skill invocation workflow.

### Step 6: Check if Suite Already Exists

```javascript
const suites = zerobias_execute("portal.Suite.search", {
  searchSuiteBody: { search: `${vendorCode} ${suiteCode}` }
})

const exists = suites.items.some(s =>
  s.vendorCode?.toLowerCase() === vendorCode.toLowerCase() &&
  s.code?.toLowerCase() === suiteCode.toLowerCase()
)

if (exists) {
  // Suite already exists - task may be complete or duplicate
}
```

### Step 7: Create Git Branch

```bash
cd /path/to/zerobias-org/suite
git checkout main
git pull origin main
git checkout -b feat/suite-{vendorCode}-{suiteCode}
```

### Step 8: Create Suite Package Structure

```bash
# Create package directory
mkdir -p package/{vendorCode}/{suiteCode}
cd package/{vendorCode}/{suiteCode}
```

**Required files:**

```
package/{vendorCode}/{suiteCode}/
├── package.json          # @zerobias-org/suite-{vendor}-{code}
├── index.yml             # Suite metadata
├── logo.svg              # Suite/standard logo
├── npm-shrinkwrap.json   # Generated dependency lock
└── .npmrc                # Registry configuration
```

### Step 9: Create package.json

```json
{
  "name": "@zerobias-org/suite-{vendorCode}-{suiteCode}",
  "version": "1.0.0",
  "description": "Suite package {suiteCode} for vendor {vendorCode}.",
  "author": "team@zerobias.com",
  "license": "ISC",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com/"
  },
  "repository": {
    "type": "git",
    "url": "git@github.com:zerobias-org/suite.git",
    "directory": "suite/"
  },
  "files": ["index.yml", "logo.svg"],
  "scripts": {
    "nx:publish": "../../../scripts/publish.sh",
    "prepublishtest": "../../../scripts/prepublish.sh",
    "correct:deps": "ts-node ../../../scripts/correctDeps.ts",
    "validate": "ts-node ../../../scripts/validate.ts"
  },
  "auditmation": {
    "package": "{vendorCode}.{suiteCode}",
    "import-artifact": "suite",
    "dataloader-version": "5.0.14"
  },
  "dependencies": {
    "@zerobias-org/vendor-{vendorCode}": "latest"
  }
}
```

**CRITICAL:** The dependency `@zerobias-org/vendor-{vendorCode}` is required.

### Step 10: Create index.yml

```yaml
vendorId: {vendor-uuid}           # Get from vendor's index.yml after npm install
code: {suiteCode}
status: active
id: {generate-uuid-v4}
name: {Suite Full Name}
type: suite
ownerId: 00000000-0000-0000-0000-000000000000
created: {current-iso-timestamp}
updated: {current-iso-timestamp}
vendorCode: {vendorCode}
vendorName: {Vendor Full Name}
url: https://{suite-website}.com
description: >-
  Description of the suite/standard.
logo: https://cdn.auditmation.io/logos/{vendorCode}-{suiteCode}.svg
```

**CRITICAL:**
- Generate new UUID v4 for `id`
- Use real current timestamp (not placeholder like `00:00:00.000Z`)
- `vendorId` must match the vendor's `index.yml` `id` field

### Step 11: Create .npmrc

```
@zerobias-org:registry=https://npm.pkg.github.com/
//npm.pkg.github.com/:_authToken=${ZB_TOKEN}
```

### Step 12: Install Dependencies and Get vendorId

```bash
npm install
```

**CRITICAL:** After install, get the correct vendorId:

```bash
cat node_modules/@zerobias-org/vendor-{vendorCode}/index.yml | grep "^id:"
```

Update `index.yml` with the correct `vendorId`.

### Step 13: Download Logo and Build

**Use logo URL extracted from task description (Step 2):**

```bash
# If logo URL specified in task
curl -o logo.svg "{logoUrl}"

# Or try common logo locations on suite/standard website
curl -o logo.svg "https://{website}/logo.svg"
curl -o logo.svg "https://{website}/assets/logo.svg"
curl -o logo.svg "https://{website}/images/logo.svg"

# Verify download
ls -lh logo.svg
```

**Logo best practices:**
- Use official SVG logos when available
- Never modify SVG content
- Verify file size after download
- If no logo found, note in PR that logo needs to be added

```bash
# Generate shrinkwrap
npm shrinkwrap

# Validate
npm run validate
```

### Step 14: Handle Unpublished Vendor (npm link)

If the vendor package is not yet published:

```bash
# In vendor repo
cd /path/to/vendor/package/{vendorCode}
npm link

# In suite repo
cd /path/to/suite/package/{vendorCode}/{suiteCode}
npm link @zerobias-org/vendor-{vendorCode}
npm install
npm shrinkwrap
```

**IMPORTANT:** After using npm link, fix the shrinkwrap to remove local path reference:

```json
{
  "dependencies": {
    "@zerobias-org/vendor-{vendorCode}": {
      "version": "1.0.0"
    }
  }
}
```

The shrinkwrap should show version `"1.0.0"`, not a `file://` path.

### Step 15: Commit and Push

```bash
git add package/{vendorCode}/{suiteCode}/
git commit -m "feat({vendorCode}-{suiteCode}): add {Suite Name} suite package

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

git push origin feat/suite-{vendorCode}-{suiteCode}
```

### Step 16: Create Pull Request

```bash
gh pr create --title "feat({vendorCode}-{suiteCode}): add {Suite Name}" --body "$(cat <<'EOF'
## Summary
- **Task:** {task.code}
- **Vendor:** {vendorCode}
- **Suite:** {suiteCode}
- **Package:** @zerobias-org/suite-{vendorCode}-{suiteCode}

## Dependencies
- Vendor: @zerobias-org/vendor-{vendorCode}

## Validation
- [x] `npm run validate` passes
- [x] vendorId matches vendor package
- [x] Logo file present

## Task Reference
- **Task Code:** {task.code}
- **Task ID:** {task.id}

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 17: Update Task Status

```javascript
// Add completion comment
zerobias_execute("platform.Task.addComment", {
  id: task.id,
  newTaskComment: {
    commentMarkdown: `## Suite Created

**Task:** ${task.code}
**Package:** @zerobias-org/suite-${vendorCode}-${suiteCode}
**Branch:** feat/suite-${vendorCode}-${suiteCode}
**PR:** ${prUrl}

### Dependencies
- Vendor: @zerobias-org/vendor-${vendorCode}

### Next Steps
- PR needs review and merge
- After merge, suite will be available in catalog`
  }
})

// Transition to awaiting_approval
zerobias_execute("platform.Task.update", {
  id: task.id,
  updateTask: {
    transitionId: "f017a447-0994-594d-9417-39cbc9a4de88"  // Peer Review
  }
})
```

---

## Linking Tasks

Link suite task to related tasks (vendor, framework):

```javascript
const relatesToLinkType = "b8bd95d0-b33c-11f0-8af3-dfaccf31600e"

// Link to vendor task (dependency)
zerobias_execute("platform.Resource.linkResources", {
  fromResource: suiteTaskId,
  toResource: vendorTaskId,
  linkType: relatesToLinkType
})

// Link to framework task (parent)
zerobias_execute("platform.Resource.linkResources", {
  fromResource: suiteTaskId,
  toResource: frameworkTaskId,
  linkType: relatesToLinkType
})
```

**Note:** Use `toResource` (not `toResourceId`), and `linkType` must be a UUID.

---

## Common Issues

### vendorId mismatch
Always verify `vendorId` after `npm install`:
```bash
grep "^id:" node_modules/@zerobias-org/vendor-{vendorCode}/index.yml
```

### npm-shrinkwrap.json has file:// reference
After using `npm link`, edit shrinkwrap to remove local path:
```json
{
  "dependencies": {
    "@zerobias-org/vendor-{vendorCode}": {
      "version": "1.0.0"
    }
  }
}
```

### Vendor not found during npm install
If vendor is not published yet:
1. Use `npm link` as described above
2. Or wait for vendor PR to be merged and published

### Validation fails
- Check `index.yml` has all required fields
- Verify `vendorId` matches vendor package
- Ensure timestamps are real (not placeholders)
- Check `package.json` has vendor dependency

---

## Workflow Transitions Reference

| Transition | Target Status | ID |
|------------|---------------|-----|
| Start | in_progress | `7f140bbe-4c10-54ac-922c-460c66392fad` |
| Peer Review | awaiting_approval | `f017a447-0994-594d-9417-39cbc9a4de88` |
| Accept | released | `1d2e9381-f609-5e26-8bc6-7bbb65a9048d` |
| Reject | in_progress | `dda277e6-12d4-581b-922c-4e80d58d9083` |
| Cancel | cancelled | `711aa97f-f0bf-5c56-936f-f5e54d9de1f3` |

**Note:** Always get actual IDs from `task.nextTransitions`.

---

## Dependency Chain

```
vendor → suite → framework/standard/benchmark → crosswalk
```

- **Suites REQUIRE vendors** - always check/create vendor first
- **Frameworks REQUIRE suites** - suite must exist before framework

---

## References

- **Meta-repo CLAUDE.md:** `../../CLAUDE.md`
- **Orchestration docs:** `../../docs/orchestration/`
- **Vendor repo:** `../../vendor/`
- **Templates:** `templates/`
