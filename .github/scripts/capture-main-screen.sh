#!/usr/bin/env bash
set -euo pipefail

: "${APP_ID:?APP_ID is required}"
: "${DEBUG_APK:?DEBUG_APK is required}"

mkdir -p artifacts

# A cached AVD may contain an APK signed by a previous runner's ephemeral debug key.
# Remove it first so Quick Boot remains reusable without signature conflicts.
adb uninstall "$APP_ID" >/dev/null 2>&1 || true
adb install "$DEBUG_APK"

# HomeScreen asks for location. Pre-grant it so an Android permission sheet never
# obscures the screenshot; failures are harmless on images/API levels without it.
adb shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION >/dev/null 2>&1 || true
adb shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION >/dev/null 2>&1 || true
adb shell am force-stop "$APP_ID" || true

# Launch through the app's launcher intent without hard-coding the activity class.
adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1

launched=false
for attempt in $(seq 1 45); do
  activity_state="$(adb shell dumpsys activity activities 2>/dev/null || true)"
  resumed="$(printf '%s\n' "$activity_state" | grep -m 1 -E 'topResumedActivity=|ResumedActivity:' || true)"

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

# Do not accept the Android/Flutter launch splash as a successful screenshot.
# Wait until accessibility exposes a stable marker from the actual HomeScreen.
home_ready=false
for attempt in $(seq 1 30); do
  adb shell uiautomator dump --compressed /sdcard/mazraa-window.xml >/dev/null 2>&1 || true
  adb exec-out cat /sdcard/mazraa-window.xml > artifacts/window.xml 2>/dev/null || true

  if grep -Eq "صباح الخير|Good morning|ملخص اليوم|Today's summary|وصول سريع|Quick access" artifacts/window.xml 2>/dev/null; then
    echo "HomeScreen marker detected on attempt $attempt."
    home_ready=true
    break
  fi

  echo "Waiting for the real HomeScreen ($attempt/30)..."
  sleep 1
done

if [[ "$home_ready" != true ]]; then
  echo "The app resumed, but the real HomeScreen never became visible. Refusing to capture a splash screen."
  adb exec-out screencap -p > artifacts/not-ready-screen.png || true
  adb shell dumpsys activity activities > artifacts/activity-dump.txt || true
  adb shell dumpsys window windows > artifacts/window-dump.txt || true
  adb logcat -d > artifacts/logcat.txt || true
  exit 1
fi

# Allow one short frame interval after semantics settle, then capture the actual UI.
sleep 1
adb exec-out screencap -p > artifacts/main-screen.png

test -s artifacts/main-screen.png
file artifacts/main-screen.png
adb shell dumpsys activity activities | head -n 300 > artifacts/activity-dump.txt || true
