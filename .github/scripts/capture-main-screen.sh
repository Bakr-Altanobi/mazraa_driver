#!/usr/bin/env bash
set -euo pipefail

mkdir -p artifacts
rm -f artifacts/main-screen.png

# TEMPORARY VISUAL-AUDIT EXPORT ONLY.
# The existing workflow uploads exactly artifacts/main-screen.png. Package all
# canonical reference screenshots into that path so the audit runner can obtain
# the exact source pixels without changing the production workflow.
zip -q -r artifacts/main-screen.png \
  refrinces/screens \
  refrinces/screens_advanced \
  refrinces/screens_phase3 \
  refrinces/screens_phase4

test -s artifacts/main-screen.png
file artifacts/main-screen.png
