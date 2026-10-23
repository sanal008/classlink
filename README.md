# ClassLink+ 

**ClassLink+** is a cross-platform smart classroom application built with Flutter and Firebase. It connects teachers and students with live video classes, an interactive whiteboard, AI-powered face-recognition attendance, analytics, and automated email notifications — all in one app.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Realtime%20Database-FFCA28?logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart&logoColor=white)

---

## Features

- **Role-based access** — separate flows for Admin, Teacher, and Student
- **Live video classes** — powered by ZegoCloud video conferencing
- **Interactive whiteboard** — shared drawing board inside live classes
- **AI attendance** — on-device face detection/recognition with TensorFlow Lite
- **Presence monitoring** — students are warned and auto-removed if not visible on camera
- **Attendance history** — students and teachers can review class-by-class records
- **Analytics dashboard** — attendance trends visualized with charts
- **Email notifications** — password resets and alerts via Firebase Cloud Functions + SendGrid
- **PDF export** — generate and share attendance reports as PDF
- **Forgot password flow** — email-based OTP reset

## Tech Stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter / Dart |
| Backend | Firebase Realtime Database, Firebase Storage |
| Serverless | Firebase Cloud Functions (Node.js 18) |
| Video | ZegoCloud UIKit Prebuilt |
| ML / AI | TensorFlow Lite (on-device face recognition) |
| Email | SendGrid (via Cloud Functions), Gmail SMTP (client) |
| PDF | `pdf` + `printing` packages |

## Project Structure

```
lib/
├── main.dart                 # App entry, Firebase bootstrap
├── login_screen.dart         # Login (admin / teacher / student)
├── signup.dart               # Registration
├── forgot_password_screen.dart
├── password_reset_screen.dart
├── firebase_service.dart     # Realtime DB access layer
├── email_service.dart        # SMTP email sending
├── attendance_service.dart   # Attendance logic
├── zego_service.dart         # Video conferencing + whiteboard + monitoring
├── whiteboard_service.dart
├── models.dart
├── admin/                    # Admin dashboard & test data generator
├── student/                  # Student dashboard, classes, history, profile
├── teacher/                  # Teacher dashboard
├── common/                   # Theme, settings, whiteboard UI
└── ml/                       # Face recognition service (TFLite)
functions/                    # Cloud Functions (SendGrid email sender)
assets/
├── classroom_animation.json  # Lottie splash animation
└── best_float32.tflite       # Trained face recognition model
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x, Dart `^3.8.1`)
- A [Firebase](https://console.firebase.google.com/) project
- A [ZegoCloud](https://www.zegocloud.com/) account (App ID + App Sign)
- Node.js 18+ (for Cloud Functions)

### 1. Clone and install

```bash
git clone https://github.com/sanal008/classlink.git
cd classlink
flutter pub get
```

### 2. Firebase setup

1. Create a Firebase project and enable **Realtime Database** and **Storage**.
2. Add a Flutter app to the project and download `google-services.json` into `android/app/`.
3. `lib/main.dart` falls back to explicit `FirebaseOptions` if native initialization fails — update those values if you use a different Firebase project.

### 3. Configure credentials (local only — do not commit)

> **Never commit real credentials.** Fill these in on your machine before building.

- `lib/email_config.dart` — set `smtpUsername` and `smtpPassword` (use a [Gmail App Password](https://support.google.com/accounts/answer/185833)).
- `lib/zego_service.dart` — `ZegoService.appID` / `appSign` must match your ZegoCloud project.

### 4. Cloud Functions (email via SendGrid)

```bash
cd functions
npm install

# Set your SendGrid key
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY" sendgrid.from="noreply@yourdomain.com"

# Deploy
firebase deploy --only functions
```

Emails are triggered when a node is created under `/email_requests` in the Realtime Database.

### 5. Run the app

```bash
flutter run
```

### Admin login

A quick admin bypass exists for development (`enrollmentId` + password `admin123` on the login screen). **Remove or guard this before any production release.**

## Building for Release

```bash
flutter build apk --release        # Android
flutter build appbundle --release  # Play Store
flutter build ios --release        # iOS (requires macOS + Xcode)
```

## Security Notes

- `lib/email_config.dart` ships with **empty placeholders** — add your SMTP credentials locally.
- Firebase API keys in `google-services.json` are client identifiers; protect your data with [Realtime Database Security Rules](https://firebase.google.com/docs/database/security).
- Store signing keys (`*.jks`, `key.properties`) out of version control (already git-ignored).
- The demo passwords in `lib/admin/test_data_generator.dart` are for seeding test data only.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m "Add amazing feature"`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is for academic use. All rights reserved unless otherwise noted.
