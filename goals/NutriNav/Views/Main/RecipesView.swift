//
//  RecipesView.swift
//  NutriNav
//
//  Recipes screen - using DesignSystem and Spoonacular API
//

import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var appState: AppState
    let initialMealType: MealType?
    
    @State private var searchText = ""
    @State private var searchResults: [RecipeSearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @State private var selectedRecipe: RecipeSearchResult? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    
    private let recipeService = RecipeService.shared
    
    init(initialMealType: MealType? = nil) {
        self.initialMealType = initialMealType
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // Search Bar
                        searchBar
                            .padding(.horizontal, Spacing.md)
                        
                        // Search Results or Empty State
                        if !searchText.isEmpty {
                            searchResultsSection
                                .padding(.horizontal, Spacing.md)
                        } else {
                            emptyStateSection
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationDestination(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipeId: recipe.id, initialMealType: initialMealType)
                    .environmentObject(appState)
            }
            .task {
                // Check if API key is set
                if !recipeService.hasAPIKey() {
                    searchError = "API key required. Please set your Spoonacular API key in settings."
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text("Recipes")
                    .font(.h1)
                    .foregroundColor(.textPrimary)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 24))
                    .foregroundColor(.primaryAccent)
            }
            
            Text("Search for healthy recipes")
                .font(.input)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            
            TextField("Search recipes...", text: $searchText)
                .font(.input)
                .foregroundColor(.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { oldValue, newValue in
                    performSearch(query: newValue)
                }
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                    searchError = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.inputBackground)
        .cornerRadius(Radius.md)
    }
    
    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = searchError {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.textTertiary)
                    Text("Error: \(error)")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.textTertiary)
                    Text("No recipes found")
                        .font(.input)
                        .foregroundColor(.textSecondary)
                    Text("Try a different search term")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
                .padding()
            } else {
                Text("\(searchResults.count) recipes found")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                
                ForEach(searchResults) { recipe in
                    recipeCard(recipe: recipe)
                }
            }
        }
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "book.fill")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)
            
            Text("Search for Recipes")
                .font(.h2)
                .foregroundColor(.textPrimary)
            
            Text("Enter a keyword to find delicious recipes with nutrition information")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .padding(.top, Spacing.xxl)
    }
    
    // MARK: - Recipe Card
    private func recipeCard(recipe: RecipeSearchResult) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedRecipe = recipe
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
                                Text("\(recipe.displayCalories) cal")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            // Protein
                            if recipe.displayProtein > 0 {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 14))
                                        .foregroundColor(.proteinColor)
                                    Text("\(recipe.displayProtein)g")
                                        .font(.bodySmall)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Search Function
    private func performSearch(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        // Clear results if query is empty
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            searchError = nil
            isSearching = false
            return
        }
        
        // Set loading state
        isSearching = true
        searchError = nil
        
        // Debounce search (wait 0.5 seconds after user stops typing)
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            do {
                let results = try await recipeService.searchRecipes(query: query)
                
                // Check if task was cancelled before updating UI
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                    self.searchError = nil
                }
            } catch {
                // Check if task was cancelled before updating UI
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.searchError = error.localizedDescription
                    self.isSearching = false
                    self.searchResults = []
                }
            }
        }
    }
}

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let recipeId: Int
    let initialMealType: MealType?
    
    @State private var recipeDetail: RecipeDetail? = nil
    @State private var isLoading = true
    @State private var error: String? = nil
    @State private var showLogRecipeSheet = false
    @State private var selectedMealType: MealType = .breakfast
    
    private let recipeService = RecipeService.shared
    
    init(recipeId: Int, initialMealType: MealType? = nil) {
        self.recipeId = recipeId
        self.initialMealType = initialMealType
        _selectedMealType = State(initialValue: initialMealType ?? .breakfast)
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let error = error {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.textTertiary)
                    Text("Error loading recipe")
                        .font(.h2)
                        .foregroundColor(.textPrimary)
                    Text(error)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                    
                    PrimaryButton(
                        title: "Retry",
                        action: {
                            loadRecipeDetails()
                        }
                    )
                    .padding(.horizontal, Spacing.xl)
                }
            } else if let recipe = recipeDetail {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Recipe Image
                        AsyncImage(url: recipe.imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(hex: "E0E0E0"))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundColor(.textTertiary)
                                )
                        }
                        .frame(height: 250)
                        .clipped()
                        
                        // Recipe Info
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            // Title
                            Text(recipe.title)
                                .font(.h1)
                                .foregroundColor(.textPrimary)
                            
                            // Quick Stats
                            HStack(spacing: Spacing.lg) {
                                statItem(icon: "clock", value: "\(recipe.readyInMinutes)m", label: "Time")
                                statItem(icon: "person.2", value: "\(recipe.servings)", label: "Servings")
                                statItem(icon: "flame.fill", value: "\(Int(recipe.caloriesPerServing))", label: "Cal")
                                if recipe.proteinPerServing > 0 {
                                    statItem(icon: "figure.strengthtraining.traditional", value: "\(Int(recipe.proteinPerServing))g", label: "Protein")
                                }
                            }
                            .padding(.top, Spacing.sm)
                            
                            // Summary
                            if let summary = recipe.summary, !summary.isEmpty {
                                Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                                    .font(.input)
                                    .foregroundColor(.textSecondary)
                                    .padding(.top, Spacing.sm)
                            }
                            
                            Divider()
                                .padding(.vertical, Spacing.md)
                            
                            // Ingredients
                            if !recipe.extendedIngredients.isEmpty {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Ingredients")
                                        .font(.h2)
                                        .foregroundColor(.textPrimary)
                                    
                                    ForEach(recipe.extendedIngredients, id: \.id) { ingredient in
                                        HStack(alignment: .top, spacing: Spacing.sm) {
                                            Text("•")
                                                .foregroundColor(.textSecondary)
                                            Text(ingredient.original)
                                                .font(.input)
                                                .foregroundColor(.textPrimary)
                                        }
                                    }
                                }
                                .padding(.top, Spacing.sm)
                                
                                Divider()
                                    .padding(.vertical, Spacing.md)
                            }
                            
                            // Instructions
                            if !recipe.instructionSteps.isEmpty {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text("Instructions")
                                        .font(.h2)
                                        .foregroundColor(.textPrimary)
                                    
                                    ForEach(Array(recipe.instructionSteps.enumerated()), id: \.offset) { index, step in
                                        HStack(alignment: .top, spacing: Spacing.sm) {
                                            Text("\(index + 1).")
                                                .font(.input)
                                                .foregroundColor(.primaryAccent)
                                                .frame(width: 30, alignment: .leading)
                                            Text(step)
                                                .font(.input)
                                                .foregroundColor(.textPrimary)
                                        }
                                        .padding(.bottom, Spacing.xs)
                                    }
                                }
                                .padding(.top, Spacing.sm)
                            }
                            
                            // Log Recipe Button
                            PrimaryButton(
                                title: "Log Recipe",
                                action: {
                                    HapticFeedback.selection()
                                    showLogRecipeSheet = true
                                },
                                icon: "plus.circle.fill"
                            )
                            .padding(.top, Spacing.lg)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let initialMealType = initialMealType {
                selectedMealType = initialMealType
            }
            loadRecipeDetails()
        }
        .sheet(isPresented: $showLogRecipeSheet) {
            LogRecipeMealSelectionView(
                recipe: recipeDetail!,
                selectedMealType: $selectedMealType
            )
            .environmentObject(appState)
        }
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primaryAccent)
            Text(value)
                .font(.input)
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func loadRecipeDetails() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let detail = try await recipeService.getRecipeDetails(id: recipeId)
                await MainActor.run {
                    self.recipeDetail = detail
                    self.isLoading = false
                    if detail == nil {
                        self.error = "Recipe not found"
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Log Recipe Meal Selection View
struct LogRecipeMealSelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let recipe: RecipeDetail
    @Binding var selectedMealType: MealType
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Recipe Summary
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text(recipe.title)
                                    .font(.h2)
                                    .foregroundColor(.textPrimary)
                                
                                HStack(spacing: Spacing.lg) {
                                    nutritionItem(label: "Calories", value: "\(Int(recipe.caloriesPerServing))")
                                    nutritionItem(label: "Protein", value: "\(Int(recipe.proteinPerServing))g")
                                    nutritionItem(label: "Carbs", value: "\(Int(recipe.carbsPerServing))g")
                                    nutritionItem(label: "Fat", value: "\(Int(recipe.fatPerServing))g")
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        
                        // Meal Type Selection
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Add to Meal")
                                    .font(.h3)
                                    .foregroundColor(.textPrimary)
                                
                                VStack(spacing: Spacing.sm) {
                                    HStack(spacing: Spacing.sm) {
                                        mealTypeButton(.breakfast)
                                        mealTypeButton(.lunch)
                                    }
                                    HStack(spacing: Spacing.sm) {
                                        mealTypeButton(.dinner)
                                        mealTypeButton(.snacks)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        // Log Button
                        PrimaryButton(
                            title: "Log to \(selectedMealType.rawValue)",
                            action: {
                                logRecipe()
                            },
                            icon: "checkmark.circle.fill"
                        )
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Log Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    private func nutritionItem(label: String, value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.input)
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func mealTypeButton(_ mealType: MealType) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedMealType = mealType
        }) {
            Text(mealType.rawValue)
                .font(.input)
                .foregroundColor(selectedMealType == mealType ? .white : .textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(selectedMealType == mealType ? Color.primaryAccent : Color.inputBackground)
                .cornerRadius(Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(selectedMealType == mealType ? Color.clear : Color.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func logRecipe() {
        // Create FoodEntry from recipe
        let entry = FoodEntry(
            name: recipe.title,
            source: .manual, // Recipes are logged as manual entries
            calories: recipe.caloriesPerServing,
            protein: recipe.proteinPerServing,
            carbs: recipe.carbsPerServing,
            fats: recipe.fatPerServing,
            servingSize: "1 serving",
            mealType: selectedMealType
        )
        
        // Add to food log
        appState.addFoodEntry(entry)
        
        HapticFeedback.success()
        dismiss()
    }
}

