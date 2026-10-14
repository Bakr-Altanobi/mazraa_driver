#!/usr/bin/env bash
set -euo pipefail

: "${APP_ID:?APP_ID is required}"
: "${DEBUG_APK:?DEBUG_APK is required}"

mkdir -p artifacts
rm -f artifacts/window.xml artifacts/window.xml.tmp artifacts/main-screen.png artifacts/not-ready-screen.png
# Quick-boot AVD snapshots preserve /sdcard across jobs. A stale UIAutomator XML
# from a previous successful HomeScreen run must never be allowed to satisfy the
# readiness markers for the app that is launching now.
adb shell rm -f /sdcard/mazraa-window.xml >/dev/null 2>&1 || true

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

fresh_window_dump() {
  rm -f artifacts/window.xml.tmp
  # Remove the remote file before *every* attempt. If uiautomator cannot inspect
  # the current window (for example while Android/Flutter splash is still on
  # screen), `cat` must not fall back to an XML left by an earlier emulator job.
  adb shell rm -f /sdcard/mazraa-window.xml >/dev/null 2>&1 || true
  if ! adb shell uiautomator dump --compressed /sdcard/mazraa-window.xml >/dev/null 2>&1; then
    return 1
  fi
  if ! adb exec-out cat /sdcard/mazraa-window.xml > artifacts/window.xml.tmp 2>/dev/null; then
    return 1
  fi
  if [[ ! -s artifacts/window.xml.tmp ]] || ! grep -Fq '<hierarchy' artifacts/window.xml.tmp; then
    return 1
  fi
  mv artifacts/window.xml.tmp artifacts/window.xml
  return 0
}

window_has_complete_home() {
  [[ -s artifacts/window.xml ]] || return 1
  grep -Eq "أنت متصل|You are online" artifacts/window.xml 2>/dev/null \
    && grep -Fq "SHP-9101" artifacts/window.xml 2>/dev/null \
    && grep -Fq "YER" artifacts/window.xml 2>/dev/null
}

# CI_SMOKE_HOME renders deterministic, fully-loaded HomeScreen data. Do not
# accept the Android/Flutter splash or a HomeScreen whose providers are still
# loading. Require two consecutive *fresh* accessibility snapshots so a cached
# AVD, transient window or one-frame race cannot produce a false positive.
home_ready=false
ready_streak=0
for attempt in $(seq 1 45); do
  profile_ready=false
  shipment_ready=false
  wallet_ready=false

  if fresh_window_dump; then
    if grep -Eq "أنت متصل|You are online" artifacts/window.xml 2>/dev/null; then
      profile_ready=true
    fi
    if grep -Fq "SHP-9101" artifacts/window.xml 2>/dev/null; then
      shipment_ready=true
    fi
    if grep -Fq "YER" artifacts/window.xml 2>/dev/null; then
      wallet_ready=true
    fi
  fi

  echo "Home data check $attempt: profile=$profile_ready shipments=$shipment_ready wallet=$wallet_ready"
  if [[ "$profile_ready" == true && "$shipment_ready" == true && "$wallet_ready" == true ]]; then
    ready_streak=$((ready_streak + 1))
    if (( ready_streak >= 2 )); then
      echo "Fully loaded HomeScreen detected in two consecutive fresh dumps."
      home_ready=true
      break
    fi
  else
    ready_streak=0
  fi

  sleep 1
done

if [[ "$home_ready" != true ]]; then
  echo "The app resumed, but profile/shipments/wallet did not all render in fresh UI snapshots. Refusing to capture an incomplete HomeScreen."
  adb exec-out screencap -p > artifacts/not-ready-screen.png || true
  adb shell dumpsys activity activities > artifacts/activity-dump.txt || true
  adb shell dumpsys window windows > artifacts/window-dump.txt || true
  adb logcat -d > artifacts/logcat.txt || true
  exit 1
fi

# Give Android one final frame, then prove the currently inspectable window still
# contains the complete HomeScreen immediately before the screenshot is taken.
sleep 1
if ! fresh_window_dump || ! window_has_complete_home; then
  echo "HomeScreen markers disappeared before screenshot capture; refusing a splash/loading screenshot."
  adb exec-out screencap -p > artifacts/not-ready-screen.png || true
  adb logcat -d > artifacts/logcat.txt || true
  exit 1
fi

adb exec-out screencap -p > artifacts/main-screen.png

test -s artifacts/main-screen.png
file artifacts/main-screen.png
adb shell dumpsys activity activities | head -n 300 > artifacts/activity-dump.txt || true
