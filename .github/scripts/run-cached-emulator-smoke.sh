#!/usr/bin/env bash
set -euo pipefail

: "${ANDROID_HOME:?ANDROID_HOME is required}"

AVD_NAME="test"
SERIAL="emulator-5554"
IMAGE_PACKAGE="system-images;android-35;default;x86_64"
IMAGE_DIR="$ANDROID_HOME/system-images/android-35/default/x86_64"
EMULATOR_BIN="$ANDROID_HOME/emulator/emulator"
AVD_DIR="$HOME/.android/avd/$AVD_NAME.avd"

mkdir -p artifacts "$HOME/.android/avd"

# Install the emulator image only on a genuine cache miss. Warm runs skip
# sdkmanager entirely, avoiding repeated dependency installation/checks.
if [[ ! -x "$EMULATOR_BIN" || ! -d "$IMAGE_DIR" ]]; then
  echo "Android emulator cache miss; installing the image once."
  yes | sdkmanager --licenses >/dev/null || true
  sdkmanager --install emulator platform-tools "$IMAGE_PACKAGE"
else
  echo "Android emulator + API 35 image restored from cache; skipping sdkmanager install."
fi

if [[ ! -d "$AVD_DIR" ]]; then
  echo "Creating cached AVD '$AVD_NAME'."
  echo no | avdmanager create avd \
    --force \
    --name "$AVD_NAME" \
    --package "$IMAGE_PACKAGE" \
    --device "pixel_6"
  printf '\nhw.cpu.ncore=2\n' >> "$AVD_DIR/config.ini"
fi

adb kill-server >/dev/null 2>&1 || true
adb start-server >/dev/null

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
  adb -s "$SERIAL" emu kill >/dev/null 2>&1 || kill "$EMU_PID" >/dev/null 2>&1 || true
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
  state="$(adb -s "$SERIAL" get-state 2>/dev/null || true)"
  if [[ "$state" == "device" ]]; then
    boot="$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
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

adb -s "$SERIAL" shell input keyevent 82 >/dev/null 2>&1 || true
adb -s "$SERIAL" shell settings put global window_animation_scale 0.0
adb -s "$SERIAL" shell settings put global transition_animation_scale 0.0
adb -s "$SERIAL" shell settings put global animator_duration_scale 0.0

# The smoke script intentionally uses the default adb target; with one emulator
# on the runner it resolves to this cached device.
bash .github/scripts/capture-main-screen.sh
