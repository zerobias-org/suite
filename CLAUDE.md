# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Lerna monorepo containing compliance and security framework suites. Each suite represents a specific regulatory framework, standard, or compliance requirement (like ISO 27001, NIST 800-53, SOC2, etc.) organized by vendor/organization and specific standard code.

## Common Development Commands

### Setup and Installation
- `npm install` - Setup husky hooks and install root dependencies
- `npm run bootstrap` - Bootstrap all packages using Lerna
- `npm run build` - Build all packages
- `npm run reset` - Full clean and rebuild (clean + correct deps + bootstrap + build)

### Development Workflow
- `npm run validate` - Validate all modified suites for proper structure and dependencies
- `npm run correct:deps` - Fix dependencies across all packages

### Package Management
- `npm run lerna:publish` - Publish packages (used in CI/CD)
- `npm run nx:publish` - Correct dependencies and publish modified packages since last release

## Creating New Suites

### Directory Structure
Suites are organized as: `package/{vendor}/{code}/`
- `{vendor}` - Organization/standard body (e.g., iso, nist, owasp)
- `{code}` - Specific standard identifier (e.g., 27001, 800-53, asvs)

### Creation Process
1. Create directory: `package/{vendor}/{code}/`
2. Run: `sh scripts/createNewSuite.sh package/{vendor}/{code}`
3. Navigate to directory: `cd package/{vendor}/{code}`
4. Install dependencies: `npm install`
5. Validate: `npm run validate` from repository root

### Required Files for Each Suite
- `package.json` - NPM package configuration
- `index.yml` - Suite metadata and configuration
- `logo.png` or `logo.svg` - Visual identifier
- `.npmrc` - NPM registry configuration
- `CHANGELOG.md` - Version history (auto-generated)

## Suite Structure and Requirements

### package.json Requirements
- Name format: `@zerobias-org/suite-{vendor}-{code}`
- Must include `auditmation` section with:
  - `package: "{vendor}.{code}"`
  - `import-artifact: "suite"`
  - `dataloader-version: "1.0.0"`
- Dependencies must include exactly one vendor package: `@zerobias-org/vendor-{vendor}`
- Standard scripts: `correct:deps`, `validate`

### index.yml Requirements
- Must contain: `id`, `name`, `description`, `url`, `vendorCode`, `vendorId`, `status`
- Optional: `logo`, `imageUrl`, `tags`, `aliases`
- No template placeholders like `{code}`, `{name}`, etc.

### Vendor Integration
- Each suite depends on its corresponding vendor package from `@zerobias-org/vendor-{vendor}`
- Vendor packages contain the actual framework definitions and controls
- Suite packages reference and configure these vendor definitions
- Vendor information can be found at: https://github.com/zerobias-org/vendor
- The vendor bundle package `@zerobias-org/vendor-bundle` contains all available vendors

## Versioning and Publishing

### Version Management
- Uses Lerna with independent versioning
- Starting version for new suites: `1.0.0-rc.1`
- Conventional commits drive automatic version bumping
- Version bumps happen automatically in CI/CD, not in PRs

### Release Process
- Pull requests trigger validation and optional dry-runs
- Merging to main triggers automatic publishing via GitHub Actions
- Suites are published to GitHub Package Registry (`https://npm.pkg.github.com/`)

## File Processing Rules

### SVG Files
- When working with SVG files (logos), never modify the content
- SVG files should remain unchanged during any operations

### Required Post-Installation Steps
- Always run `npm install` after creating or modifying a suite
- The vendor dependency will force installation of the vendor package together with the suite package
- **After installing vendor dependency**: Always check `node_modules/@zerobias-org/vendor-{vendor}/index.yml#id` to get the correct `vendorId` for the suite's index.yml

## Validation and Testing

### Validation Script
The `scripts/validate.ts` script checks:
- Proper package.json structure and naming
- Required auditmation configuration section
- Vendor dependency configuration
- index.yml structure and required fields
- Presence of required files (.npmrc, package.json, index.yml)

### GitHub Actions
- `pull_request.yml` - Runs validation on PRs
- `lerna_publish.yml` - Handles publishing after merge
- `lerna_post_publish.yml` - Post-publish notifications

## Code Architecture

### Monorepo Structure
- Root manages shared tooling and CI/CD
- Each suite package is independent but follows consistent patterns
- Lerna manages inter-package dependencies and publishing
- NX provides caching and build optimization

### Scripts and Tooling
- `scripts/` contains shared build and validation scripts
- `templates/` provides boilerplate for new suites
- TypeScript scripts handle dependency management and validation
- Shell scripts manage package lifecycle operations

## Best Practices from Production Suites

### Package Naming and Description
- Package name: `@zerobias-org/suite-{vendor}-{code}`
- Description: `"Suite package {code} for vendor {vendor}"`
- Author: `"team@zerobias.com"`

### Version Management
- Production suites use semantic versioning (1.0.x+)
- New suites start with `"1.0.0-rc.0"`
- Version bumps are automatic via Lerna - never manually update versions
- CHANGELOG.md files are auto-generated from conventional commits

### Dependencies
- Always use `"latest"` for vendor dependencies in package.json
- Exactly one dependency: `@zerobias-org/vendor-{vendor}`
- Dependencies resolve from custom registry: `https://pkg.zerobias.org/`

### Standard Configuration Values
- `dataloader-version: "1.0.0"` (current standard across all suites)
- Repository directory: `"package/{vendor}/{code}/"` in package.json
- Scripts always reference: `../../../scripts/`
- Logo URL pattern: `https://cdn.auditmation.io/logos/{vendor}-{code}.png` (or .svg)

### File Structure Requirements
Every suite must include:
- `package.json` - NPM configuration
- `index.yml` - Suite metadata
- `logo.png` or `logo.svg` - Logo file (never modify content)
- `CHANGELOG.md` - Auto-generated version history
- `.npmrc` - Registry configuration

### Logo Best Practices
- **Use official logos**: Always try to find and use official vendor logos (PNG or SVG)
- **Reuse existing logos**: For frameworks from the same vendor (e.g., CSA), copy the logo from another suite of the same vendor
- **Download approach**: Use curl to download official logos directly:
  ```bash
  curl -o /path/to/suite/logo.png "https://official-logo-url.png"
  ```
- **Verify download**: Check file size with `ls -lh` to ensure complete download
- **Never modify**: Don't edit logo content - preserve official branding exactly as provided
- **Logo naming**: Follow pattern `https://cdn.auditmation.io/logos/{vendor}-{code}.png` in index.yml (or .svg)

### Validation Notes
- Templates contain placeholders like `{vendor}`, `{code}` - these must be replaced
- UUIDs must be unique per suite, lowercase UUID v4 format (generated automatically by creation script)
- All metadata fields in index.yml must have real values, not template placeholders
- **Timestamps**: Always use real current time for `created` and `updated` fields, never use placeholder times like `00:00:00.000Z`

## Authentication

Set `ZB_TOKEN` environment variable with API key from ZeroBias for npm registry authentication.

---

## ZeroBias Task Integration

For creating suites from ZeroBias tasks, use the skill:

```
/create-suite [task-id]
```

See **[.claude/skills/create-suite.md](.claude/skills/create-suite.md)** for the complete workflow.

### Quick Reference

**Orchestration Documentation:**
- [Meta-repo: DEPENDENCY_CHAIN.md](../../docs/orchestration/DEPENDENCY_CHAIN.md) - Suites depend on vendors
- [Meta-repo: TASK_MANAGEMENT.md](../../docs/orchestration/TASK_MANAGEMENT.md) - Task API patterns
- [Meta-repo: API_REFERENCE.md](../../docs/orchestration/API_REFERENCE.md) - Quick API reference

**Dependency Chain:**
```
vendor → suite → framework/standard/benchmark → crosswalk
```

**CRITICAL:** Suites REQUIRE vendors. Always check/create vendor first.

### Key APIs

```javascript
// Check if vendor exists (REQUIRED before suite)
zerobias_execute("portal.Vendor.search", { searchVendorBody: { search: "vendor" }})

// Check if suite exists
zerobias_execute("portal.Suite.search", { searchSuiteBody: { search: "vendor suite" }})

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

### Critical: vendorId

After `npm install`, get the correct vendorId from the vendor package:
```bash
cat node_modules/@zerobias-org/vendor-{vendor}/index.yml | grep "^id:"
```

The `vendorId` in suite's `index.yml` MUST match this value.
