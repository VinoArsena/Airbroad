# Airbroad

Airbroad helps people with respiratory conditions decide *when* to visit a destination in Singapore, not just whether the air is generally "good" or "bad" today. Pick a place and a time — up to a few days ahead — and Airbroad pulls live pollutant and weather data, classifies the respiratory risk for that specific hour, and shows what's driving the number.

## How it works

1. **Search** — pick any location in Singapore (`MKLocalSearchCompleter`-backed autocomplete).
2. **Pick a time** — today or a few days ahead, by hour.
3. **Fetch** — Airbroad pulls pollutant (PM2.5, PM10, CO, NO₂, O₃) and weather (temperature, humidity, wind, rain) data from two Open-Meteo endpoints for that location and time window.
4. **Classify** — a CoreML model (trained on labeled AQI/weather data with XGBoost) predicts one of four risk levels — Safe, Slight Risk, Moderate Risk, High Risk — for each hour. If the model fails to load, Airbroad falls back to a threshold-based classification derived from EPA AQI category breakpoints, so the app never shows nothing.
5. **Recommend** — the result screen shows the risk level, a plain-language recommendation, the next better time if the current hour isn't ideal, and simple visual breakdowns of AQI/PM2.5/PM10/O₃ so the numbers mean something at a glance.

## Tech stack

- **SwiftUI**, iOS 26.5+, `@Observable` / `@Bindable` (no `ObservableObject` / `@Published`)
- **MVVM** — Views render, ViewModels hold state and logic, plain structs hold data
- **Open-Meteo** — weather + air quality APIs (two separate endpoints)
- **CoreML** (`RiskModel.mlpackage`) — XGBoost classifier, converted via `coremltools`
- **MapKit** (`MKLocalSearchCompleter`) — location search
- **Swift Charts** — hourly pollutant trend visualization
- Liquid Glass (`.glassEffect`) throughout, batched with `GlassEffectContainer` where multiple glass surfaces overlap on screen at once

## Project structure

```
Airbroad/
├── App/                    # App entry point
├── Root/                   # ContentView — top-level container
├── AirQualityAPI/          # Open-Meteo networking + shared models (PollutantType, AQICategory)
├── MLModel/                # RiskModel.mlpackage + RiskPredictionService (CoreML wrapper)
├── Features/
│   ├── SearchView/         # Location search, date/time picker, recommendation card
│   └── ResultView/         # Hourly breakdown, charts, per-pollutant stats
└── Resources/               # Images, assets
```

## Requirements

- Xcode with the iOS 26.5 SDK
- Swift 5 toolchain (the project uses the modern `@Observable` macro-based state system)

## Setup

1. Clone the repo and open `Airbroad.xcodeproj`.
2. Build and run — no API keys required; Open-Meteo's public endpoints are used as-is.
3. First launch defaults to Singapore's current conditions; use the search bar to pick a specific location.

## Known limitations

- **Risk model validation is a work in progress.** `RiskModel.mlpackage` was trained on a labeled dataset via XGBoost, but training provenance (which data split was used, whether results are reproducible) isn't fully documented yet, and per-class recall — especially for the rarer "High Risk" class — hasn't been independently confirmed against a clean holdout. Treat classifications as a prototype signal, not a validated clinical tool.
- **Singapore-only.** Location search and the date/time range are scoped to Singapore; the approach isn't yet generalized to other regions.
- **No offline mode.** Every forecast requires a live Open-Meteo request; there's no cached/offline fallback beyond the existing loading/error/retry states if the network is unavailable.

## License

MIT — see [LICENSE](./LICENSE).
