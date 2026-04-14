# Cuaca

A Flutter weather app for Malaysia that shows forecasts and a live rain radar.

**Features:**
- Search any place in Malaysia via Photon (typo-tolerant, covers roads, neighbourhoods & POIs)
- Auto-detects current location on startup via GPS; tap **Your Location** in the search dropdown to re-centre on GPS without restarting
- **Forecast tab** with a Daily / Hourly toggle:
  - *Daily* — 7-day forecast cards; tap to expand and see Morning / Afternoon / Night breakdowns with weather condition and temperature for each period
  - *Hourly* — next 12 hours starting from the current hour ("Now"); each card shows weather condition, temperature, rain probability, and wind speed
- **Rain Map tab** — live precipitation overlay powered by Tomorrow.io; defaults to a full-Malaysia view (zoom 4) when no place is pinned, zooms to the selected place when one is set; auto-refreshes every 10 minutes; colour-coded Rain Intensity legend (Light → Moderate → Heavy → Intense)

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

## Building a release APK

To distribute the app to other Android devices without going through the Play Store.

### 1. Generate a signing keystore (one-time)

```bash
keytool -genkey -v -keystore ~/cuaca-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cuaca
```

Keep the `.jks` file and the passwords safe — you need them for every future release build.

### 2. Create `android/key.properties`

This file is gitignored and must never be committed.

```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=cuaca
storeFile=/path/to/cuaca-release.jks
```

### 3. Build

```bash
flutter build apk --release
```

The signed APK will be at:

```
build/app/outputs/apk/release/cuaca-<version>.apk
```

The version matches the `version` field in `pubspec.yaml` (e.g. `cuaca-1.0.0.apk`).

> Note: Flutter also places a copy at `build/app/outputs/flutter-apk/app-release.apk` — use the path above for the correctly named file.

Transfer it to any Android device. Recipients need **Install unknown apps** enabled (Settings → Apps → Special app access → Install unknown apps).

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

## Disclaimer

This app is an independent open-source project and is **not affiliated with,
endorsed by, or sponsored by** any of the data providers it uses:

- Weather data: [Open-Meteo](https://open-meteo.com)
- Rain map tiles: [Tomorrow.io](https://tomorrow.io)
- Place search: [Photon / Komoot](https://photon.komoot.io)
- Base map tiles: [OpenStreetMap](https://www.openstreetmap.org) contributors

Weather and rain data are provided for informational purposes only and may not
be accurate or up to date. Do not rely on this app for safety-critical
decisions.

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

**Dev dependencies:**

| Package | Purpose |
|---------|---------|
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | Generate Android launcher icons from source image |

**APIs used:**

| API | Purpose | Key required |
|-----|---------|-------------|
| [Open-Meteo](https://open-meteo.com) | Weather forecast (daily + hourly) | No |
| [Photon](https://photon.komoot.io) | Place search & reverse geocoding | No |
| [Tomorrow.io](https://tomorrow.io) | Live rain map tiles (satellite + model) | Yes (free tier) |
| [OpenStreetMap](https://www.openstreetmap.org) | Base map tiles | No |
