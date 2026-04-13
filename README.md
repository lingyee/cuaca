# Cuaca

A Flutter weather app for Malaysia that shows forecasts and live rain radar.

**Features:**
- Search any place in Malaysia via Photon (typo-tolerant, covers roads, neighbourhoods & POIs)
- 7-day daily forecast with expandable cards
- 48-hour hourly forecast
- Live rain map powered by Tomorrow.io (satellite + model data)
- Auto-detects current location on startup via GPS

---

## Setup on Ubuntu

### 1. Install Flutter (via snap)

```bash
sudo snap install flutter --classic
flutter sdk-path   # verify installation
```

### 2. Install Android Studio

```bash
sudo snap install android-studio --classic
```

Open Android Studio and complete the setup wizard. Make sure to install:
- Android SDK
- Android SDK Platform-Tools
- An Android emulator (AVD)

### 3. Install Android SDK Command-line Tools

`flutter doctor --android-licenses` will fail if this component is missing. Install it first:

1. Open **Android Studio**
2. Go to **Settings** → **Languages & Frameworks** → **Android SDK**
3. Click the **SDK Tools** tab
4. Check **Android SDK Command-line Tools (latest)**
5. Click **Apply** → **OK**

### 4. Accept Android licenses

```bash
flutter doctor --android-licenses
```

Accept all prompts with `y`.

### 5. Verify your environment

```bash
flutter doctor
```

All items should show a checkmark. Fix any issues it reports before continuing.

### 6. Clone and get dependencies

```bash
git clone <repo-url>
cd cuaca
flutter pub get
```

### 7. Set up the Tomorrow.io API key

The rain map uses [Tomorrow.io](https://tomorrow.io) for live precipitation tiles. A free API key is required.

**Get your API key:**

1. Go to [app.tomorrow.io](https://app.tomorrow.io) and create a free account
2. After signing in, go to **Development → API Keys** in the left sidebar
3. Copy the default key (or create a new one)

**Create the config file:**

Create the file `lib/config.dart` in the project root with the following content:

```dart
// Get a free API key at https://app.tomorrow.io/development/keys
const String tomorrowIoApiKey = 'YOUR_API_KEY_HERE';
```

Replace `YOUR_API_KEY_HERE` with your actual key.

> This file is listed in `.gitignore` and will never be committed to version control.
> The app will not compile without it.

### 8. Grant location permissions (Android emulator)

The app requests GPS location on startup. On the emulator, location is enabled by default. On a physical device, allow the permission when prompted.

For internet access, ensure the following are in `android/app/src/main/AndroidManifest.xml` (already included):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

## Running the app

### List available devices

```bash
flutter devices
```

### Run on Android emulator

Start the emulator from Android Studio (Device Manager), then find its device ID:

```bash
flutter devices
```

Look for a line like:
```
sdk gphone16k x86 64 (mobile) • emulator-5554 • android-x64 • Android 17 (API 37) (emulator)
```

The value after `•` (e.g. `emulator-5554`) is your device ID. Use it to run:

```bash
flutter run -d emulator-5554   # replace with your actual device ID
```

> First run downloads Gradle (~200 MB) and compiles the app. This can take 5–15 minutes depending on your connection. Subsequent runs are much faster.

### Run on a physical Android phone

**1. Enable Developer Options on your phone**

- Go to **Settings → About phone**
- Tap **Build number** 7 times until "You are now a developer" appears
- Go back to **Settings → Developer options**
- Enable **USB debugging**

**2. Connect via USB**

Plug your phone into your PC. A prompt will appear on the phone asking to **"Allow USB debugging"** — tap **Allow**.

**3. Verify the device is detected**

```bash
flutter devices
```

Your phone should appear, e.g.:
```
Pixel 7 (mobile) • R5CT1BXXXXX • android-arm64 • Android 14
```

**4. Run the app**

```bash
flutter run -d R5CT1BXXXXX   # replace with your device ID
```

Or if it's the only connected device:

```bash
flutter run
```

> First run compiles the app and may take a few minutes. Subsequent runs are much faster.

**If your phone isn't detected:**

- Try a different USB cable (some are charge-only)
- On the phone, change the USB mode to **File Transfer / MTP** (not just charging)
- Install ADB if missing: `sudo apt install adb`
- Run `adb devices` — if it shows `unauthorized`, re-check the allow prompt on the phone

> When the app first launches, allow the location permission prompt to enable GPS auto-detect.

### Run on Linux desktop

```bash
flutter run -d linux
```

> Note: GPS/location features do not work on Linux desktop.

### Run in Chrome

```bash
flutter run -d chrome
```

---

## Hot reload during development

While `flutter run` is active, use these keyboard shortcuts in the terminal:

| Key | Action |
|-----|--------|
| `r` | Hot reload (apply code changes instantly) |
| `R` | Hot restart (full restart, resets state) |
| `q` | Quit |

---

## Troubleshooting

### Gradle download stalls or times out

Android Studio and the terminal both share `~/.gradle`. Running both at the same time causes file lock conflicts.

```bash
# Kill any stuck Gradle processes
pkill -f gradle; pkill -f GradleDaemon

# Delete the incomplete download
rm -rf ~/.gradle/wrapper/dists/gradle-8.14-all

# Re-run (close Android Studio first)
flutter run -d emulator-5554
```

### Manually download Gradle (faster than letting Gradle Wrapper do it)

```bash
curl -L -o ~/.gradle/wrapper/dists/gradle-8.14-all/c2qonpi39x1mddn7hk5gh9iqj/gradle-8.14-all.zip \
  https://services.gradle.org/distributions/gradle-8.14-all.zip
```

### flutter doctor shows issues

```bash
flutter doctor -v
```

Run with `-v` for verbose output to diagnose specific issues.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | State management |
| [flutter_map](https://pub.dev/packages/flutter_map) | Interactive map |
| [geolocator](https://pub.dev/packages/geolocator) | GPS location |
| [http](https://pub.dev/packages/http) | API requests |
| [intl](https://pub.dev/packages/intl) | Date formatting |
| [latlong2](https://pub.dev/packages/latlong2) | Lat/lng coordinates |

**APIs used:**

| API | Purpose | Key required |
|-----|---------|-------------|
| [Open-Meteo](https://open-meteo.com) | Weather forecast | No |
| [Photon](https://photon.komoot.io) | Place search & reverse geocoding | No |
| [Tomorrow.io](https://tomorrow.io) | Live rain map tiles (satellite + model) | Yes (free tier) |
| [OpenStreetMap](https://www.openstreetmap.org) | Base map tiles | No |
