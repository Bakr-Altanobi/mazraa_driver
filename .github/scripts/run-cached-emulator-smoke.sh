#!/usr/bin/env bash
set -euo pipefail

: "${ANDROID_HOME:?ANDROID_HOME is required}"

AVD_NAME="test"
SERIAL="emulator-5554"
IMAGE_PACKAGE="system-images;android-35;default;x86_64"
IMAGE_DIR="$ANDROID_HOME/system-images/android-35/default/x86_64"
EMULATOR_BIN="$ANDROID_HOME/emulator/emulator"
ADB_BIN="$ANDROID_HOME/platform-tools/adb"
AVDMANAGER_BIN="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
SDKMANAGER_BIN="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

export ANDROID_AVD_HOME="$HOME/.android/avd"
mkdir -p artifacts "$ANDROID_AVD_HOME"

missing_packages=()
[[ -x "$EMULATOR_BIN" ]] || missing_packages+=(emulator)
[[ -x "$ADB_BIN" ]] || missing_packages+=(platform-tools)
[[ -d "$IMAGE_DIR" ]] || missing_packages+=("$IMAGE_PACKAGE")

# Warm runs skip sdkmanager completely. Installation happens only when a cache
# or runner tool is genuinely absent.
if (( ${#missing_packages[@]} > 0 )); then
  echo "Android cache miss; installing only: ${missing_packages[*]}"
  yes | "$SDKMANAGER_BIN" --licenses >/dev/null || true
  "$SDKMANAGER_BIN" --install "${missing_packages[@]}"
else
  echo "Android emulator, platform-tools and API 35 image are ready; skipping sdkmanager entirely."
fi

export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

avd_registered() {
  "$EMULATOR_BIN" -list-avds 2>/dev/null | tr -d '\r' | grep -Fxq "$AVD_NAME"
}

# A cache restore can be interrupted after unpacking part of ~/.android/avd.
# Never reuse a half-restored definition: remove it and create one cleanly in a
# deterministic ANDROID_AVD_HOME.
if ! avd_registered; then
  echo "Cached AVD '$AVD_NAME' is absent or incomplete; recreating it."
  rm -rf "$ANDROID_AVD_HOME/$AVD_NAME.avd" "$ANDROID_AVD_HOME/$AVD_NAME.ini"

  echo no | "$AVDMANAGER_BIN" create avd \
    --force \
    --name "$AVD_NAME" \
    --package "$IMAGE_PACKAGE" \
    --device "pixel_6"

  # Some avdmanager versions create the .avd directory but omit/lose the .ini
  # registry file when a previous cache extraction was partial. Repair that
  # tiny registry deterministically rather than downloading the image again.
  if [[ -d "$ANDROID_AVD_HOME/$AVD_NAME.avd" && ! -f "$ANDROID_AVD_HOME/$AVD_NAME.ini" ]]; then
    cat > "$ANDROID_AVD_HOME/$AVD_NAME.ini" <<EOF
avd.ini.encoding=UTF-8
path=$ANDROID_AVD_HOME/$AVD_NAME.avd
path.rel=avd/$AVD_NAME.avd
target=android-35
EOF
  fi

  if ! avd_registered; then
    echo "AVD '$AVD_NAME' is still not registered after recreation."
    echo "ANDROID_AVD_HOME=$ANDROID_AVD_HOME"
    find "$HOME/.android" -maxdepth 3 -type f -o -type d | sort | head -n 250 || true
    [[ -f "$ANDROID_AVD_HOME/$AVD_NAME.ini" ]] && cat "$ANDROID_AVD_HOME/$AVD_NAME.ini" || true
    exit 1
  fi
else
  echo "Cached AVD '$AVD_NAME' is already registered."
fi

"$ADB_BIN" kill-server >/dev/null 2>&1 || true
"$ADB_BIN" start-server >/dev/null

"$EMULATOR_BIN" \
  -port 5554 \
  -avd "$AVD_NAME" \
  -no-window \
  -gpu swiftshader_indirect \
  -noaudio \
  -no-boot-anim \
  -camera-back none \
  > artifacts/emulator.log 2>&1 &
EMU_PID=$!

cleanup() {
  "$ADB_BIN" -s "$SERIAL" emu kill >/dev/null 2>&1 || kill "$EMU_PID" >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do
    if ! kill -0 "$EMU_PID" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  kill "$EMU_PID" >/dev/null 2>&1 || true
  wait "$EMU_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

booted=false
for attempt in $(seq 1 120); do
  state="$("$ADB_BIN" -s "$SERIAL" get-state 2>/dev/null || true)"
  if [[ "$state" == "device" ]]; then
    boot="$("$ADB_BIN" -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [[ "$boot" == "1" ]]; then
      booted=true
      echo "Emulator booted on attempt $attempt."
      break
    fi
  fi

  if ! kill -0 "$EMU_PID" >/dev/null 2>&1; then
    echo "Emulator exited before boot completed."
    tail -n 300 artifacts/emulator.log || true
    exit 1
  fi

  sleep 2
done

if [[ "$booted" != true ]]; then
  echo "Android emulator failed to boot."
  tail -n 300 artifacts/emulator.log || true
  exit 1
fi

"$ADB_BIN" -s "$SERIAL" shell input keyevent 82 >/dev/null 2>&1 || true
"$ADB_BIN" -s "$SERIAL" shell settings put global window_animation_scale 0.0
"$ADB_BIN" -s "$SERIAL" shell settings put global transition_animation_scale 0.0
"$ADB_BIN" -s "$SERIAL" shell settings put global animator_duration_scale 0.0

bash .github/scripts/capture-main-screen.sh
