//
//  ProfileView.swift
//  NutriNav
//
//  Profile screen - using DesignSystem
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPremium = false
    @State private var showEditProfile = false
    @State private var showNutritionGoals = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
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
                    // TODO: Implement sign out logic
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
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
            
            goalRow(
                title: "Dietary Restrictions",
                subtitle: "Gluten-free, Vegetarian",
                icon: "leaf.fill",
                iconColor: Color(hex: "9C27B0"),
                action: {
                    // TODO: Navigate to dietary preferences
                }
            )
            
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
            
            settingsRow(title: "Notifications", icon: "bell.fill", iconColor: Color(hex: "2196F3")) {
                // TODO: Navigate to notifications settings
            }
            
            settingsRow(title: "Privacy & Security", icon: "shield.fill", iconColor: Color(hex: "4CAF50")) {
                // TODO: Navigate to privacy settings
            }
            
            settingsRow(title: "Help & Support", icon: "questionmark.circle.fill", iconColor: Color(hex: "9E9E9E")) {
                // TODO: Navigate to help & support
            }
        }
    }
    
    // MARK: - Settings Row (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private func settingsRow(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        InteractiveCard(action: action) { // Card.padding=16, Card.cornerRadius=lg=10
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
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
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
