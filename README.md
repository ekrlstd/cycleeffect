Updated description:
Our application is an intelligent traffic assistant that helps users make the best traffic decision based on real-time traffic updates. These updates includes things like collision warnings, high and low traffic areas, etc.
Unlike other tools like Waze which is built on crowdsourced information, our app uses the Trafikverket API and on-device offline AI to give the user intelligent information and insights through traffic cameras and other means, provided by the API itself.
The parts of the API we're using is built around traffic cameras which most often are located at intersections. Using the phones GPS and speedometer features, our app will calculate the next five intersections and give relevant data to the user.
The app is meant to be used in two ways - both as a regular mobile app you can use while driving, the app provides an AI chat with TTS, so you can ask questions about upcoming traffic situations. It will also provide you with a list of information for the five upcoming intersections. Along with this, a map that shows the location of the five intersections, and the user, will also be available so the user can have a better visual of where potential traffic risks are located.
The second usecase for the app is running it in the background, having it minimized while other useful driving services like Google Maps are running on fullscreen. Our app will then provide this information to the user with text to speech, and the user can open the app at any point to ask questions and get personalized information based on the real-time traffic updates.
Note that this app isn't just an app - it's a whole system that will be more and more relevant in the future. We imagine our system can be used in autonomous vehicles, wether those are personal cars, or trucks, or anything else.
I want to fully redesign the app we've built. Currently it's a Material 3 very simple app that has the following layout:
App name and a slogan below it.
A card that has the map.
The AI chat in another card below with a voice waveform visualiser thing.
The list of traffic updates.
A button that says narrate to get the AI voice TTS system to speak and say the most recent or closest traffic situation.

# TrafficVision AI - Intelligent Traffic Narration Assistant

## Project Overview

TrafficVision AI is an Android application that provides intelligent, context-aware traffic narration and collision warnings using on-device AI. The app combines real-time traffic data from Trafikverket API (car counts, density, accidents) with the user's precise location and heading to deliver personalized, spoken safety alerts - like having an intelligent co-pilot who understands what's happening around you.

## The Problem We're Solving

Current navigation apps show you traffic data but don't _understand_ it in your context:

- **No Spatial Awareness**: Apps show "3 cars ahead" but don't know if they're in your lane or crossing your path
- **Generic Alerts**: Warning "traffic ahead" without explaining the specific danger to YOU
- **Cloud Latency**: Critical split-second decisions (like at roundabouts) require instant processing
- **Privacy Concerns**: Continuous uploading of your precise location, speed, and heading to servers
- **Driver Distraction**: Reading traffic data while driving is dangerous

**Example Scenario**: You're approaching a roundabout. Trafikverket data shows 3 vehicles detected at the camera location. A normal app would just say "traffic at roundabout." Our app knows your exact position, heading, and speed, combines it with the traffic data, and narrates: "Caution: Three vehicles approaching from your left at the roundabout - yield before entering."

## Why On-Device AI?

Our solution requires on-device LLM processing because:

1. **Real-Time Contextual Reasoning**: At a roundabout, you have 2-3 seconds to make decisions. Cloud-based LLM calls (2-5 seconds latency) are too slow. On-device Llama 3.2 delivers contextual narration in <500ms.

2. **Privacy First**: Your precise location, speed, heading, and driving patterns never leave your device. The app combines external traffic data with your personal context locally, addressing privacy concerns.

3. **Offline Capability**: Highway driving often involves areas with spotty connectivity. Our app continues functioning with cached traffic data and local LLM processing, providing safety warnings even without network access.

4. **Reduced API Costs**: By processing narration on-device, we eliminate expensive cloud LLM API calls for every user interaction (which could be hundreds per trip).

## Technical Architecture

### Core Components

#### 1. AI Model: Llama 3.2 Text (1B or 3B)

- **Why Llama 3.2**: Specifically optimized for edge devices with efficient text reasoning
- **Model Size**: Using the 1B or 3B parameter text variant for mobile deployment
- **Task**: Contextual reasoning and natural language narration
- **Input**: Structured traffic data + user context (location, heading, speed)
- **Output**: Natural language safety warnings and traffic narration

#### 2. Data Pipeline

```
Trafikverket API → Traffic Data Parser → Context Builder → Llama 3.2 → Text-to-Speech
       ↓                                      ↑
  Cache Manager                        GPS + Sensors
       ↓
  Local Database
```

**Data Flow:**

1. **Camera Registry**: Fetch static camera locations and metadata from Trafikverket
2. **Traffic Data Polling**: Fetch real-time textual data (car counts, density, accidents) from Trafikverket API
3. **User Context**: Gather GPS location, heading (compass), speed from device sensors
4. **Context Building**: Match nearby camera data with user position and trajectory
5. **LLM Reasoning**: Llama 3.2 processes combined data to generate contextual warnings
6. **Narration**: Text-to-speech delivers spoken alerts to driver

**Example Data Processing:**

_Input to LLM:_

```json
{
  "user_context": {
    "location": "57.7089° N, 11.9746° E",
    "heading": "North (0°)",
    "speed": "50 km/h",
    "road": "Approaching roundabout at Korsvägen"
  },
  "traffic_data": {
    "camera_id": "CAM_123",
    "location": "Korsvägen roundabout entrance",
    "vehicle_count": 3,
    "density": "moderate",
    "approaching_direction": "West (270°)",
    "incidents": null
  }
}
```

_LLM Output:_
"Caution: Three vehicles approaching from your left at the roundabout. Yield before entering."

#### 3. Android Implementation

- **Language**: Kotlin
- **AI Framework**: ONNX Runtime or llama.cpp for Android
- **Location Services**: Fused Location Provider (GPS + Network)
- **Sensors**: Magnetometer (compass), Accelerometer (movement detection)
- **Database**: Room for caching traffic data and camera locations
- **TTS**: Android Text-to-Speech engine
- **UI**: Jetpack Compose for modern, reactive interface
- **Maps**: OpenStreetMap or Google Maps for visualization

### Key Features

1. **Contextual Traffic Narration**
   - Real-time spoken alerts based on your position and heading
   - "3 cars from your left" instead of just "traffic detected"
   - Understands complex intersections (roundabouts, merges, crossings)
   - Natural language warnings that make sense for YOUR situation

2. **Intelligent Collision Warnings**
   - Predicts potential conflicts based on trajectory analysis
   - Warns about vehicles in crossing paths
   - Roundabout entry/exit safety alerts
   - Merge lane conflict detection

3. **Offline Mode**
   - Continue with cached traffic data
   - LLM runs entirely on-device (no internet needed for reasoning)
   - Function in areas with poor connectivity

4. **Privacy Dashboard**
   - Show users that location data never leaves device
   - Display on-device processing statistics
   - Export/delete all local data

5. **Future: V2V Communication Ready**
   - Architecture designed for vehicle-to-vehicle data exchange
   - As autonomous vehicles become prevalent, app can integrate direct vehicle communication
   - Scale from API-based traffic data to real-time V2V mesh network
   - Foundation for next-generation cooperative driving systems

### Example User Scenarios

**Scenario 1: Roundabout Entry**

- _User_: Approaching roundabout at 50 km/h, heading north
- _Traffic Data_: 3 vehicles detected, approaching from west at camera location
- _App Narrates_: "Caution: Three vehicles approaching from your left at the roundabout. Yield before entering."

**Scenario 2: Highway Merge**

- _User_: On merging lane, heading northeast
- _Traffic Data_: High density (8 vehicles) in right lane ahead
- _App Narrates_: "Heavy traffic in right lane ahead. Prepare to merge carefully. Eight vehicles detected in your merging zone."

**Scenario 3: Intersection Warning**

- _User_: Approaching intersection, going straight
- _Traffic Data_: 2 vehicles at perpendicular road
- _App Narrates_: "Two vehicles detected on cross street to your right. Proceed with caution at intersection."

## Business Case

### Target Market

- **Primary**: Daily commuters navigating complex intersections (500,000+ potential users in Sweden)
- **Secondary**: New drivers needing extra guidance, elderly drivers, professional drivers
- **Future**: Autonomous and semi-autonomous vehicle integration (V2V market)

### Revenue Model

1. **Freemium**: Basic narration free, premium features (multi-route planning, advanced warnings) paid
2. **B2B Licensing**:
   - Driver training companies (new driver assistance)
   - Fleet management (safety monitoring)
   - Insurance companies (safer driving discounts)
3. **V2V Platform**: Future licensing for autonomous vehicle manufacturers

### Competitive Advantage

- **Only app** providing AI-powered contextual traffic narration on-device
- **First-mover** in on-device LLM-based driving assistance
- **Privacy-first** approach differentiates from Google/Waze
- **Lower operational costs** than cloud-based LLM services
- **V2V Ready**: Architecture positions us for autonomous vehicle future

### Market Validation

- Privacy concerns driving users away from big-tech location tracking
- Growing market for driver assistance features (lane assist, collision warnings)
- **Unique Insight**: Traditional ADAS systems cost $2,000-5,000 in new cars. Our software solution delivers similar contextual awareness for fraction of the cost
- Autonomous vehicle market growing 20% YoY - early V2V positioning valuable

### The V2V Vision

Today's app is the foundation for tomorrow's cooperative driving ecosystem:

- **Phase 1** (Now): API-based traffic data + on-device LLM narration
- **Phase 2** (2-3 years): Semi-autonomous vehicles broadcast positions directly to app
- **Phase 3** (5+ years): Full V2V mesh network where all vehicles communicate
- Our on-device architecture is perfect for low-latency V2V processing

This positions us not just as a traffic app, but as early infrastructure for cooperative autonomous driving.

## Embedl Hub Validation Strategy

We will use Embedl Hub to ensure our LLM-powered narration runs efficiently across the diverse Android ecosystem:

### Performance Targets

- **LLM Inference Time**: <500ms per contextual reasoning query on mid-range devices
- **Memory Usage**: <300MB RAM footprint (lighter than vision models)
- **Battery Impact**: <3% additional drain per hour of active use
- **Device Coverage**: 85%+ of Android devices from 2019 onwards (text models are lighter than vision)
- **Cold Start**: <2 seconds to load model on app launch

### Testing Matrix

1. **Flagship Devices**: Samsung Galaxy S23, Google Pixel 8
   - Target: <200ms inference, handle complex multi-vehicle scenarios
2. **Mid-Range**: Samsung Galaxy A54, OnePlus Nord
   - Target: <500ms inference, 2-3 vehicle scenarios
3. **Budget Devices**: Xiaomi Redmi Note 12
   - Target: <800ms inference, basic warnings
4. **Older Hardware**: Devices with Snapdragon 720G or older (3-4 years old)
   - Target: <1000ms inference, simplified narration

### Optimization Plan

- Test Llama 3.2 1B vs 3B variants (1B likely sufficient for narration)
- Benchmark INT8 vs INT4 quantization
- Optimize prompt engineering for faster inference
- Test context window sizes (less context = faster inference)
- Evaluate llama.cpp vs ONNX Runtime performance on Android

## Implementation Roadmap

### Phase 1: Hackathon MVP (24-48 hours)

- [ ] Integrate Llama 3.2 Text model (1B variant for speed)
- [ ] Connect to Trafikverket API for textual traffic data
- [ ] Implement GPS + compass sensor integration for user context
- [ ] Build context builder that combines traffic data + user position
- [ ] Create basic prompt engineering for collision warnings
- [ ] Implement text-to-speech narration
- [ ] Simple map view showing user position and nearby cameras
- [ ] Validate on Embedl Hub across 3-5 device types
- [ ] Demo scenario: Roundabout warning with 2-3 vehicles

### Phase 2: Post-Hackathon (1-2 weeks)

- [ ] Offline mode with intelligent traffic data caching
- [ ] Enhanced prompt engineering for diverse scenarios (merges, intersections)
- [ ] Route-based camera selection and prediction
- [ ] More sophisticated trajectory analysis
- [ ] Voice customization (speed, language)
- [ ] Enhanced UI with real-time visualization
- [ ] Comprehensive device testing

### Phase 3: Production (1-2 months)

- [ ] App store deployment
- [ ] User feedback integration
- [ ] Machine learning from user interactions
- [ ] B2B partnerships (driving schools, insurance)
- [ ] Multi-language support

### Phase 4: V2V Foundation (6-12 months)

- [ ] V2V protocol research and design
- [ ] Partnerships with autonomous vehicle manufacturers
- [ ] Extended sensor integration
- [ ] Real-time vehicle position broadcasting (when available)

## Team Roles

- **AI Developer**: LLM integration, prompt engineering, context reasoning, inference optimization
- **Android Developer**: App architecture, sensor integration (GPS, compass), UI, TTS, local storage
- **Business Developer**: Market research, V2V strategy, pitch deck, go-to-market planning
- **Systems Engineer**: Traffic data pipeline, API integration, caching strategy, real-time data processing

## Getting Started

### Prerequisites

- Android Studio Hedgehog or newer
- Android device or emulator (API 26+)
- Embedl Hub account (provided by hackathon)

### Setup Instructions

```bash
# Clone repository
git clone [repo-url]

# Open in Android Studio
# Sync Gradle dependencies

# Add Trafikverket API credentials to local.properties
TRAFIKVERKET_API_KEY=your_key_here

# Run on device
./gradlew installDebug
```

### Development Dependencies

- Llama 3.2 text model (1B or 3B - download instructions TBD)
- llama.cpp Android build OR ONNX Runtime
- Fused Location Provider (Google Play Services)
- Android Sensor APIs (magnetometer, accelerometer)
- Retrofit for Trafikverket API calls
- Room for local database
- Android Text-to-Speech
- Compose for UI

## Resources

### APIs & Data Sources

- **Trafikverket Open API**: https://api.trafikinfo.trafikverket.se/
- **Traffic Data Endpoints**: Textual data (vehicle counts, density, incidents)
- **Camera Metadata**: Static locations, coverage areas

### Model Resources

- **Llama 3.2**: Meta's edge-optimized text model
- **llama.cpp**: C++ implementation optimized for mobile
- **ONNX Runtime**: Alternative inference engine
- **Embedl Hub**: Performance testing platform

### Hackathon Support

- Embedl mentorship for on-device AI optimization
- Unlimited benchmarking on Embedl Hub
- Curated model library access

## Success Metrics

### Hackathon Judging Criteria Alignment

1. **On-Device Capability (25%)**: Comprehensive device testing via Embedl Hub, LLM optimization for diverse hardware, demonstrating 1B model runs on 85%+ devices
2. **Technical Execution (25%)**: Working prototype with real Trafikverket API integration, functional GPS+LLM pipeline, actual spoken narration
3. **Innovation & Originality (25%)**: First app using on-device LLM for contextual traffic narration; unique combination of traffic data + location context; V2V future vision
4. **Business Case (25%)**: Clear driver safety need, privacy advantages, cost benefits vs cloud LLMs, V2V positioning for autonomous vehicle future

### Demo Success Criteria

- Successfully narrate roundabout scenario with 2+ vehicles
- Show <500ms inference time on mid-range device
- Demonstrate offline capability
- Clear articulation of V2V future vision

## License

TBD - Likely MIT or Apache 2.0

## Contact

[Team contact information]

---

## Notes for Team

**Critical Path for Hackathon:**

1. Get Llama 3.2 running on Android FIRST
2. Connect to one camera feed and prove end-to-end pipeline
3. Test on Embedl Hub to validate device coverage
4. Polish demo and business case presentation

**Questions to Resolve:**

- Which Llama 3.2 variant (1B vs 3B)?
- Image processing resolution tradeoff?
- Caching strategy for offline mode?
- UI framework: Compose vs XML?

**Demo Story:**
"Imagine driving on E4 and seeing accident ahead before Waze users do. That's TrafficVision - privacy-first, works offline, instant alerts."
