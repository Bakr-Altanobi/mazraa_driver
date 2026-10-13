#!/usr/bin/env bash
set -euo pipefail

: "${APP_ID:?APP_ID is required}"
: "${DEBUG_APK:?DEBUG_APK is required}"

mkdir -p artifacts

adb install -r "$DEBUG_APK"
adb shell pm clear "$APP_ID" || true
adb shell am force-stop "$APP_ID" || true

# Launch through the app's launcher intent without hard-coding the activity class.
adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1

launched=false
for attempt in $(seq 1 30); do
  resumed="$(adb shell dumpsys activity activities | grep -m 1 mResumedActivity || true)"
  echo "Foreground check $attempt: $resumed"

  if [[ "$resumed" == *"$APP_ID"* ]]; then
    launched=true
    break
  fi

  sleep 2
done

if [[ "$launched" != true ]]; then
  echo "The Mazraa Driver app did not become the resumed foreground application."
  adb shell dumpsys activity activities > artifacts/activity-dump.txt || true
  adb logcat -d > artifacts/logcat.txt || true
  exit 1
fi

# Let Flutter finish painting its first stable frame before the screenshot.
sleep 3
adb exec-out screencap -p > artifacts/main-screen.png

test -s artifacts/main-screen.png
file artifacts/main-screen.png

# Keep lightweight diagnostics available if a later step needs them.
adb shell dumpsys activity activities | head -n 300 > artifacts/activity-dump.txt || true
