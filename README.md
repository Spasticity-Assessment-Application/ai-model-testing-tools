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

#### In debug mode with hot reload:

```bash
flutter run --debug
```

#### In release mode:

```bash
flutter run --release
```

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
