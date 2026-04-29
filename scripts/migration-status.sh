#!/usr/bin/env bash
#
# Regenerate MIGRATION_STATUS.md — a snapshot of which suite packages
# have been migrated to the gradle (zb.content) pipeline and which are
# still on the lerna-era 1.x line.
#
# A suite is considered migrated when its directory contains a
# build.gradle.kts marker tracked on origin/main. Pre-flight URL/code
# checks mirror what the gate's contentValidator enforces; suites with
# obvious schema problems are flagged so they can be triaged before
# they reach the matrix publish job.
#
# Usage:
#   ./scripts/migration-status.sh             # writes MIGRATION_STATUS.md
#   ./scripts/migration-status.sh --check     # exit non-zero if file out of date
#
# Run from the repo root.

set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="MIGRATION_STATUS.md"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Suites with a build.gradle.kts marker in the working tree.
# Mirrors what the publish workflow's detect job sees — present on disk
# means present in the matrix.
mapfile -t MIGRATED < <(find package -mindepth 3 -maxdepth 3 -name "build.gradle.kts" \
  | sed 's|^package/||; s|/build\.gradle\.kts$||' \
  | sort)

# All suite leaf directories
mapfile -t ALL < <(find package -mindepth 2 -maxdepth 2 -type d \
  | sed 's|^package/||' | sort)

total=${#ALL[@]}
migrated=${#MIGRATED[@]}
pending=$((total - migrated))
pct=$(awk -v m="$migrated" -v t="$total" 'BEGIN{printf "%.1f", (m/t)*100}')

CODE_REGEX='^[a-z0-9_]+$'

is_migrated() {
  local s="$1"
  printf '%s\n' "${MIGRATED[@]}" | grep -qx "$s"
}

flag_for() {
  local s="$1"
  local indexyml="package/$s/index.yml"
  local pkgjson="package/$s/package.json"
  local flags=""

  [ -f "$indexyml" ] || flags="$flags missing-index.yml"
  [ -f "$pkgjson" ]  || flags="$flags missing-package.json"

  if [ -f "$indexyml" ]; then
    local code vendor_code url
    code=$(awk -F': ' '/^code:/{print $2; exit}' "$indexyml" | tr -d '"' | tr -d "'" | xargs)
    vendor_code=$(awk -F': ' '/^vendorCode:/{print $2; exit}' "$indexyml" | tr -d '"' | tr -d "'" | xargs)
    url=$(awk -F': ' '/^url:/{$1=""; sub(/^[ \t:]+/,""); print; exit}' "$indexyml" | tr -d '"' | tr -d "'" | xargs)
    if [ -n "$code" ] && ! [[ "$code" =~ $CODE_REGEX ]]; then
      flags="$flags bad-code"
    fi
    if [ -n "$vendor_code" ] && ! [[ "$vendor_code" =~ $CODE_REGEX ]]; then
      flags="$flags bad-vendorCode"
    fi
    if [ -n "$url" ] && ! [[ "$url" =~ ^https?:// ]]; then
      flags="$flags bad-url"
    fi
  fi

  echo "$flags" | xargs
}

{
  echo "# Migration Status — \`zerobias-org/suite\`"
  echo
  echo "Tracker for the gradle (zb.content) migration of suite packages."
  echo "Regenerate with \`./scripts/migration-status.sh\`."
  echo
  echo "**Last updated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)  "
  echo "**Migrated:** $migrated / $total ($pct%)  "
  echo "**Pending:** $pending"
  echo
  echo "## Legend"
  echo
  echo "- ✅ migrated — has \`build.gradle.kts\` on \`origin/main\`"
  echo "- ⬜ pending — still on the lerna-era flow"
  echo "- ⚠ flagged — pre-flight schema issue surfaced (will fail gate as-is). See the Flagged section."
  echo
  echo "## Flagged (fix before migrating)"
  echo
  echo "These suites will fail \`./gradlew :<vendor>:<suite>:gate\` as-is — fix the index.yml / package.json drift before adding the gradle marker."
  echo
  echo "| suite | current version | flags |"
  echo "|---|---|---|"
  flagged_count=0
  for s in "${ALL[@]}"; do
    if is_migrated "$s"; then continue; fi
    flags=$(flag_for "$s")
    if [ -n "$flags" ]; then
      ver=$(jq -r '.version // "?"' "package/$s/package.json" 2>/dev/null || echo "?")
      printf '| %s | %s | %s |\n' "$s" "$ver" "$flags"
      flagged_count=$((flagged_count + 1))
    fi
  done
  if [ "$flagged_count" -eq 0 ]; then
    echo "| _(none)_ | | |"
  fi
  echo
  echo "_$flagged_count flagged_"
  echo
  echo "## All suites"
  echo
  echo "| suite | status | current version |"
  echo "|---|---|---|"
  for s in "${ALL[@]}"; do
    ver=$(jq -r '.version // "?"' "package/$s/package.json" 2>/dev/null || echo "?")
    if is_migrated "$s"; then
      status="✅ migrated"
    else
      flags=$(flag_for "$s")
      if [ -n "$flags" ]; then
        status="⚠ flagged ($flags)"
      else
        status="⬜ pending"
      fi
    fi
    printf '| %s | %s | %s |\n' "$s" "$status" "$ver"
  done
} > "$TMP"

if [ "${1:-}" = "--check" ]; then
  if ! diff -q "$OUT" "$TMP" >/dev/null 2>&1; then
    echo "MIGRATION_STATUS.md is out of date — run scripts/migration-status.sh and commit." >&2
    exit 1
  fi
  echo "MIGRATION_STATUS.md is current."
  exit 0
fi

mv "$TMP" "$OUT"
trap - EXIT
echo "Wrote $OUT"
echo "  migrated: $migrated / $total ($pct%)"
