# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Lerna monorepo containing compliance and security framework suites. Each suite represents a specific regulatory framework, standard, or compliance requirement (like ISO 27001, NIST 800-53, SOC2, etc.) organized by vendor/organization and specific standard code.

## Common Development Commands

### Setup and Installation
- `npm install` - Setup husky hooks and install root dependencies
- `npm run bootstrap` - Bootstrap all packages using Lerna
- `npm run build` - Generate npm-shrinkwrap.json for all packages
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
5. Generate shrinkwrap: `npm shrinkwrap`
6. Validate: `npm run validate` from repository root

### Required Files for Each Suite
- `package.json` - NPM package configuration
- `index.yml` - Suite metadata and configuration
- `logo.svg` or logo file - Visual identifier
- `npm-shrinkwrap.json` - Dependency lock file
- `.npmrc` - NPM registry configuration

## Suite Structure and Requirements

### package.json Requirements
- Name format: `@zerobias-org/suite-{vendor}-{code}`
- Must include `auditmation` section with:
  - `package: "{vendor}.{code}"`
  - `import-artifact: "suite"`
  - `dataloader-version` field
- Dependencies must include exactly one vendor package: `@zerobias-org/vendor-{vendor}`
- Standard scripts: `nx:publish`, `prepublishtest`, `correct:deps`, `validate`

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
- Always run `npm install && npm shrinkwrap` after creating or modifying a suite
- The vendor dependency will force installation of the vendor package together with the suite package
- **After installing vendor dependency**: Always check `node_modules/@zerobias-org/vendor-{vendor}/index.yml#id` to get the correct `vendorId` for the suite's index.yml

## Validation and Testing

### Validation Script
The `scripts/validate.ts` script checks:
- Proper package.json structure and naming
- Required auditmation configuration
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
- npm-shrinkwrap.json will lock to specific versions automatically
- Exactly one dependency: `@zerobias-org/vendor-{vendor}`
- Dependencies resolve from custom registry: `https://pkg.zerobias.org/`

### Standard Configuration Values
- `dataloader-version: "5.0.14"` (current standard across all suites)
- Repository directory: `"suite/"` in package.json
- Scripts always reference: `../../../scripts/`
- Logo URL pattern: `https://cdn.auditmation.io/logos/{vendor}-{code}.svg`

### File Structure Requirements
Every suite must include:
- `package.json` - NPM configuration
- `index.yml` - Suite metadata
- `logo.svg` - Logo file (never modify SVG content)
- `npm-shrinkwrap.json` - Generated dependency lock
- `CHANGELOG.md` - Auto-generated version history
- `.npmrc` - Registry configuration

### Logo Best Practices
- **Use official logos**: Always try to find and use official vendor SVG logos
- **Download approach**: Use curl to download official logos directly:
  ```bash
  curl -o /path/to/suite/logo.svg "https://official-logo-url.svg"
  ```
- **Verify download**: Check file size with `ls -lh` to ensure complete download
- **Never modify**: Don't edit SVG content - preserve official branding exactly as provided
- **Logo naming**: Follow pattern `https://cdn.auditmation.io/logos/{vendor}-{code}.svg` in index.yml

### Validation Notes
- Templates contain placeholders like `{vendor}`, `{code}` - these must be replaced
- UUIDs must be unique per suite, lowercase UUID v4 format (generated automatically by creation script)
- All metadata fields in index.yml must have real values, not template placeholders
- **Timestamps**: Always use real current time for `created` and `updated` fields, never use placeholder times like `00:00:00.000Z`

## Authentication

Set `ZB_TOKEN` environment variable with API key from ZeroBias for npm registry authentication.
