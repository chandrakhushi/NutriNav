# NutriNav - Screen Navigation & Component Guide

This guide helps you quickly find which files contain which screens and components, making it easy to navigate and make changes.

---

## 📱 Main App Screens

### 1. **HomeView** (Dashboard)
**File:** `Views/Main/HomeView.swift`

**Components Used:**
- `SectionHeader` - "Nutrition Progress", "Quick Actions"
- `PrimaryCard` - Nutrition progress card, Quick action cards
- `ProgressBar` - Calories and protein progress bars
- `InteractiveCard` - Quick action buttons (Recipe Suggestions, Nearby Food, Budget Planner)
- `PrimaryButton` - (via NavigationLink to Budget)
- Custom daily tip card (green background)

**Key Sections:**
- Header with "Today" and date
- Crown icon button (premium feature)
- Nutrition Progress Card (Calories & Protein)
- Quick Actions Section (3 cards)
- Daily Tip Card

**Design System Elements:**
- Font: h1 (24pt medium) for "Today"
- Font: h2 (20pt medium) for section headers
- Font: h3 (18pt medium) for quick action titles
- Font: input (16pt regular) for nutrition values
- Card padding: 16px
- Card corner radius: 10px (lg)
- Button corner radius: 8px (md)

---

### 2. **RecipesView**
**File:** `Views/Main/RecipesView.swift`

**Components Used:**
- `SectionHeader` - "Suggested for You"
- `PrimaryCard` - Recipe cards
- `BadgeView` - Difficulty badges ("Easy", "Medium")
- `PrimaryButton` - Save button in ingredient editor
- Custom search bar
- Custom ingredient input field

**Key Sections:**
- Header with "Recipes" title
- Search bar
- "Your Available Ingredients" section
- Recipe list with cards

**Sub-Views:**
- `IngredientEditorView` - Modal for editing ingredients

**Design System Elements:**
- Font: h1 (24pt medium) for title
- Font: h3 (18pt medium) for recipe titles
- Font: input (16pt regular) for search and ingredients
- Input background: #f3f3f5
- Card padding: 16px
- Card corner radius: 10px

---

### 3. **NearbyView** (Restaurants)
**File:** `Views/Main/NearbyView.swift`

**Components Used:**
- `SectionHeader` - "Restaurants Near You"
- `PrimaryCard` - Restaurant cards
- `PrimaryButton` - "Order Now" buttons
- `SecondaryButton` - "Show Map" button
- `BadgeView` - "X places" count
- Custom budget filter buttons ($, $$, $$$)

**Key Sections:**
- Header with location
- Budget filter buttons
- "Show Map" button
- Restaurant list with cards

**Sub-Views:**
- `MapViewPlaceholder` - Modal for map view

**Design System Elements:**
- Font: h1 (24pt medium) for title
- Font: h3 (18pt medium) for restaurant names
- Font: label (16pt medium) for budget filters
- Button padding: 12px
- Button corner radius: 8px
- Card padding: 16px

---

### 4. **ProfileView**
**File:** `Views/Main/ProfileView.swift`

**Components Used:**
- `SectionHeader` - "Goals & Preferences", "App Settings", "Account"
- `InteractiveCard` - All settings/goals rows
- `PrimaryButton` - (via NavigationLink)
- Custom premium banner (gradient button)
- Custom sign out button

**Key Sections:**
- Profile header (avatar, name, email)
- Premium upgrade banner
- Goals & Preferences (3 rows)
- App Settings (3 rows)
- Account section (Personal Info, Sign Out)
- App version text

**Sub-Views:**
- `PremiumView` - Modal for premium features

**Design System Elements:**
- Font: h2 (20pt medium) for name
- Font: h3 (18pt medium) for row titles
- Font: h3 (18pt medium) for premium banner
- Card padding: 16px
- Card corner radius: 10px
- Button corner radius: 8px for icon backgrounds

---

### 5. **ActivitiesView**
**File:** `Views/Main/ActivitiesView.swift`

**Components Used:**
- `SectionHeader` - "Your Hobbies", "Your Badges", "Activity Impact"
- `PrimaryCard` - HealthKit card, hobby cards, badge cards, activity impact card
- `StatRing` - Steps progress ring
- `BadgeView` - "X selected" count
- `HealthKitPermissionCard` - Permission request card

**Key Sections:**
- Header with description
- HealthKit status card (or permission card)
- Hobbies grid (2 columns)
- Badges horizontal scroll
- Activity Impact card

**Sub-Views:**
- `HealthKitPermissionView` - Modal for HealthKit setup

**Design System Elements:**
- Font: h1 (24pt medium) for title
- Font: input (16pt regular) for hobby names
- Font: h3 (18pt medium) for stat values
- Card padding: 16px
- Card corner radius: 10px

---

### 6. **CycleView** (Cycle-Aware Nutrition)
**File:** `Views/Main/CycleView.swift`

**Components Used:**
- `PrimaryCard` - Phase card, adjustments card, tips card
- `SectionHeader` - "Adjusted Nutrition Goals", "Cycle Nutrition Tips"
- `PrimaryButton` - "Get Started", "Save"
- `InteractiveCard` - HealthKit sync card
- `AdjustmentRow` - Nutrition adjustment rows
- `CyclePhaseButton` - Phase selection buttons
- `CycleProgressIndicator` - Phase dots

**Key Sections:**
- Cycle Phase Card (or "Track Your Cycle" card)
- Nutrition Adjustments Card
- Cycle Tips Card
- HealthKit Sync Card (if female)

**Sub-Views:**
- `CycleEditorView` - Modal for cycle tracking setup
- `CyclePhaseCard` - Current phase display
- `NoCycleDataCard` - Empty state
- `CycleNutritionAdjustments` - Adjusted goals
- `CycleTipsCard` - Phase-specific tips
- `HealthKitCycleSyncCard` - Sync button

**Design System Elements:**
- Font: h1 (24pt medium) for "Track Your Cycle"
- Font: h2 (20pt medium) for phase names
- Font: h3 (18pt medium) for adjustment labels
- Font: input (16pt regular) for descriptions
- Card padding: 16px
- Card corner radius: 10px
- Button corner radius: 8px

---

### 7. **BudgetView** (Budget Tracker)
**File:** `Views/Main/BudgetView.swift`

**Components Used:**
- `SectionHeader` - "This Week's Spending", "Recent Expenses", "Budget Tips"
- `PrimaryCard` - Budget summary, spending chart, expense rows, tips card
- `ProgressBar` - Budget progress bar
- `PrimaryButton` - "Save Budget"
- `BudgetPresetButton` - Quick budget amount buttons

**Key Sections:**
- Budget Summary Card (weekly budget, remaining, progress)
- Weekly Spending Chart (bar chart)
- Recent Expenses list
- Budget Tips Card

**Sub-Views:**
- `BudgetEditorView` - Modal for editing budget
- `BudgetSummaryCard` - Main budget display
- `WeeklySpendingChart` - Bar chart
- `ExpenseRow` - Individual expense item
- `EmptyExpensesView` - Empty state
- `BudgetTipsCard` - Tips list

**Design System Elements:**
- Font: h1 (24pt medium) for budget amounts
- Font: h3 (18pt medium) for expense names
- Font: label (16pt medium) for labels
- Card padding: 16px
- Card corner radius: 10px
- Button padding: 12px
- Button corner radius: 8px

---

## 🔐 Authentication Screens

### 8. **LoginView**
**File:** `Views/Auth/LoginView.swift`

**Components Used:**
- `PrimaryButton` - "Sign In" / "Sign Up"
- `TextButton` - Toggle login/signup, "Continue as Guest"
- Custom text fields (email, password)
- Custom app icon display

**Key Sections:**
- App icon with badge
- App name and tagline
- Email input field
- Password input field
- Primary action button
- Toggle login/signup link
- Guest access link
- Disclaimer text

**Design System Elements:**
- Font: h1 (24pt medium) for "NutriNav"
- Font: input (16pt regular) for text fields
- Font: label (16pt medium) for field labels
- Input background: #f3f3f5
- Button padding: 12px
- Button corner radius: 8px

---

## 🎯 Onboarding Screens

### 9. **OnboardingWelcomeView**
**File:** `Views/Onboarding/OnboardingWelcomeView.swift`

**Components Used:**
- `PrimaryButton` - "Get Started"
- `SecondaryButton` - "Sign In"
- `FeatureCard` - Feature list items

**Key Sections:**
- App icon
- App name
- Tagline
- Feature cards (3 items)
- CTA buttons
- Terms disclaimer

**Design System Elements:**
- Font: h1 (24pt medium) for "NutriNav"
- Font: h3 (18pt medium) for feature titles
- Font: input (16pt regular) for tagline
- Background: Light green (#F1F8F4)

---

### 10. **OnboardingPersonalInfoView**
**File:** `Views/Onboarding/OnboardingPersonalInfoView.swift`

**Components Used:**
- `PrimaryButton` - Continue button
- Custom input fields
- Custom pickers/selectors

**Design System Elements:**
- Font: h1 (24pt medium) for title
- Font: input (16pt regular) for inputs
- Input background: #f3f3f5

---

### 11. **OnboardingStatsView**
**File:** `Views/Onboarding/OnboardingStatsView.swift`

**Components Used:**
- `PrimaryButton` - Continue button
- Custom input fields for height/weight

**Design System Elements:**
- Font: h1 (24pt medium) for title
- Font: input (16pt regular) for inputs

---

### 12. **OnboardingActivityView**
**File:** `Views/Onboarding/OnboardingActivityView.swift`

**Components Used:**
- `PrimaryButton` - Continue button
- Custom activity level selectors

**Design System Elements:**
- Font: h1 (24pt medium) for title
- Font: h3 (18pt medium) for activity options

---

### 13. **OnboardingGoalView**
**File:** `Views/Onboarding/OnboardingGoalView.swift`

**Components Used:**
- `PrimaryButton` - Continue/Finish button
- Custom goal selection cards

**Design System Elements:**
- Font: h1 (24pt medium) for title
- Font: h3 (18pt medium) for goal options

---

## 🧩 Reusable Components

### **DesignSystemComponents.swift**
**File:** `Views/Components/DesignSystemComponents.swift`

**Components Defined:**
1. **PrimaryButton**
   - Green background, white text
   - Padding: 12px
   - Corner radius: 8px (md)
   - Font: 16pt medium

2. **SecondaryButton**
   - White background, green border
   - Padding: 12px
   - Corner radius: 8px (md)
   - Font: 16pt medium

3. **TextButton**
   - Text-only button
   - Font: 16pt medium

4. **PrimaryCard**
   - White background with shadow
   - Padding: 16px (default)
   - Corner radius: 10px (lg)

5. **ProgressBar**
   - Customizable color and height
   - Default height: 8px

6. **StatRing**
   - Circular progress indicator
   - Customizable size and color

7. **BadgeView**
   - Pill-shaped badge
   - Corner radius: 6px (sm)
   - Sizes: small, medium, large

8. **SectionHeader**
   - Title with optional action button
   - Font: 20pt medium (h2)

9. **InteractiveCard**
   - Tappable card wrapper
   - Uses PrimaryCard internally

---

### **HealthKitComponents.swift**
**File:** `Views/Components/HealthKitComponents.swift`

**Components Defined:**
1. **ActivitySummaryCard**
   - Steps, calories, workouts display
   - Used in: ActivitiesView

2. **HealthKitPermissionCard**
   - Permission request card
   - Used in: ActivitiesView

3. **HealthKitPermissionView**
   - Full-screen permission setup
   - Used in: ActivitiesView modal

4. **BenefitRow**
   - Feature list item
   - Used in: HealthKitPermissionView

---

## 🎨 Design System Files

### **DesignSystem.swift**
**File:** `Utilities/DesignSystem.swift`

**Contains:**
- **Colors:**
  - `Color.background` - #ffffff
  - `Color.primary` - #030213
  - `Color.primaryAccent` - #4CAF50 (green)
  - `Color.inputBackground` - #f3f3f5
  - `Color.textPrimary`, `Color.textSecondary`, `Color.textTertiary`
  - Nutrition colors: `calorieColor`, `proteinColor`, etc.

- **Fonts:**
  - `Font.h1` - 24pt, medium
  - `Font.h2` - 20pt, medium
  - `Font.h3` - 18pt, medium
  - `Font.h4` - 16pt, medium
  - `Font.label` - 16pt, medium
  - `Font.button` - 16pt, medium
  - `Font.input` - 16pt, regular

- **Corner Radius:**
  - `Radius.sm` - 6px
  - `Radius.md` - 8px
  - `Radius.lg` - 10px
  - `Radius.xl` - 14px

- **Spacing:**
  - `Spacing.xs` - 4px
  - `Spacing.sm` - 8px
  - `Spacing.md` - 16px
  - `Spacing.lg` - 20px
  - `Spacing.xl` - 24px
  - `Spacing.xxl` - 32px

---

## 📋 Quick Reference: Making Changes

### To Change Text Styles:
1. **Headings:** Update `Font.h1`, `Font.h2`, `Font.h3` in `DesignSystem.swift`
2. **Body Text:** Update `Font.input` in `DesignSystem.swift`
3. **Buttons:** Update `Font.button` in `DesignSystem.swift`

### To Change Colors:
1. **Primary Colors:** Update in `DesignSystem.swift` → `Color` extension
2. **Component Colors:** Update in `DesignSystemComponents.swift`
3. **Screen-Specific Colors:** Update in individual view files

### To Change Spacing:
1. **Global Spacing:** Update `Spacing` struct in `DesignSystem.swift`
2. **Card Padding:** Update `PrimaryCard` default padding (16px)
3. **Button Padding:** Update `PrimaryButton` and `SecondaryButton` (12px)

### To Change Corner Radius:
1. **Global Radius:** Update `Radius` struct in `DesignSystem.swift`
2. **Card Radius:** Update `PrimaryCard` (10px/lg)
3. **Button Radius:** Update button components (8px/md)

### To Add a New Component:
1. Create in `DesignSystemComponents.swift` or appropriate component file
2. Use design system values (colors, fonts, spacing, radius)
3. Add comments indicating design system usage
4. Document in this file

### To Modify a Screen:
1. Find the screen in this guide
2. Locate the file path
3. Check which components are used
4. Review design system elements section
5. Make changes following the design system

---

## 🔍 Screen-by-Screen Consistency Checklist

When reviewing each screen, check:

- [ ] **Fonts:** All text uses correct design system fonts (h1, h2, h3, input, label, button)
- [ ] **Colors:** All colors come from DesignSystem (not hardcoded hex)
- [ ] **Spacing:** Consistent spacing using Spacing constants
- [ ] **Corner Radius:** Cards use lg (10px), buttons use md (8px), badges use sm (6px)
- [ ] **Padding:** Cards use 16px, buttons use 12px
- [ ] **Components:** Using reusable components where possible
- [ ] **Comments:** Design system choices are commented

---

## 📁 File Structure Quick Reference

```
Views/
├── Auth/
│   └── LoginView.swift                    # Login/Sign Up screen
├── Components/
│   ├── DesignSystemComponents.swift      # Reusable UI components
│   └── HealthKitComponents.swift         # HealthKit-specific components
├── Main/
│   ├── MainTabView.swift                 # Tab bar navigation
│   ├── HomeView.swift                    # Dashboard
│   ├── RecipesView.swift                 # Recipe browser
│   ├── NearbyView.swift                  # Restaurant finder
│   ├── ProfileView.swift                 # User profile & settings
│   ├── ActivitiesView.swift              # Hobbies & activities
│   ├── CycleView.swift                   # Cycle-aware nutrition
│   └── BudgetView.swift                  # Budget tracker
└── Onboarding/
    ├── OnboardingWelcomeView.swift      # Welcome screen
    ├── OnboardingPersonalInfoView.swift # Personal info
    ├── OnboardingStatsView.swift        # Height/weight
    ├── OnboardingActivityView.swift     # Activity level
    └── OnboardingGoalView.swift         # Fitness goals

Utilities/
└── DesignSystem.swift                    # Design system definitions
```

---

## 🎯 Common Tasks

### Change a Button Style:
- Edit `PrimaryButton` or `SecondaryButton` in `DesignSystemComponents.swift`

### Change Card Appearance:
- Edit `PrimaryCard` in `DesignSystemComponents.swift`

### Update All Headings:
- Change `Font.h1`, `Font.h2`, `Font.h3` in `DesignSystem.swift`

### Change Primary Accent Color:
- Update `Color.primaryAccent` in `DesignSystem.swift`

### Add a New Screen:
1. Create file in appropriate `Views/` subdirectory
2. Use design system components
3. Add to this navigation guide
4. Update `MainTabView.swift` if it's a main screen

---

**Last Updated:** After design system consistency update
**Design System Version:** Figma-based design system (colors, fonts, spacing, radius)

