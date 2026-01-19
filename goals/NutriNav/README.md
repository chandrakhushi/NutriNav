# NutriNav - Smart Nutrition & Activity Assistant

A SwiftUI iOS app for tracking nutrition, discovering recipes, finding nearby healthy food options, and managing fitness goals.

## Features

### Core Features
- **Daily Nutrition Tracking**: Track calories, protein, carbs, and fats with visual progress indicators
- **Ingredient-Based Recipe Suggestions**: Input ingredients you have and get personalized recipe recommendations
- **Nearby Food Options**: Find restaurants with nutrition info, filtered by budget and preferences
- **Activity Integration**: Track activities and hobbies that affect nutrition needs
- **Cycle-Aware Nutrition**: Adjust nutrition goals based on menstrual cycle phase (for females)
- **Profile & Settings**: Manage personal info, dietary restrictions, and goals
- **Budget Tracking**: Filter recipes and nearby food by budget constraints

### Onboarding Flow
1. Welcome screen with app introduction
2. Personal info (age, gender)
3. Stats (height, weight)
4. Activity level selection
5. Fitness goal selection

### Main Screens
- **Home/Dashboard**: Nutrition tracking, streak display, motivational content
- **Recipes**: Search and browse recipes based on available ingredients
- **Nearby**: Restaurant listings with filters and nutrition info
- **Profile**: User info, progress tracking, goals management

## 📖 Navigation Guide

**👉 See [SCREEN_NAVIGATION.md](./SCREEN_NAVIGATION.md) for a complete guide to:**
- All screens and their file locations
- Components used in each screen
- Design system elements per screen
- Quick reference for making changes
- Screen-by-screen consistency checklist

## Project Structure

```
NutriNav/
├── Models/
│   ├── User.swift              # User profile and onboarding data
│   ├── Nutrition.swift          # Nutrition tracking models
│   ├── Recipe.swift             # Recipe data model
│   ├── Restaurant.swift         # Restaurant data model
│   └── Activity.swift           # Activity and hobby tracking
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift      # Login/Sign Up screen
│   ├── Components/
│   │   ├── DesignSystemComponents.swift  # Reusable UI components
│   │   └── HealthKitComponents.swift     # HealthKit components
│   ├── Onboarding/
│   │   ├── OnboardingWelcomeView.swift
│   │   ├── OnboardingPersonalInfoView.swift
│   │   ├── OnboardingStatsView.swift
│   │   ├── OnboardingActivityView.swift
│   │   └── OnboardingGoalView.swift
│   └── Main/
│       ├── MainTabView.swift    # Tab bar navigation
│       ├── HomeView.swift       # Dashboard
│       ├── RecipesView.swift    # Recipe browser
│       ├── NearbyView.swift     # Restaurant finder
│       ├── ProfileView.swift    # User profile & settings
│       ├── ActivitiesView.swift # Hobbies & activities
│       ├── CycleView.swift      # Cycle-aware nutrition
│       └── BudgetView.swift     # Budget tracker
├── ViewModels/
│   └── AppState.swift           # Global app state management
├── Services/
│   └── MockDataService.swift   # Mock data for MVP development
├── Utilities/
│   ├── DesignSystem.swift       # Design system (colors, fonts, spacing)
│   └── ColorExtensions.swift   # Legacy color extensions
├── ContentView.swift            # Root view
└── NutriNavApp.swift           # App entry point
```

## Setup Instructions

### Requirements
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Installation

1. **Open in Xcode**
   ```bash
   cd /Users/kchandra/Desktop/NutriNav
   open NutriNav.xcodeproj
   ```
   Or create a new Xcode project and add all the files.

2. **Create Xcode Project** (if starting fresh):
   - Open Xcode
   - Create a new iOS App project
   - Name: "NutriNav"
   - Interface: SwiftUI
   - Language: Swift
   - Minimum iOS: 17.0
   - Copy all files from this directory into the project

3. **Build and Run**
   - Select a simulator (iPhone 15 Pro recommended)
   - Press Cmd+R to build and run

## API Integration Placeholders

The app is structured to easily integrate with the following APIs:

### Google Maps / Places API
- Location: `Services/GooglePlacesService.swift` (to be created)
- Used in: `NearbyView.swift`
- **API Key Required**: Add to `Info.plist` or environment variables

### Nutritional Database API
- Location: `Services/NutritionService.swift` (to be created)
- Used in: `RecipesView.swift`, `HomeView.swift`
- **API Key Required**: Add to configuration

### DoorDash / UberEats API
- Location: `Services/DeliveryService.swift` (to be created)
- Used in: `NearbyView.swift` - "Order Now" buttons
- **API Key Required**: Add to configuration

### HealthKit Integration
- Location: `Services/HealthKitService.swift` (to be created)
- Used for: Activity tracking, cycle data
- **Permissions Required**: HealthKit entitlements in Xcode

### RevenueCat Integration
- Location: `Services/SubscriptionService.swift` (to be created)
- Used in: `ProfileView.swift` - Premium upgrade
- **API Key Required**: Add to configuration

### TelemetryDeck Integration
- Location: `Services/AnalyticsService.swift` (to be created)
- Used for: Event tracking throughout the app
- **API Key Required**: Add to configuration

## Mock Data

The app currently uses mock data from `MockDataService.swift`:
- 3 sample recipes
- 3 sample restaurants
- Sample user data
- Sample nutrition goals

Replace with real API calls when ready.

## Design System

**👉 See [SCREEN_NAVIGATION.md](./SCREEN_NAVIGATION.md) for complete design system documentation.**

### Colors
- **Background**: `Color.background` - #ffffff
- **Primary**: `Color.primary` - #030213
- **Primary Accent**: `Color.primaryAccent` - #4CAF50 (green)
- **Input Background**: `Color.inputBackground` - #f3f3f5
- **Nutrition Colors**: 
  - Calories: Orange (`Color.calorieColor`)
  - Protein: Blue (`Color.proteinColor`)
  - Carbs: Green (`Color.carbColor`)
  - Fats: Yellow (`Color.fatColor`)

### Typography
- **h1**: 24pt, medium weight
- **h2**: 20pt, medium weight
- **h3**: 18pt, medium weight
- **h4**: 16pt, medium weight
- **label**: 16pt, medium weight
- **button**: 16pt, medium weight
- **input**: 16pt, regular weight

### Spacing & Radius
- **Card Padding**: 16px
- **Button Padding**: 12px
- **Card Corner Radius**: 10px (lg)
- **Button Corner Radius**: 8px (md)
- **Badge Corner Radius**: 6px (sm)

All design system values are defined in `Utilities/DesignSystem.swift`.

## Next Steps for Production

1. **API Integration**
   - Replace mock data with real API calls
   - Add error handling and loading states
   - Implement caching

2. **HealthKit Integration**
   - Request permissions
   - Sync activity data
   - Sync cycle data (for females)

3. **Authentication**
   - Add user authentication
   - Implement user accounts
   - Add data persistence

4. **Premium Features**
   - Integrate RevenueCat
   - Add subscription management
   - Implement premium features

5. **Analytics**
   - Integrate TelemetryDeck
   - Add event tracking
   - Implement user analytics

6. **Testing**
   - Add unit tests
   - Add UI tests
   - Test on multiple devices

## Notes

- The app uses iOS 17+ features (NavigationStack, etc.)
- All navigation is handled via SwiftUI NavigationStack
- State management uses @EnvironmentObject for global state
- Mock data is provided for immediate testing
- UI matches the provided Figma designs

## License

This is an MVP version for development purposes.

