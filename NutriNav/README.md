# NutriNav - AI-Powered Nutrition & Activity Assistant

NutriNav is a high-performance SwiftUI application that leverages Apple HealthKit, Yelp, and Spoonacular to provide a deeply personalized nutrition and fitness experience. It uniquely adapts goals and recommendations based on activity level, metabolic data, and biological cycles.

## 🚀 Actual Core Features

### 1. Intelligent Nutrition Dashboard
- **Macro-Tracking**: Real-time visualization of Calories, Protein, Carbs, and Fats.
- **Dynamic Goals**: Targets that shift based on active energy burned (HealthKit) and biological phases.
- **Progress Tracking**: Daily streaks and visual progress indicators for health targets.

### 2. Cycle-Aware Intelligence (The "Hero" Feature)
- **Automatic Prediction**: Uses **Apple HealthKit** menstrual flow data to predict cycle phases (Menstruation, Follicular, Ovulation, Luteal).
- **Manual Fallback**: Full manual cycle logging for users without HealthKit data.
- **Bio-Adaptive Nutrition**: Automatically adjusts macro targets and workout intensity recommendations based on the current biological phase.

### 3. Workout Recommendation Engine
- **Metabolic Analysis**: Recommends workouts (Yoga, Running, Gym, etc.) based on "Available Calories" and "Protein Status".
- **Phase Integration**: Tailors intensity (Light to Very Intense) to the user's cycle phase.
- **Tactile Feedback**: Integrated haptic feedback for all major navigation and logging actions.

### 4. Smart Recipe Discovery
- **Spoonacular Integration**: Search 5,000+ recipes with filters for diets (Keto, Vegan, etc.), max ready time, and nutrition ranges.
- **Ingredient analysis**: Detailed breakdown of ingredients, instructions, and nutrition per serving.

### 5. Nearby Healthy Dining
- **Dual-Provider Mapping**: Uses **Apple MapKit** by default or **Yelp Fusion API** for enhanced restaurant data.
- **Cuisine-Based Nutrition Estimation**: Automatically estimates the nutritional value of restaurant meals based on cuisine type and price range.
- **Location Intelligence**: Real-time restaurant discovery with distance and price filtering.

### 6. HealthKit Ecosystem
- **Seamless Sync**: Bi-directional sync for steps, active calories burned, height/weight metrics, and workouts.
- **Observer Queries**: Real-time updates when HealthKit data changes in the background.

## 🏗️ Technical Architecture

### Tech Stack
- **Framework**: SwiftUI (iOS 17.0+)
- **State Management**: @EnvironmentObject centered around `AppState`.
- **Concurrency**: Modern Swift Concurrency (async/await) for all network and HealthKit operations.
- **Navigation**: Hero-focused `NavigationStack` with a custom floating action button for logging.

### Implementation Details: Services
- `HealthKitService`: Manages all Apple Health integrations and permissions.
- `CyclePredictionService`: Medically-backed logic for phase determination.
- `WorkoutRecommendationService`: Adaptive logic engine for fitness suggestions.
- `RecipeService`: Wrapper for the Spoonacular API.
- `YelpService`: Optional provider for high-fidelity restaurant data.
- `FoodService`: Core logic for managing food logs and daily goals.

## 📁 Project Structure

```
NutriNav/
├── Models/              # Codable data models (User, FoodLog, Recipe, etc.)
├── Views/               
│   ├── Main/            # Primary feature views (Home, Recipes, Nearby)
│   ├── Onboarding/      # Multi-step personalization flow
│   ├── Components/      # Reusable UI elements (Design System)
├── ViewModels/          # AppState (Global State)
├── Services/            # Core logic (HealthKit, Yelp, Spoonacular, Bio-Logic)
├── Utilities/           # Design System tokens (Colors, Spacing, Haptics)
└── NutriNavApp.swift    # App Entry Point
```

## 🛠️ Setup & Requirements

- **Environment**: Xcode 15.2+, iOS 17.0+
- **API Keys**:
  - **Spoonacular**: Required for Recipe search (set in `RecipeService.swift`).
  - **Yelp**: Optional for advanced restaurant search (set in `YelpService.swift`).
- **Permissions**:
  - Requires HealthKit and Location permissions for full functionality.

---
*Developed as a high-fidelity MVP for smart nutrition management.*

