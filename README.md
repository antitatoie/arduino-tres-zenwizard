# arduino-tres-zenwizard

Smart desk ergonomics & workspace environment monitor built with Flutter, Dart, and Arduino (DHT11, LDR, RGB LED, Buzzer).

### Expected Project Structure (template only subject to change)
```text
posture_wizard/
├── firmware/                        # Arduino sketches & hardware circuit diagrams
│   └── posture_wizard_firmware/
│       └── posture_wizard_firmware.ino
├── lib/
│   ├── main.dart
│   ├── models/                    # TelemetryData, PomodoroState, SettingsConfig
│   ├── services/                  # SerialPortService, ThresholdAlertService
│   ├── providers/                 # State management (EnvironmentProvider, TimerProvider)
│   └── screens/
│       ├── home_screen.dart       # Figure 1: Real-time gauges, Pomodoro circular ring
│       ├── stats_screen.dart      # Figure 2: Focus charts & session logs
│       └── settings_screen.dart   # Figure 3: Lux/Temp thresholds, COM port selector
├── pubspec.yaml
└── README.md
```

### Dependencies (Please check if you have the proper dependencies)
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Serial communication over USB
  # For Desktop (Windows/macOS/Linux): flutter_libserialport
  # For Android USB-OTG: usb_serial_communication or flutter_serial_communication
  universal_serial: ^0.0.1        # Or flutter_libserialport for desktop USB serial

  # UI & Charts for the Statistics Tab
  fl_chart: ^0.69.0               # To render the focus stats bar/line charts

  # State Management
  provider: ^6.1.2                # Or flutter_riverpod

  # Local Storage for Preferences & Historical Logs
  shared_preferences: ^2.3.2
```

  ## Team Setup & Development Guide

**Follow these steps to set up the project on your computer/laptop**

### 1. Clone the Repository
```bash
git clone [https://github.com/antitatoie/posture-wizard.git](https://github.com/antitatoie/posture-wizard.git)
cd posture-wizard
```
---

### 2. Install Dependencies
```bash
flutter pub get
```
---

### 3. Verify Environment
```bash
flutter doctor
```
---

### 4. Run the Project
```bash
flutter run
```
---

### 5. Git Workflow
```bash
# 1. Update your local main branch
git checkout main
git pull origin main

# 2. Create and switch to your feature branch
git checkout -b feature/your-feature-name

# 3. Stage and commit your changes
git add .
git commit -m "feat: brief summary of work"

# 4. Push your branch to GitHub and open a Pull Request (PR)
git push origin feature/your-feature-name
```

