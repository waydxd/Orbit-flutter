# Orbit: An Intelligent Calendar and Planning Solution Powered by AI

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev) [![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)](https://dart.dev) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0.en.html)

This is the Flutter frontend repository for the Orbit app, a smart calendar and planning mobile application developed as a Final Year Project (FYP) at HKUST (2025-2026). Orbit uses AI to provide personalized scheduling, habit tracking, natural language input, OCR-based event extraction, and conversational assistance. It aims to address gaps in existing apps like Apple Calendar, Google Calendar, Todoist, and Notion by offering proactive, adaptive features.

License: This project is licensed under the GNU Affero General Public License v3.0 — see the [LICENSE](./LICENSE) file for details.

## Project Overview
- **Objectives** (from proposal):
    - Intelligent, user-friendly interface for event management (e.g., multi-view displays, natural language input, OCR).
    - Personalized recommendations from historical data.
    - Conversational AI for planning and decision-making.
    - Proactive/predictive planning (e.g., buffer times, work-rest balance).
- **Core Features**:
    - User authentication (JWT-based).
    - Task management with real-time sync.
    - Countdowns and basic calendar views (day/week/month, pre-loaded holidays).
    - AI: Habit tracking (clustering), natural language input (DistilBERT), scheduling suggestions (Gemini API), chatbot (LangChain), OCR (Google ML Kit).
    - Extra: Hashtag/topic marking (Sentence-BERT), location tracking (Google Maps API), special event display.
- **Target Platforms**: iOS, Android (cross-platform via Flutter), with web support potential.
- **Architecture**: MVVM pattern for maintainability. Starts as a modular monolith, evolving to microservices. Offline support via Hive/SQLite.
- **Backend Integration**: Communicates with Golang backend (REST/gRPC) and Python AI services (e.g., Gemini API, vLLM for LLMs).
- **Data Storage**: Local (Hive/SQLite for offline), synced to PostgreSQL/MongoDB backend.

## Tech Stack
- **Frontend**: Flutter (Dart) with Riverpod/Bloc for state management.
- **AI/ML**: Google ML Kit (on-device OCR), Gemini API (NLP/chatbot), Sentence-BERT (classification), TensorFlow Recommenders (location suggestions).
- **Offline/Storage**: Hive or SQLite.
- **UI Design**: Neumorphic theme (preferred by ~70% in Qualtrics survey), light/dark modes, customizable colors.
- **Dev Tools**: VS Code/Android Studio, Figma for UI prototypes.
- **CI/CD**: GitHub Actions for builds/tests (blue-green deployment planned).
- **Testing**: Unit (Flutter test), Integration, UAT (via Qualtrics surveys), Performance/Security.

## Setup Instructions
### Prerequisites
- Flutter SDK (v3.x): Install from [flutter.dev](https://flutter.dev/docs/get-started/install).
- Dart (v3.x): Comes with Flutter.
- Android Studio/Xcode for emulators/simulators.
- Git, VS Code/Android Studio.
- API Keys: Google Maps, Gemini API, Resend (email) – store in `.env` (use `flutter_dotenv` package).

### Installation
1. Clone the repo: `git clone https://github.com/waydxd/Orbit-flutter.git`
2. Navigate: `cd Orbit-flutter`
3. Install dependencies: `flutter pub get`
4. Run: `flutter run` (select device/emulator)

For iOS: Ensure CocoaPods is installed (`pod install` in `ios/` folder).

### Environment Configuration
- Create `.env` in root for Google Maps, Gemini API, Resend, etc. (use `flutter_dotenv` package).
- **Compile-time secrets** (pass via `--dart-define` when building/running):
  - `HUGGING_FACE_API_KEY` – Hugging Face API key for text classification.
  - Example: `flutter run --dart-define=HUGGING_FACE_API_KEY=your_key`
  - Note: NLP parse endpoints use the JWT Bearer token from login (Orbit-core); no separate token needed.

