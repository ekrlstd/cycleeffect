<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/YOLOv8-00FFFF?style=for-the-badge&logo=yolo&logoColor=black" alt="YOLOv8"/>
  <img src="https://img.shields.io/badge/On--Device_AI-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white" alt="On-Device AI"/>
</p>

<h1 align="center">Headsup</h1>
<h3 align="center">Your AI Co-Pilot for Smarter, Safer Driving</h3>

<p align="center">
  <strong>On-device AI traffic intelligence • Real-time narration • Privacy-first • AV-ready</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-MVP-brightgreen?style=flat-square" alt="Status"/>
  <img src="https://img.shields.io/badge/Platform-iOS | Android-blue?style=flat-square" alt="Platform"/>
  <img src="https://img.shields.io/badge/AI-On--Device-purple?style=flat-square" alt="AI"/>
</p>

## 🎯 The Problem

**Every year, 1.35 million people die in traffic accidents worldwide.** Most of these are preventable with better situational awareness.

Current navigation apps like **Waze** and **Google Maps** rely on crowdsourced data—reactive, delayed, and often inaccurate. They tell you there's traffic ahead, but not why it matters to you.

## 💡 Our Solution

**Headsup** is an intelligent traffic assistant that understands _your_ context—your speed, heading, and position—and delivers spoken, actionable insights in real-time.

```
Waze: "Traffic at intersection"
Headsup: "Three vehicles approaching from your left at the roundabout. Yield before entering."
```

### What Makes Us Different

| Feature      | Waze/Google Maps       | Headsup                              |
| ------------ | ---------------------- | ------------------------------------ |
| Data Source  | Crowdsourced (delayed) | **Government APIs + AI** (real-time) |
| Processing   | Cloud-based            | **On-device** (instant)              |
| Privacy      | Location tracked       | **Data never leaves device**         |
| Context      | Generic alerts         | **Personalized to YOUR trajectory**  |
| Offline      | Limited                | **Full functionality**               |
| Future-Ready | Static                 | **AV architecture**                  |

## 🚀 How It Works

<p align="center">
  <em>Real-time pipeline: Trafikverket API → On-device AI → Contextual narration</em>
</p>

1. **Fetch** real-time traffic data from Trafikverket
2. **Combine** with your GPS location, heading, and speed
3. **Process** through on-device AI for contextual reasoning
4. **Narrate** personalized safety alerts via text-to-speech

## 📱 App Screenshots

<p align="center">
  <img src="docs/screenshots/home.png" alt="Home Screen" width="250"/>
  &nbsp;&nbsp;
  <img src="docs/screenshots/map.png" alt="Map View" width="250"/>
  &nbsp;&nbsp;
</p>

<p align="center">
  <em>Dark mode interface optimized for driving • Interactive map • Real-time narration</em>
</p>

## ✨ Key Features

### 🗣️ AI-Powered Voice Assistant

Ask questions while driving. Get answers without taking your eyes off the road.

- _"What's the traffic like at the next intersection?"_
- _"Are there any accidents ahead?"_
- _"How many vehicles at the roundabout?"_

### 🗺️ Smart Intersection Tracking

Automatically calculates and monitors the **next 5 intersections** based on your route, providing relevant data before you get there.

### 🔒 Privacy-First Architecture

Your location data **never leaves your device**. All AI processing happens locally. No cloud. No tracking. No compromise.

> Our on-device architecture is also purpose-built for V2V (Vehicle-to-Vehicle) processing. We're not building a traffic app—we're building the communication layer for cooperative autonomous driving of the future.

## 🏃 Quick Start

### Prerequisites

- Flutter 3.8.1+
- Python 3.8+
- Android API 26+ / iOS 12+

### Installation

```bash
# Clone the repository
git clone https://github.com/ekrlstd/cycleeffect.git
cd cycleeffect

# Install Flutter dependencies
flutter pub get

# Start the backend
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000

# Run the app
cd ..
flutter run
```

### Configuration

Update `lib/config.dart` with your backend IP:

```dart
static const String backendHost = 'YOUR_IP_HERE';
static const int backendPort = 8000;
```

## 💼 Business Model

### Target Market

- **500K+** daily commuters in Sweden alone
- **New drivers** needing extra guidance
- **Professional drivers** (trucking, delivery)
- **Fleet operators** requiring safety monitoring

### Revenue Streams

| Stream            | Description                                  |
| ----------------- | -------------------------------------------- |
| **Freemium**      | Basic narration free, premium features paid  |
| **B2B Licensing** | Driving schools, fleet management, insurance |
| **V2V Platform**  | Future licensing for autonomous vehicles     |

## 👥 Team

Built with ❤️ by a team passionate about software, AI, and building things that help people.
Aakrish Lama

<p align="center">
  <strong>Aakrish Lama • Abdirashid Sammantar • Ebbe Karlstad • Syuash Mullick</strong>
</p>

## 📄 License

GPLv2 License — See [LICENSE](LICENSE) for details.

<p align="center">
  <strong>Headsup</strong> — Because every second counts on the road.
  <br/><br/>
  <img src="https://img.shields.io/badge/Built_for-Safer_Roads-red?style=for-the-badge" alt="Built for Safer Roads"/>
</p>
