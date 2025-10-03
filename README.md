# POC - Spasticity Assessment Application

Proof of Concept (POC) of a mobile application using a lightweight AI model to validate the feasibility of the spasticity assessment application.

## 📱 About the Project

This Flutter application serves as a POC to demonstrate the feasibility of a mobile spasticity assessment application using lightweight artificial intelligence models. The goal is to validate technical concepts before developing the complete application.

## 🏗️ Project Architecture

The project follows a clean architecture with clear separation of responsibilities:

```
lib/
│
├── main.dart
├── app.dart
├── router/
│   └── app_router.dart
│
├── core/
│   ├── errors/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── feature/
│   │   ├── data/
│   │   ├── logic/
│   │   └── presentation/
│   │       ├── pages/
│   │       └── widgets/
```

### Environment Verification

```bash
flutter doctor
```

This command checks that all necessary tools are properly installed.

## 🚀 Installation and Launch

### 1. Clone the Repository

```bash
git clone https://github.com/Spasticity-Assessment-Application/POC.git
cd POC
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Check Available Devices

```bash
flutter devices
```

### 4. Run the Application

#### On an emulator/simulator:

```bash
flutter run
```

#### On a specific device:

```bash
flutter run -d <device-id>
```

#### On a physical device:

**For iOS (iPhone/iPad):**

1. **Configure code signing in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
2. **In Xcode:**
   - Select "Runner" in the project navigator
   - Go to "Signing & Capabilities" tab
   - Select your development team
   - Change the Bundle Identifier to something unique (e.g., `com.yourname.poc`)
3. **Connect your iOS device via USB or wirelessly**

4. **Run on your device:**

   ```bash
   # List connected devices to find your device ID
   flutter devices

   # Run on specific iOS device
   flutter run -d "Your iPhone Name"
   ```

**For Android:**

1. **Enable Developer Options on your Android device:**

   - Go to Settings > About phone
   - Tap "Build number" 7 times
   - Go back to Settings > Developer options
   - Enable "USB debugging"

2. **Connect your Android device via USB**

3. **Run on your device:**

   ```bash
   # List connected devices
   flutter devices

   # Run on Android device
   flutter run -d <android-device-id>
   ```

#### In debug mode with hot reload:

```bash
flutter run --debug
```

#### In release mode:

```bash
flutter run --release
```

## 📸 Camera Feature

The camera functionality requires a **physical device** to work properly.

### ⚠️ Important Notes:

- **Simulators/Emulators**: Camera features will show a mock interface for development purposes
- **Physical devices**: Full camera functionality with real photo capture
- **Permissions**: The app will request camera permissions on first use

### Testing Camera on Physical Device:

1. Follow the physical device setup instructions above
2. Navigate to the camera page in the app
3. Grant camera permissions when prompted
4. The camera should initialize and allow photo capture

## 🏃‍♂️ Useful Scripts

### Development

```bash
# Run in debug mode with hot reload
flutter run

# Analyze code
flutter analyze

# Format code
dart format .

# Run tests
flutter test
```

### Build

```bash
# Build for Android
flutter build apk
flutter build appbundle  # For Play Store

# Build for iOS
flutter build ios

# Build for Web
flutter build web

# Build for Desktop (macOS)
flutter build macos
```

## 🛠️ Troubleshooting

### Common Issues

#### iOS Code Signing Error

```
Error: Signing for "Runner" requires a development team
```

**Solution:** Configure your development team in Xcode (see iOS setup instructions above)

#### Camera Permission Denied

**Symptoms:** Camera shows "Permission denied" error
**Solutions:**

1. Ensure you're testing on a physical device (not simulator)
2. Grant camera permission when prompted
3. Check device settings: Settings > Privacy > Camera > Your App

#### Device Not Detected

**Solution:**

```bash
# Check connected devices
flutter devices

# Restart ADB (Android)
flutter doctor

# For iOS, ensure device is trusted in Xcode
```

#### App Not Appearing in Device Settings

**Note:** The app will only appear in iOS camera settings **after** requesting camera permission for the first time.

#### Local Network Permission Popup (iOS)

**Symptoms:** App asks for "local network access" permission
**Explanation:** This is normal in debug mode - Flutter uses local network for hot reload
**Solution:** This permission won't be requested in release builds
