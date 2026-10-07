#!/usr/bin/env bash
#
# Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.
#

# Validates the Ping Identity copyright header of source files changed in a PR / push.
#
# Environment:
#   BASE_SHA   Commit to diff against (PR base or push "before" SHA). Optional.
#   BASE_REPO  "owner/repo" to fetch BASE_SHA from if it is missing locally (fork PRs). Optional.
#   GITHUB_BASE_REF  Fallback base branch when BASE_SHA is not usable. Defaults to "main".
#
# Run from the root of the checked-out repository being validated.

set -euo pipefail

CURRENT_YEAR=$(date +%Y)
HEADER_LINES=20
ZERO_SHA="0000000000000000000000000000000000000000"

has_commit() {
  git cat-file -e "$1^{commit}" 2>/dev/null
}

if [[ -n "${BASE_SHA:-}" && "$BASE_SHA" != "$ZERO_SHA" ]]; then
  if ! has_commit "$BASE_SHA" && [[ -n "${BASE_REPO:-}" ]]; then
    git fetch --no-tags --quiet "https://github.com/${BASE_REPO}.git" "$BASE_SHA" || true
  fi
fi

if [[ -n "${BASE_SHA:-}" && "$BASE_SHA" != "$ZERO_SHA" ]] && has_commit "$BASE_SHA"; then
  BASE="$BASE_SHA"
  echo "Checking copyright headers for files changed since: $BASE"
else
  BASE_REF="${GITHUB_BASE_REF:-main}"
  echo "Checking copyright headers for files changed against: origin/$BASE_REF"
  git fetch --no-tags --quiet origin "$BASE_REF"
  BASE="origin/$BASE_REF"
fi

FAILED=0

while IFS= read -r -d '' file; do
  # Not owned by this repo's sample code: legacy samples, dependencies, generated or
  # framework-scaffolded files, and tool configuration.
  case "$file" in
    archived/*|*/node_modules/*) continue ;;
    *.g.dart|*.freezed.dart|*/GeneratedPluginRegistrant.*) continue ;;
    */ios/Runner/*|*/ios/RunnerTests/*|*/android/app/src/main/kotlin/*/MainActivity.kt) continue ;;
    */Package.swift|Package.swift) continue ;;
    *.config.js|*.config.ts|*/.eslintrc.js|.eslintrc.js) continue ;;
  esac

  case "$file" in
    *.kt|*.java|*.swift|*.dart|*.js|*.jsx) ;;
    *) continue ;;
  esac

  [[ -f "$file" ]] || continue

  echo "Checking: $file"

  COPYRIGHT_LINE=$(head -n "$HEADER_LINES" "$file" | grep -iE \
    'Copyright( \(c\))? [0-9]{4}([[:space:]]*-[[:space:]]*[0-9]{4})?[[:space:]]+Ping Identity( Corporation)?' \
    | head -1 || true)

  if [[ -z "$COPYRIGHT_LINE" ]]; then
    echo "::error file=$file::Missing or invalid Ping Identity copyright header"
    FAILED=1
    continue
  fi

  YEARS=$(echo "$COPYRIGHT_LINE" | grep -oE '[0-9]{4}([[:space:]]*-[[:space:]]*[0-9]{4})?' | head -1)
  START_YEAR=$(echo "$YEARS" | grep -oE '^[0-9]{4}')
  END_YEAR=$(echo "$YEARS" | grep -oE '[0-9]{4}$')

  if [[ "$END_YEAR" -lt "$CURRENT_YEAR" ]]; then
    echo "::error file=$file::Copyright year is stale. Expected: $START_YEAR - $CURRENT_YEAR"
    FAILED=1
  fi
done < <(git diff -z --name-only --diff-filter=ACMR "$BASE"...HEAD)

if [[ "$FAILED" -ne 0 ]]; then
  echo
  echo "Copyright validation failed."
  exit 1
fi

echo "Copyright validation passed."
