#!/usr/bin/env bash
#
# RideMate — engineering quality gates.
#
# Single reproducible entry point for local development and, later, CI.
# Every gate is fatal; the script stops at the first failure.
#
#   ./tool/check.sh
#
# Note: docs/claude-designs/ is an immutable design reference and is never
# formatted or rewritten by this script.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> dart format (check only)"
dart format --set-exit-if-changed .

echo "==> flutter analyze"
flutter analyze --fatal-infos --fatal-warnings

echo "==> flutter test"
# Goldens are host-dependent and run separately; see tool/goldens.sh.
flutter test --exclude-tags golden

echo
echo "All checks passed."
