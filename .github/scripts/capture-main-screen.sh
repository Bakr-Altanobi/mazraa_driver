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
for attempt in $(seq 1 45); do
  activity_state="$(adb shell dumpsys activity activities 2>/dev/null || true)"
  resumed="$(printf '%s\n' "$activity_state" | grep -m 1 -E 'topResumedActivity=|ResumedActivity:' || true)"

  # Android releases expose the resumed activity with slightly different labels.
  # Fall back to the focused window so the smoke test remains stable across API levels.
  if [[ -z "$resumed" ]]; then
    resumed="$(adb shell dumpsys window windows 2>/dev/null | grep -m 1 -E 'mCurrentFocus=|mFocusedApp=' || true)"
  fi

  echo "Foreground check $attempt: $resumed"
  if [[ "$resumed" == *"$APP_ID"* ]]; then
    launched=true
    break
  fi

  sleep 1
done

if [[ "$launched" != true ]]; then
  echo "The Mazraa Driver app did not become the resumed foreground application."
  adb shell dumpsys activity activities > artifacts/activity-dump.txt || true
  adb shell dumpsys window windows > artifacts/window-dump.txt || true
  adb logcat -d > artifacts/logcat.txt || true
  exit 1
fi

# The activity is resumed; allow a short interval for Flutter's first stable frame.
sleep 2
adb exec-out screencap -p > artifacts/main-screen.png

test -s artifacts/main-screen.png
file artifacts/main-screen.png

# Keep lightweight state evidence alongside the successful run.
adb shell dumpsys activity activities | head -n 300 > artifacts/activity-dump.txt || true
