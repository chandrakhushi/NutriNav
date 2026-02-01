//
//  ProfileView.swift
//  NutriNav
//
//  Profile screen - using DesignSystem
//

import SwiftUI
import Charts

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPremium = false
    @State private var showEditProfile = false
    @State private var showNutritionGoals = false
    @State private var showSignOutConfirmation = false
    @State private var showLogWeight = false
    @State private var showDietaryPreferences = false
    @State private var showNotifications = false
    @State private var showPrivacy = false
    @State private var showHelp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // Weight Progress Section
                        weightProgressSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Goals Section
                        goalsSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Favorite Recipes Section
                        favoriteRecipesSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Settings Section
                        settingsSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Personal Info
                        personalInfoSection
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
                    .environmentObject(appState)
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    HapticFeedback.impact()
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showLogWeight) {
                LogWeightView()
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Weight Progress Section
    
    private var weightProgressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader(title: "Weight Progress")
                
                Spacer()
                
                Button(action: {
                    showLogWeight = true
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Log")
                            .font(.bodySmall)
                    }
                    .foregroundColor(.primaryAccent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.primaryAccent.opacity(0.1))
                    .cornerRadius(Radius.sm)
                }
            }
            
            PrimaryCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Weight summary stats
                    if !appState.weightHistory.isEmpty {
                        weightSummaryRow
                    }
                    
                    // Chart
                    if appState.weightHistory.count >= 2 {
                        WeightProgressChart(entries: appState.weightHistory)
                            .frame(height: 180)
                    } else {
                        // Empty state
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.textTertiary)
                            
                            Text("Track Your Progress")
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            
                            Text("Log at least 2 weight entries to see your progress chart")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { showLogWeight = true }) {
                                Text("Log Weight")
                                    .font(.input)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.sm)
                                    .background(Color.primaryAccent)
                                    .cornerRadius(Radius.md)
                            }
                            .padding(.top, Spacing.sm)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                    }
                }
            }
        }
    }
    
    private var weightSummaryRow: some View {
        HStack(spacing: Spacing.lg) {
            // Starting weight
            if let startWeight = appState.startingWeight {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Start")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    Text(String(format: "%.1f kg", startWeight))
                        .font(.h3)
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Current weight
            if let currentWeight = appState.currentWeight {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Current")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    Text(String(format: "%.1f kg", currentWeight))
                        .font(.h3)
                        .foregroundColor(.textPrimary)
                }
            }
            
            Spacer()
            
            // Change indicator
            if let change = appState.weightChangeFromStart {
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Change")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: change > 0 ? "arrow.up.right" : (change < 0 ? "arrow.down.right" : "minus"))
                            .font(.system(size: 12, weight: .semibold))
                        Text(String(format: "%+.1f kg", change))
                            .font(.h3)
                    }
                    .foregroundColor(weightChangeColor(change))
                }
            }
        }
    }
    
    private func weightChangeColor(_ change: Double) -> Color {
        guard let goal = appState.user.goal else { return .textSecondary }
        
        switch goal {
        case .loseWeight:
            return change < 0 ? .success : (change > 0 ? .error : .textSecondary)
        case .gainWeight, .buildMuscle:
            return change > 0 ? .success : (change < 0 ? .error : .textSecondary)
        case .maintainWeight:
            return abs(change) < 1.0 ? .success : .calorieColor
        }
    }
    
    // MARK: - Header (Design System: h2=20pt medium, h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private var headerSection: some View {
        VStack(spacing: Spacing.lg) {
            // Profile Info
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(appState.user.name)
                        .font(.h2) // 20pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text(appState.user.email)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            
            // Premium Banner - Tappable
            Button(action: {
                showPremium = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Upgrade to Premium")
                            .font(.h3) // 18pt, medium
                            .foregroundColor(.white)
                        
                        Text("Unlock all features")
                            .font(.bodySmall)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(16) // Card.padding = 16
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF9800"), Color(hex: "FFC107")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Radius.lg) // Card.cornerRadius = Radius.lg (10)
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Goals & Preferences")
            
            Button(action: {
                showNutritionGoals = true
            }) {
                goalRow(
                    title: "Nutrition Goals",
                    subtitle: "\(Int(appState.dailyNutrition.calories.target)) cal, \(Int(appState.dailyNutrition.protein.target))g protein",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color(hex: "FF9800"),
                    action: nil
                )
            }
            .sheet(isPresented: $showNutritionGoals) {
                NutritionGoalsView()
            }
            
            Button(action: {
                showDietaryPreferences = true
            }) {
                goalRow(
                    title: "Dietary Restrictions",
                    subtitle: dietaryRestrictionsSubtitle,
                    icon: "leaf.fill",
                    iconColor: Color(hex: "9C27B0"),
                    action: nil
                )
            }
            .sheet(isPresented: $showDietaryPreferences) {
                DietaryPreferencesView()
                    .environmentObject(appState)
            }
            
            NavigationLink(destination: CycleView().environmentObject(appState)) {
                goalRow(
                    title: "Cycle & Workout Sync",
                    subtitle: "Adapt recommendations",
                    icon: "calendar.badge.clock",
                    iconColor: Color(hex: "E91E63"),
                    action: nil // NavigationLink handles this
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Goal Row (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10, button cornerRadius=md=8)
    private func goalRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        action: (() -> Void)?
    ) -> some View {
        InteractiveCard(action: action) { // Card.padding=16, Card.cornerRadius=lg=10
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.h3) // 18pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    // MARK: - Favorite Recipes Section
    
    private var favoriteRecipesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader(title: "Favorite Recipes")
                
                Spacer()
                
                if !appState.favoriteRecipeIds.isEmpty {
                    NavigationLink(destination: FavoriteRecipesView().environmentObject(appState)) {
                        Text("View All")
                            .font(.input)
                            .foregroundColor(.primaryAccent)
                    }
                }
            }
            
            if appState.favoriteRecipeIds.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "star")
                        .font(.system(size: 32))
                        .foregroundColor(.textTertiary)
                    Text("No favorite recipes yet")
                        .font(.input)
                        .foregroundColor(.textSecondary)
                    Text("Tap the star icon on any recipe to add it here")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.lg)
                .background(Color.inputBackground)
                .cornerRadius(Radius.md)
            } else {
                // Show preview of favorite recipes (first 3)
                FavoriteRecipesPreviewView()
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "App Settings")
            
            // Vacation Mode Toggle
            vacationModeToggle
            
            Button(action: { showNotifications = true }) {
                settingsRowContent(title: "Notifications", icon: "bell.fill", iconColor: Color(hex: "2196F3"))
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsSettingsView()
            }
            
            Button(action: { showPrivacy = true }) {
                settingsRowContent(title: "Privacy & Security", icon: "shield.fill", iconColor: Color(hex: "4CAF50"))
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacySettingsView()
            }
            
            Button(action: { showHelp = true }) {
                settingsRowContent(title: "Help & Support", icon: "questionmark.circle.fill", iconColor: Color(hex: "9E9E9E"))
            }
            .sheet(isPresented: $showHelp) {
                HelpSupportView()
            }
        }
    }
    
    private func settingsRowContent(title: String, icon: String, iconColor: Color) -> some View {
        PrimaryCard {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.h3)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    private var dietaryRestrictionsSubtitle: String {
        if appState.user.dietaryRestrictions.isEmpty {
            return "None set"
        }
        return appState.user.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", ")
    }
    
    private var vacationModeToggle: some View {
        PrimaryCard {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF4081").opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: appState.isVacationMode ? "airplane" : "airplane")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "FF4081"))
                }
                
                Text("Vacation Mode")
                    .font(.h3)
                    .foregroundColor(.textPrimary)
                    .fixedSize(horizontal: true, vertical: false)
                
                Spacer()
                
                Toggle("", isOn: $appState.isVacationMode)
                    .tint(Color(hex: "FF4081"))
                    .scaleEffect(0.9)
            }
        }
    }
    
    // MARK: - Personal Info (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Account")
            
            Button(action: {
                showEditProfile = true
            }) {
                InteractiveCard(action: nil) { // Card.padding=16, Card.cornerRadius=lg=10
                    HStack {
                        Text("Personal Information")
                            .font(.h3) // 18pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            
            Button(action: {
                showSignOutConfirmation = true
            }) {
                Text("Sign Out")
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            
            // App Version
            Text("NutriNav v1.0.0")
                .font(.bodySmall)
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.md)
        }
    }
}

// MARK: - Premium View (Placeholder)

// MARK: - Premium View (Design System: h1=24pt medium, input=16pt regular)
struct PremiumView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        Text("Premium Features")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Text("Unlock all features coming soon")
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
}

// MARK: - Favorite Recipes Preview View
struct FavoriteRecipesPreviewView: View {
    @EnvironmentObject var appState: AppState
    @State private var favoriteRecipes: [RecipeDetail] = []
    @State private var isLoading = true
    @State private var selectedRecipeId: Int? = nil
    
    private let recipeService = RecipeService.shared
    private let maxPreviewCount = 3
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(Spacing.md)
            } else if favoriteRecipes.isEmpty {
                EmptyView()
            } else {
                // Show preview recipes (up to 3)
                ForEach(Array(favoriteRecipes.prefix(maxPreviewCount))) { recipe in
                    favoriteRecipePreviewCard(recipe: recipe)
                }
                
                // Show "View All" if there are more than 3
                if appState.favoriteRecipeIds.count > maxPreviewCount {
                    NavigationLink(destination: FavoriteRecipesView().environmentObject(appState)) {
                        HStack {
                            Text("View \(appState.favoriteRecipeIds.count - maxPreviewCount) more recipe\(appState.favoriteRecipeIds.count - maxPreviewCount == 1 ? "" : "s")")
                                .font(.input)
                                .foregroundColor(.primaryAccent)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textTertiary)
                        }
                        .padding(Spacing.md)
                        .background(Color.inputBackground)
                        .cornerRadius(Radius.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedRecipeId != nil },
            set: { if !$0 { selectedRecipeId = nil } }
        )) {
            if let recipeId = selectedRecipeId {
                RecipeDetailView(recipeId: recipeId)
                    .environmentObject(appState)
            }
        }
        .task {
            loadFavoriteRecipes()
        }
        .onChange(of: appState.favoriteRecipeIds) { oldValue, newValue in
            // Reload when favorites change
            loadFavoriteRecipes()
        }
    }
    
    private func favoriteRecipePreviewCard(recipe: RecipeDetail) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedRecipeId = recipe.id
        }) {
            PrimaryCard {
                HStack(spacing: Spacing.md) {
                    // Recipe Image
                    AsyncImage(url: recipe.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color(hex: "E0E0E0"))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.textTertiary)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(recipe.title)
                            .font(.h3)
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: Spacing.sm) {
                            // Time
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                                Text("\(recipe.readyInMinutes)m")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            // Calories
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.calorieColor)
                                Text("\(Int(recipe.caloriesPerServing)) cal")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Favorite button
                    Button(action: {
                        HapticFeedback.selection()
                        appState.toggleFavoriteRecipe(recipeId: recipe.id)
                        // Remove from local list if unfavorited
                        favoriteRecipes.removeAll { $0.id == recipe.id }
                    }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.yellow)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func loadFavoriteRecipes() {
        Task {
            isLoading = true
            
            var recipes: [RecipeDetail] = []
            
            // Load only the first few recipes for preview
            let recipeIdsToLoad = Array(appState.favoriteRecipeIds.prefix(maxPreviewCount))
            
            for recipeId in recipeIdsToLoad {
                do {
                    if let recipe = try await recipeService.getRecipeDetails(id: recipeId) {
                        recipes.append(recipe)
                    }
                } catch {
                    print("Error loading recipe \(recipeId): \(error)")
                }
            }
            
            await MainActor.run {
                self.favoriteRecipes = recipes
                self.isLoading = false
            }
        }
    }
}

// MARK: - Favorite Recipes View
struct FavoriteRecipesView: View {
    @EnvironmentObject var appState: AppState
    @State private var favoriteRecipes: [RecipeDetail] = []
    @State private var isLoading = true
    @State private var selectedRecipeId: Int? = nil
    
    private let recipeService = RecipeService.shared
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if favoriteRecipes.isEmpty {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "star")
                        .font(.system(size: 64))
                        .foregroundColor(.textTertiary)
                    
                    Text("No Favorite Recipes")
                        .font(.h2)
                        .foregroundColor(.textPrimary)
                    
                    Text("Start favoriting recipes to see them here")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
            } else {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(favoriteRecipes) { recipe in
                            favoriteRecipeCard(recipe: recipe)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.lg)
                }
            }
        }
        .navigationTitle("Favorite Recipes")
        .navigationBarTitleDisplayMode(.large)
        .task {
            loadFavoriteRecipes()
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedRecipeId != nil },
            set: { if !$0 { selectedRecipeId = nil } }
        )) {
            if let recipeId = selectedRecipeId {
                RecipeDetailView(recipeId: recipeId)
                    .environmentObject(appState)
            }
        }
    }
    
    private func favoriteRecipeCard(recipe: RecipeDetail) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedRecipeId = recipe.id
        }) {
            PrimaryCard {
                HStack(spacing: Spacing.md) {
                    // Recipe Image
                    AsyncImage(url: recipe.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color(hex: "E0E0E0"))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(.textTertiary)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(recipe.title)
                            .font(.h3)
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: Spacing.md) {
                            // Time
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                Text("\(recipe.readyInMinutes)m")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            // Calories
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.calorieColor)
                                Text("\(Int(recipe.caloriesPerServing)) cal")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            // Protein
                            if recipe.proteinPerServing > 0 {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 14))
                                        .foregroundColor(.proteinColor)
                                    Text("\(Int(recipe.proteinPerServing))g")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Favorite button
                    Button(action: {
                        HapticFeedback.selection()
                        appState.toggleFavoriteRecipe(recipeId: recipe.id)
                        // Reload to update list
                        Task {
                            await loadFavoriteRecipes()
                        }
                    }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func loadFavoriteRecipes() {
        Task {
            isLoading = true
            
            var recipes: [RecipeDetail] = []
            
            for recipeId in appState.favoriteRecipeIds {
                do {
                    if let recipe = try await recipeService.getRecipeDetails(id: recipeId) {
                        recipes.append(recipe)
                    }
                } catch {
                    print("Error loading recipe \(recipeId): \(error)")
                }
            }
            
            await MainActor.run {
                self.favoriteRecipes = recipes
                self.isLoading = false
            }
        }
    }
}

// MARK: - Weight Progress Chart

struct WeightProgressChart: View {
    let entries: [WeightEntry]
    
    private var displayEntries: [WeightEntry] {
        // Show last 30 days of entries, or all if less
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let filtered = entries.filter { $0.date >= last30Days }
        return filtered.isEmpty ? entries.suffix(10).map { $0 } : filtered
    }
    
    private var yAxisRange: ClosedRange<Double> {
        guard !displayEntries.isEmpty else { return 50...100 }
        let weights = displayEntries.map { $0.weight }
        let minWeight = (weights.min() ?? 50) - 2
        let maxWeight = (weights.max() ?? 100) + 2
        return minWeight...maxWeight
    }
    
    var body: some View {
        Chart {
            ForEach(displayEntries) { entry in
                LineMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primaryAccent, Color.primaryAccent.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                
                AreaMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primaryAccent.opacity(0.3), Color.primaryAccent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Weight", entry.weight)
                )
                .foregroundStyle(Color.primaryAccent)
                .symbolSize(40)
            }
        }
        .chartYScale(domain: yAxisRange)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.textTertiary.opacity(0.3))
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.textTertiary.opacity(0.3))
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text(String(format: "%.0f", weight))
                            .font(.bodySmall)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Log Weight View

struct LogWeightView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var weightValue: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false
    
    private var canSave: Bool {
        guard let weight = Double(weightValue) else { return false }
        return weight > 20 && weight < 300 // Reasonable kg range
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    // Weight Input
                    VStack(spacing: Spacing.md) {
                        Text("Enter Your Weight")
                            .font(.h2)
                            .foregroundColor(.textPrimary)
                        
                        HStack(alignment: .lastTextBaseline, spacing: Spacing.xs) {
                            TextField("0.0", text: $weightValue)
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 160)
                            
                            Text("kg")
                                .font(.h2)
                                .foregroundColor(.textSecondary)
                        }
                        
                        // Show in lbs for reference
                        if let kgValue = Double(weightValue), kgValue > 0 {
                            Text(String(format: "(%.1f lbs)", kgValue * 2.20462))
                                .font(.bodySmall)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .padding(.top, Spacing.xxl)
                    
                    // Date Selector
                    VStack(spacing: Spacing.sm) {
                        Text("Date")
                            .font(.input)
                            .foregroundColor(.textSecondary)
                        
                        Button(action: { showDatePicker.toggle() }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.primaryAccent)
                                
                                Text(selectedDate, style: .date)
                                    .font(.h3)
                                    .foregroundColor(.textPrimary)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(Color.inputBackground)
                            .cornerRadius(Radius.md)
                        }
                        
                        if showDatePicker {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .padding(.horizontal, Spacing.md)
                            .transition(.opacity)
                        }
                    }
                    
                    Spacer()
                    
                    // Recent Entries
                    if !appState.weightHistory.isEmpty {
                        recentEntriesSection
                    }
                    
                    // Save Button
                    Button(action: saveWeight) {
                        Text("Save Weight")
                            .font(.h3)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(canSave ? Color.primaryAccent : Color.textTertiary)
                            .cornerRadius(Radius.md)
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            .onAppear {
                // Pre-fill with current weight if available
                if let currentWeight = appState.user.weight {
                    weightValue = String(format: "%.1f", currentWeight)
                }
            }
        }
    }
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Entries")
                .font(.input)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(appState.weightHistory.suffix(5).reversed()) { entry in
                        VStack(spacing: Spacing.xs) {
                            Text(String(format: "%.1f", entry.weight))
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            Text(entry.date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.inputBackground)
                        .cornerRadius(Radius.md)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    private func saveWeight() {
        guard let weight = Double(weightValue), canSave else { return }
        appState.logWeight(weight, date: selectedDate)
        dismiss()
    }
}

// MARK: - Dietary Preferences View

struct DietaryPreferencesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRestrictions: Set<DietaryRestriction> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header Info
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "9C27B0"))
                            
                            Text("Dietary Preferences")
                                .font(.h1)
                                .foregroundColor(.textPrimary)
                            
                            Text("Select any dietary restrictions to personalize your recipe and meal recommendations")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.lg)
                        }
                        .padding(.top, Spacing.xl)
                        
                        // Restriction Options
                        VStack(spacing: Spacing.sm) {
                            ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                                dietaryOptionRow(restriction)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        Spacer(minLength: Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Dietary Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        appState.user.dietaryRestrictions = Array(selectedRestrictions)
                        HapticFeedback.success()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedRestrictions = Set(appState.user.dietaryRestrictions)
            }
        }
    }
    
    private func dietaryOptionRow(_ restriction: DietaryRestriction) -> some View {
        Button(action: {
            HapticFeedback.selection()
            if selectedRestrictions.contains(restriction) {
                selectedRestrictions.remove(restriction)
            } else {
                selectedRestrictions.insert(restriction)
            }
        }) {
            HStack {
                Image(systemName: iconFor(restriction))
                    .font(.system(size: 24))
                    .foregroundColor(selectedRestrictions.contains(restriction) ? .white : Color(hex: "9C27B0"))
                    .frame(width: 44, height: 44)
                    .background(
                        selectedRestrictions.contains(restriction)
                            ? Color(hex: "9C27B0")
                            : Color(hex: "9C27B0").opacity(0.1)
                    )
                    .cornerRadius(Radius.md)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(restriction.rawValue)
                        .font(.h3)
                        .foregroundColor(.textPrimary)
                    
                    Text(descriptionFor(restriction))
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: selectedRestrictions.contains(restriction) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(selectedRestrictions.contains(restriction) ? Color(hex: "9C27B0") : .textTertiary)
            }
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(
                        selectedRestrictions.contains(restriction) ? Color(hex: "9C27B0") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
    
    private func iconFor(_ restriction: DietaryRestriction) -> String {
        switch restriction {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.arrow.triangle.circlepath"
        case .glutenFree: return "xmark.circle.fill"
        case .dairyFree: return "drop.fill"
        case .keto: return "flame.fill"
        case .paleo: return "figure.walk"
        }
    }
    
    private func descriptionFor(_ restriction: DietaryRestriction) -> String {
        switch restriction {
        case .vegetarian: return "No meat or fish"
        case .vegan: return "No animal products"
        case .glutenFree: return "No wheat, barley, or rye"
        case .dairyFree: return "No milk or dairy products"
        case .keto: return "Low carb, high fat"
        case .paleo: return "Whole foods, no grains"
        }
    }
}

// MARK: - Notifications Settings View

struct NotificationsSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var mealReminders = true
    @State private var waterReminders = true
    @State private var weightReminders = false
    @State private var workoutReminders = true
    @State private var weeklyDigest = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Info Banner
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "2196F3"))
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Stay on Track")
                                    .font(.h3)
                                    .foregroundColor(.textPrimary)
                                Text("Enable reminders to help you reach your goals")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.md)
                        .background(Color(hex: "2196F3").opacity(0.1))
                        .cornerRadius(Radius.lg)
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        
                        // Notification Toggles
                        VStack(spacing: 0) {
                            notificationToggle(
                                title: "Meal Reminders",
                                subtitle: "Breakfast, lunch, dinner reminders",
                                icon: "fork.knife",
                                isOn: $mealReminders
                            )
                            
                            Divider().padding(.leading, 60)
                            
                            notificationToggle(
                                title: "Water Reminders",
                                subtitle: "Stay hydrated throughout the day",
                                icon: "drop.fill",
                                isOn: $waterReminders
                            )
                            
                            Divider().padding(.leading, 60)
                            
                            notificationToggle(
                                title: "Weight Check-ins",
                                subtitle: "Weekly weight logging reminder",
                                icon: "scalemass.fill",
                                isOn: $weightReminders
                            )
                            
                            Divider().padding(.leading, 60)
                            
                            notificationToggle(
                                title: "Workout Suggestions",
                                subtitle: "Daily activity recommendations",
                                icon: "figure.run",
                                isOn: $workoutReminders
                            )
                            
                            Divider().padding(.leading, 60)
                            
                            notificationToggle(
                                title: "Weekly Digest",
                                subtitle: "Summary of your progress",
                                icon: "chart.bar.fill",
                                isOn: $weeklyDigest
                            )
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(Radius.lg)
                        .padding(.horizontal, Spacing.md)
                        
                        // Note
                        Text("Notification preferences are saved locally. Enable notifications in iOS Settings to receive alerts.")
                            .font(.bodySmall)
                            .foregroundColor(.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.md)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    private func notificationToggle(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "2196F3"))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.input)
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(Color(hex: "2196F3"))
        }
        .padding(Spacing.md)
    }
}

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var shareWithHealthKit = true
    @State private var anonymousAnalytics = true
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Privacy Header
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "4CAF50"))
                            
                            Text("Your Privacy Matters")
                                .font(.h2)
                                .foregroundColor(.textPrimary)
                            
                            Text("We take your privacy seriously. Your data is stored locally on your device.")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.lg)
                        }
                        .padding(.top, Spacing.xl)
                        
                        // Data Sharing Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Data Sharing")
                                .font(.input)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: 0) {
                                privacyToggle(
                                    title: "Apple Health Sync",
                                    subtitle: "Share steps, workouts, and weight",
                                    icon: "heart.fill",
                                    iconColor: .error,
                                    isOn: $shareWithHealthKit
                                )
                                
                                Divider().padding(.leading, 60)
                                
                                privacyToggle(
                                    title: "Anonymous Analytics",
                                    subtitle: "Help us improve the app",
                                    icon: "chart.pie.fill",
                                    iconColor: Color(hex: "FF9800"),
                                    isOn: $anonymousAnalytics
                                )
                            }
                            .background(Color.cardBackground)
                            .cornerRadius(Radius.lg)
                            .padding(.horizontal, Spacing.md)
                        }
                        
                        // Data Storage Info
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Data Storage")
                                .font(.input)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: Spacing.md) {
                                infoRow(icon: "iphone", title: "Local Storage", subtitle: "All data stored on device")
                                infoRow(icon: "lock.fill", title: "Encrypted", subtitle: "Protected by iOS security")
                                infoRow(icon: "icloud.slash", title: "No Cloud Sync", subtitle: "Data never leaves your device")
                            }
                            .padding(Spacing.md)
                            .background(Color.cardBackground)
                            .cornerRadius(Radius.lg)
                            .padding(.horizontal, Spacing.md)
                        }
                        
                        // Danger Zone
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Danger Zone")
                                .font(.input)
                                .foregroundColor(.error)
                                .padding(.horizontal, Spacing.md)
                            
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.error)
                                    Text("Delete All Data")
                                        .foregroundColor(.error)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.error.opacity(0.5))
                                }
                                .padding(Spacing.md)
                                .background(Color.error.opacity(0.1))
                                .cornerRadius(Radius.lg)
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                        .padding(.top, Spacing.lg)
                    }
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
            .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // This would clear all data
                    HapticFeedback.error()
                }
            } message: {
                Text("This will permanently delete all your food logs, weight history, and preferences. This action cannot be undone.")
            }
        }
    }
    
    private func privacyToggle(title: String, subtitle: String, icon: String, iconColor: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.input)
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(Color(hex: "4CAF50"))
        }
        .padding(Spacing.md)
    }
    
    private func infoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "4CAF50"))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.input)
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Help & Support View

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Support Header
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(Color(hex: "9E9E9E"))
                            
                            Text("How can we help?")
                                .font(.h1)
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.top, Spacing.xl)
                        
                        // FAQ Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Frequently Asked Questions")
                                .font(.input)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: 0) {
                                faqRow(question: "How are my calorie goals calculated?", answer: "We use the Mifflin-St Jeor equation based on your age, height, weight, and activity level.")
                                
                                Divider().padding(.leading, Spacing.md)
                                
                                faqRow(question: "Can I sync with Apple Health?", answer: "Yes! Go to Settings > Privacy & Security to enable HealthKit sync.")
                                
                                Divider().padding(.leading, Spacing.md)
                                
                                faqRow(question: "How do I log custom foods?", answer: "Tap the + button on the Home screen and use 'Quick Add' to enter custom nutrition values.")
                                
                                Divider().padding(.leading, Spacing.md)
                                
                                faqRow(question: "Is my data private?", answer: "Yes! All your data is stored locally on your device and never shared.")
                            }
                            .background(Color.cardBackground)
                            .cornerRadius(Radius.lg)
                            .padding(.horizontal, Spacing.md)
                        }
                        
                        // Contact Options
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Get in Touch")
                                .font(.input)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: Spacing.sm) {
                                contactButton(
                                    icon: "envelope.fill",
                                    title: "Email Support",
                                    subtitle: "support@nutrinav.app",
                                    color: Color(hex: "2196F3")
                                )
                                
                                contactButton(
                                    icon: "star.fill",
                                    title: "Rate the App",
                                    subtitle: "Help us reach more users",
                                    color: Color(hex: "FF9800")
                                )
                                
                                contactButton(
                                    icon: "doc.text.fill",
                                    title: "Terms of Service",
                                    subtitle: "Legal information",
                                    color: Color(hex: "9E9E9E")
                                )
                                
                                contactButton(
                                    icon: "hand.raised.fill",
                                    title: "Privacy Policy",
                                    subtitle: "How we handle your data",
                                    color: Color(hex: "4CAF50")
                                )
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                        
                        // App Info
                        VStack(spacing: Spacing.xs) {
                            Text("NutriNav")
                                .font(.h3)
                                .foregroundColor(.textPrimary)
                            Text("Version 1.0.0")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            Text("Made with ❤️ for your health")
                                .font(.bodySmall)
                                .foregroundColor(.textTertiary)
                        }
                        .padding(.top, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    @State private var expandedFAQ: String? = nil
    
    private func faqRow(question: String, answer: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedFAQ = expandedFAQ == question ? nil : question
            }
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(question)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: expandedFAQ == question ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                }
                
                if expandedFAQ == question {
                    Text(answer)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(Spacing.md)
        }
    }
    
    private func contactButton(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button(action: {
            HapticFeedback.selection()
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .cornerRadius(Radius.md)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.textTertiary)
            }
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(Radius.lg)
        }
    }
}

