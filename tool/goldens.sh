#!/usr/bin/env bash
#
# RideMate — golden tests.
#
# Kept out of tool/check.sh on purpose: golden images depend on font
# rasterization, which differs between operating systems. The committed
# baselines were generated on Linux, so running these on macOS or on non-Linux
# CI will show diffs that are not real regressions.
#
#   ./tool/goldens.sh           verify against the committed baselines
#   ./tool/goldens.sh --update  regenerate them (review the diff before committing)

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "${1:-}" == "--update" ]]; then
  echo "==> regenerating golden baselines"
  flutter test --tags golden --update-goldens
  echo
  echo "Baselines updated. Inspect the image diff before committing:"
  echo "  git diff --stat -- test/golden/goldens"
else
  echo "==> verifying goldens"
  flutter test --tags golden
fi
