# Cuaca

A Flutter weather app for Malaysia that shows forecasts and live rain radar.

**Features:**
- Search any place in Malaysia via OpenStreetMap Nominatim
- 7-day daily forecast with expandable cards
- 48-hour hourly forecast
- Live rain radar map powered by RainViewer
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

### 3. Accept Android licenses

```bash
flutter doctor --android-licenses
```

Accept all prompts with `y`.

### 4. Verify your environment

```bash
flutter doctor
```

All items should show a checkmark. Fix any issues it reports before continuing.

### 5. Clone and get dependencies

```bash
git clone <repo-url>
cd cuaca
flutter pub get
```

### 6. Grant location permissions (Android emulator)

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

Start the emulator from Android Studio (Device Manager), then:

```bash
flutter run -d emulator-5554
```

> First run downloads Gradle (~200 MB) and compiles the app. This can take 5–15 minutes depending on your connection. Subsequent runs are much faster.

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

**APIs used (all free, no key required):**
- [Open-Meteo](https://open-meteo.com) — weather forecast
- [Nominatim](https://nominatim.openstreetmap.org) — place search & reverse geocoding
- [RainViewer](https://www.rainviewer.com/api.html) — radar tiles
- [OpenStreetMap](https://www.openstreetmap.org) — base map tiles
