# UI Consistency Audit Report

## Issues Found

### 1. Non-Functional Buttons (Empty Actions)
- **HomeView.swift** (Line 97): "X% Complete" button - Should show nutrition details or be disabled
- **HomeView.swift** (Line 383): Crown icon button - Should navigate to premium or be disabled
- **ProfileView.swift** (Line 65): Premium upgrade banner - Should navigate to subscription screen or be disabled
- **ProfileView.swift** (Line 237): Sign Out button - Should have actual sign out logic
- **NearbyView.swift** (Line 69): "Show Map" button - Should show map view or be disabled
- **RecipesView.swift** (Line 113): Recipe count button - Should filter or be disabled

### 2. Inconsistent Colors
- MainTabView uses `.appPurple` instead of `.primaryAccent`
- Multiple views use old color system (appPurple, appPink, appOrange)
- Need to migrate all to DesignSystem colors

### 3. Inconsistent Button Styles
- Mix of custom buttons and system buttons
- No consistent disabled states
- Missing haptic feedback

### 4. Inconsistent Card Styles
- Some use custom styling, some don't
- Shadow inconsistencies
- Padding inconsistencies

### 5. Typography Inconsistencies
- Mix of system fonts and custom sizes
- Not using DesignSystem typography scale

## Fix Plan

1. Update MainTabView to use DesignSystem
2. Fix all empty button actions (wire or disable)
3. Apply DesignSystem components to all views
4. Add haptic feedback to all interactions
5. Ensure consistent spacing and styling

