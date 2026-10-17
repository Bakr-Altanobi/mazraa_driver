#!/usr/bin/env bash
set -euo pipefail

mkdir -p artifacts
rm -f artifacts/main-screen.png
zip -q -r artifacts/main-screen.png \
  refrinces/screens \
  refrinces/screens_advanced \
  refrinces/screens_phase3 \
  refrinces/screens_phase4
test -s artifacts/main-screen.png
file artifacts/main-screen.png
