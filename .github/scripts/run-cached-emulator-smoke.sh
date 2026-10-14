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
AVD_DIR="$HOME/.android/avd/$AVD_NAME.avd"

mkdir -p artifacts "$HOME/.android/avd"

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

if [[ ! -d "$AVD_DIR" ]]; then
  echo "Creating cached AVD '$AVD_NAME'."
  echo no | "$AVDMANAGER_BIN" create avd \
    --force \
    --name "$AVD_NAME" \
    --package "$IMAGE_PACKAGE" \
    --device "pixel_6"
  printf '\nhw.cpu.ncore=2\n' >> "$AVD_DIR/config.ini"
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
