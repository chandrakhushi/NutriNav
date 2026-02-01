//
//  RecipesView.swift
//  NutriNav
//
//  Recipes screen - using DesignSystem and Spoonacular API
//

import SwiftUI
import UIKit

// MARK: - Recipe Category
enum RecipeCategory: String, CaseIterable {
    case all = "All"
    case mainCourse = "Main Course"
    case dessert = "Dessert"
    case appetizer = "Appetizer"
    case salad = "Salad"
    case soup = "Soup"
    case breakfast = "Breakfast"
    case beverage = "Beverage"
    case sideDish = "Side Dish"
    
    var apiValue: String? {
        switch self {
        case .all: return nil
        case .mainCourse: return "main course"
        case .dessert: return "dessert"
        case .appetizer: return "appetizer"
        case .salad: return "salad"
        case .soup: return "soup"
        case .breakfast: return "breakfast"
        case .beverage: return "beverage"
        case .sideDish: return "side dish"
        }
    }
}

struct RecipesView: View {
    @EnvironmentObject var appState: AppState
    let initialMealType: MealType?
    
    @State private var searchText = ""
    @State private var searchResults: [RecipeSearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @State private var selectedRecipe: RecipeSearchResult? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var selectedCategory: RecipeCategory = .all
    @State private var showFilters = false
    @State private var filters = RecipeFilters()
    
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
                        
                        // Categories
                        categoriesSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Filters Button
                        if !searchText.isEmpty {
                            filtersButton
                                .padding(.horizontal, Spacing.md)
                        }
                        
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
            .sheet(isPresented: $showFilters) {
                RecipeFiltersView(filters: $filters) {
                    performSearch(query: searchText)
                }
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
                    filters = RecipeFilters()
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
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(RecipeCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        performSearch(query: searchText)
                    }
                }
            }
            .padding(.leading, Spacing.md)
            .padding(.trailing, Spacing.md)
        }
    }
    
    // MARK: - Filters Button
    private var filtersButton: some View {
        HStack {
            Button(action: {
                showFilters = true
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                    Text("Filters")
                        .font(.input)
                    
                    if hasActiveFilters {
                        BadgeView(text: "\(activeFilterCount)", color: .primaryAccent, size: .small)
                    }
                }
                .foregroundColor(.primaryAccent)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.primaryAccent.opacity(0.1))
                .cornerRadius(Radius.md)
            }
            
            Spacer()
        }
    }
    
    private var hasActiveFilters: Bool {
        filters.maxReadyTime != nil ||
        filters.minCalories != nil ||
        filters.maxCalories != nil ||
        filters.minProtein != nil ||
        filters.maxProtein != nil ||
        filters.diet != nil
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if filters.maxReadyTime != nil { count += 1 }
        if filters.minCalories != nil || filters.maxCalories != nil { count += 1 }
        if filters.minProtein != nil || filters.maxProtein != nil { count += 1 }
        if filters.diet != nil { count += 1 }
        return count
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
                    Text("Try a different search term or adjust filters")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
                .padding()
            } else {
                Text("\(searchResults.count) recipes found")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                
                // Grid layout for recipes
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md)
                ], spacing: Spacing.md) {
                    ForEach(searchResults) { recipe in
                        recipeGridCard(recipe: recipe)
                    }
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
                    // Enhanced Recipe Image
                    AsyncImage(url: recipe.imageURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E0E0E0"), Color(hex: "F5F5F5")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ProgressView()
                                        .tint(.primaryAccent)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E0E0E0"), Color(hex: "F5F5F5")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.textTertiary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(recipe.title)
                            .font(.h3)
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: Spacing.sm) {
                            // Time
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                                Text("\(recipe.readyInMinutes)m")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            // Calories - Always show
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.calorieColor)
                                Text(recipe.displayCalories > 0 ? "\(recipe.displayCalories) cal" : "N/A")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            
                            // Protein - Show if available
                            HStack(spacing: 4) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 12))
                                    .foregroundColor(.proteinColor)
                                Text(recipe.displayProtein > 0 ? "\(recipe.displayProtein)g" : "N/A")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
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
    
    // MARK: - Recipe Grid Card (New Grid Layout)
    private func recipeGridCard(recipe: RecipeSearchResult) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedRecipe = recipe
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Recipe Image
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: recipe.imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E8E8E8"), Color(hex: "F5F5F5")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ProgressView()
                                        .tint(.primaryAccent)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E8E8E8"), Color(hex: "F5F5F5")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 28))
                                        .foregroundColor(.textTertiary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 140)
                    .clipped()
                    
                    // Time badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text("\(recipe.readyInMinutes)m")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(Radius.sm)
                    .padding(8)
                }
                
                // Recipe Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(recipe.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: Spacing.sm) {
                        // Calories
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.calorieColor)
                            Text(recipe.displayCalories > 0 ? "\(recipe.displayCalories)" : "-")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                        
                        // Protein
                        HStack(spacing: 2) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 10))
                                .foregroundColor(.proteinColor)
                            Text(recipe.displayProtein > 0 ? "\(recipe.displayProtein)g" : "-")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(Spacing.sm)
            }
            .background(Color.card)
            .cornerRadius(Radius.lg)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
        
        // Apply category to filters
        var searchFilters = filters
        searchFilters.type = selectedCategory.apiValue
        
        // Debounce search (wait 0.5 seconds after user stops typing)
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            do {
                let results = try await recipeService.searchRecipes(query: query, filters: searchFilters)
                
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

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(title)
                .font(.input)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.primaryAccent : Color.inputBackground)
                .cornerRadius(Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recipe Filters View
struct RecipeFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filters: RecipeFilters
    let onApply: () -> Void
    
    @State private var maxReadyTime: String = ""
    @State private var minCalories: String = ""
    @State private var maxCalories: String = ""
    @State private var minProtein: String = ""
    @State private var maxProtein: String = ""
    @State private var selectedDiet: String = ""
    
    let dietOptions = ["", "vegetarian", "vegan", "gluten-free", "keto", "paleo", "dairy-free"]
    
    init(filters: Binding<RecipeFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        
        // Initialize state from filters
        if let maxTime = filters.wrappedValue.maxReadyTime {
            _maxReadyTime = State(initialValue: "\(maxTime)")
        }
        if let minCal = filters.wrappedValue.minCalories {
            _minCalories = State(initialValue: "\(minCal)")
        }
        if let maxCal = filters.wrappedValue.maxCalories {
            _maxCalories = State(initialValue: "\(maxCal)")
        }
        if let minProt = filters.wrappedValue.minProtein {
            _minProtein = State(initialValue: "\(minProt)")
        }
        if let maxProt = filters.wrappedValue.maxProtein {
            _maxProtein = State(initialValue: "\(maxProt)")
        }
        if let diet = filters.wrappedValue.diet {
            _selectedDiet = State(initialValue: diet)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Quick Filters
                        quickFiltersSection
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                        
                        // Time Filter
                        filterSection(title: "Max Cooking Time", icon: "clock") {
                            HStack {
                                TextField("Minutes", text: $maxReadyTime)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("30 min") {
                                    maxReadyTime = "30"
                                }
                                .buttonStyle(.bordered)
                                
                                Button("60 min") {
                                    maxReadyTime = "60"
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        // Calories Filter
                        filterSection(title: "Calories", icon: "flame.fill") {
                            HStack {
                                TextField("Min", text: $minCalories)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                
                                Text("to")
                                    .foregroundColor(.textSecondary)
                                
                                TextField("Max", text: $maxCalories)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        // Protein Filter
                        filterSection(title: "Protein (grams)", icon: "figure.strengthtraining.traditional") {
                            HStack {
                                TextField("Min", text: $minProtein)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                
                                Text("to")
                                    .foregroundColor(.textSecondary)
                                
                                TextField("Max", text: $maxProtein)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        // Diet Filter
                        filterSection(title: "Dietary Restrictions", icon: "leaf.fill") {
                            Picker("Diet", selection: $selectedDiet) {
                                Text("None").tag("")
                                ForEach(dietOptions.filter { !$0.isEmpty }, id: \.self) { diet in
                                    Text(diet.capitalized).tag(diet)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        // Apply Button
                        PrimaryButton(
                            title: "Apply Filters",
                            action: {
                                applyFilters()
                                onApply()
                                dismiss()
                            }
                        )
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        clearFilters()
                    }
                    .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applyFilters()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Filters")
                .font(.h3)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: Spacing.sm) {
                quickFilterButton(title: "Under 30 min", isActive: maxReadyTime == "30") {
                    maxReadyTime = maxReadyTime == "30" ? "" : "30"
                }
                
                quickFilterButton(title: "Under 60 min", isActive: maxReadyTime == "60") {
                    maxReadyTime = maxReadyTime == "60" ? "" : "60"
                }
                
                quickFilterButton(title: "High Protein", isActive: minProtein == "20") {
                    minProtein = minProtein == "20" ? "" : "20"
                }
            }
        }
    }
    
    private func quickFilterButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(title)
                .font(.input)
                .foregroundColor(isActive ? .white : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isActive ? Color.primaryAccent : Color.inputBackground)
                .cornerRadius(Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func filterSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(.primaryAccent)
                Text(title)
                    .font(.h3)
                    .foregroundColor(.textPrimary)
            }
            
            content()
        }
        .padding(Spacing.md)
        .background(Color.inputBackground)
        .cornerRadius(Radius.md)
    }
    
    private func applyFilters() {
        filters.maxReadyTime = Int(maxReadyTime)
        filters.minCalories = Int(minCalories)
        filters.maxCalories = Int(maxCalories)
        filters.minProtein = Int(minProtein)
        filters.maxProtein = Int(maxProtein)
        filters.diet = selectedDiet.isEmpty ? nil : selectedDiet
    }
    
    private func clearFilters() {
        maxReadyTime = ""
        minCalories = ""
        maxCalories = ""
        minProtein = ""
        maxProtein = ""
        selectedDiet = ""
        applyFilters()
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
    @State private var servingMultiplier: Double = 1.0
    @State private var checkedIngredients: Set<Int> = []
    @State private var showIngredients = true
    @State private var showInstructions = true
    @State private var showNutrition = true
    @State private var imageLoadingState: ImageLoadingState = .loading
    
    private let recipeService = RecipeService.shared
    
    enum ImageLoadingState {
        case loading
        case loaded
        case failed
    }
    
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
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Enhanced Hero Image with Gradient Overlay
                        ZStack(alignment: .bottomLeading) {
                            // Recipe Image
                            GeometryReader { geometry in
                                AsyncImage(url: recipe.imageURL) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "E0E0E0"), Color(hex: "F5F5F5")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                ProgressView()
                                                    .tint(.primaryAccent)
                                            )
                                            .onAppear {
                                                imageLoadingState = .loading
                                            }
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .clipped()
                                            .onAppear {
                                                imageLoadingState = .loaded
                                            }
                                    case .failure:
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "E0E0E0"), Color(hex: "F5F5F5")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                VStack(spacing: Spacing.sm) {
                                                    Image(systemName: "photo")
                                                        .font(.system(size: 48))
                                                        .foregroundColor(.textTertiary)
                                                    Text("Image unavailable")
                                                        .font(.bodySmall)
                                                        .foregroundColor(.textSecondary)
                                                }
                                            )
                                            .onAppear {
                                                imageLoadingState = .failed
                                            }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            .frame(height: 350)
                            .clipped()
                            
                            // Gradient Overlay
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Action Buttons (Top Right)
                            HStack(spacing: Spacing.sm) {
                                // Share Button
                                Button(action: {
                                    HapticFeedback.selection()
                                    shareRecipe(recipe)
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(Spacing.sm)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                                
                                // Favorite Button
                                Button(action: {
                                    HapticFeedback.selection()
                                    appState.toggleFavoriteRecipe(recipeId: recipe.id)
                                }) {
                                    Image(systemName: appState.isFavoriteRecipe(recipeId: recipe.id) ? "star.fill" : "star")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(appState.isFavoriteRecipe(recipeId: recipe.id) ? .yellow : .white)
                                        .padding(Spacing.sm)
                                        .background(Color.black.opacity(0.4))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .topTrailing)
                            
                            // Recipe Title Overlay (Bottom)
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(recipe.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                
                                // Quick Stats Overlay
                                HStack(spacing: Spacing.sm) {
                                    statBadge(icon: "clock.fill", text: "\(recipe.readyInMinutes)m")
                                    statBadge(icon: "person.2.fill", text: "\(recipe.servings)")
                                    if recipe.proteinPerServing > 0 {
                                        statBadge(icon: "figure.strengthtraining.traditional", text: "\(Int(recipe.proteinPerServing))g")
                                    }
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.md)
                        }
                        .frame(maxWidth: .infinity)
                        .clipped()
                        
                        // Content Section
                        VStack(spacing: Spacing.lg) {
                            // Quick Stats Cards
                            quickStatsCards(recipe: recipe)
                            
                            // Nutrition Breakdown (Visual)
                            if showNutrition {
                                nutritionBreakdownSection(recipe: recipe)
                            }
                            
                            // Serving Size Adjuster (Enhanced)
                            servingSizeSection(recipe: recipe)
                            
                            // Summary
                            if let summary = recipe.summary, !summary.isEmpty {
                                summarySection(summary: summary)
                            }
                            
                            // Ingredients (Interactive Checklist)
                            if !recipe.extendedIngredients.isEmpty {
                                ingredientsSection(recipe: recipe)
                            }
                            
                            // Instructions (Step-by-step Cards)
                            if !recipe.instructionSteps.isEmpty {
                                instructionsSection(recipe: recipe)
                            }
                            
                            // Action Buttons
                            actionButtonsSection
                        }
                        .padding(Spacing.md)
                        .background(Color.background)
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
                selectedMealType: $selectedMealType,
                servingMultiplier: servingMultiplier
            )
            .environmentObject(appState)
        }
    }
    
    // MARK: - Helper Views
    
    private func statBadge(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.bodySmall)
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.white.opacity(0.2))
        .cornerRadius(Radius.sm)
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
    
    private func quickStatsCards(recipe: RecipeDetail) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.sm) {
            statCard(
                icon: "clock.fill",
                value: "\(recipe.readyInMinutes)",
                label: "Minutes",
                color: .calorieColor
            )
            statCard(
                icon: "person.2.fill",
                value: "\(Int(Double(recipe.servings) * servingMultiplier))",
                label: "Servings",
                color: .proteinColor
            )
            statCard(
                icon: "flame.fill",
                value: "\(Int(recipe.caloriesPerServing * servingMultiplier))",
                label: "Calories",
                color: .calorieColor
            )
            statCard(
                icon: "figure.strengthtraining.traditional",
                value: recipe.proteinPerServing > 0 ? "\(Int(recipe.proteinPerServing * servingMultiplier))g" : "-",
                label: "Protein",
                color: .proteinColor
            )
        }
    }
    
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.h3)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(Color.card)
        .cornerRadius(Radius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func nutritionBreakdownSection(recipe: RecipeDetail) -> some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Nutrition per Serving")
                        .font(.h2)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showNutrition.toggle()
                        }
                    }) {
                        Image(systemName: showNutrition ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                if showNutrition {
                    VStack(spacing: Spacing.md) {
                        nutritionBar(
                            label: "Calories",
                            value: recipe.caloriesPerServing * servingMultiplier,
                            maxValue: 2000,
                            color: .calorieColor,
                            unit: "cal"
                        )
                        
                        nutritionBar(
                            label: "Protein",
                            value: recipe.proteinPerServing * servingMultiplier,
                            maxValue: 150,
                            color: .proteinColor,
                            unit: "g"
                        )
                        
                        nutritionBar(
                            label: "Carbs",
                            value: recipe.carbsPerServing * servingMultiplier,
                            maxValue: 300,
                            color: .carbColor,
                            unit: "g"
                        )
                        
                        nutritionBar(
                            label: "Fat",
                            value: recipe.fatPerServing * servingMultiplier,
                            maxValue: 100,
                            color: .fatColor,
                            unit: "g"
                        )
                    }
                    .padding(.top, Spacing.sm)
                }
            }
        }
    }
    
    private func nutritionBar(label: String, value: Double, maxValue: Double, color: Color, unit: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label)
                    .font(.input)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.input)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.inputBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: min(geometry.size.width * CGFloat(value / maxValue), geometry.size.width),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }
    
    private func servingSizeSection(recipe: RecipeDetail) -> some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Adjust Servings")
                        .font(.h2)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(Double(recipe.servings) * servingMultiplier)) servings")
                        .font(.input)
                        .foregroundColor(.textSecondary)
                }
                
                HStack(spacing: Spacing.md) {
                    Button(action: {
                        if servingMultiplier > 0.25 {
                            withAnimation(.spring(response: 0.3)) {
                                servingMultiplier -= 0.25
                            }
                            HapticFeedback.selection()
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(servingMultiplier > 0.25 ? .primaryAccent : .textTertiary)
                    }
                    .disabled(servingMultiplier <= 0.25)
                    
                    // Slider
                    VStack(spacing: Spacing.xs) {
                        Slider(
                            value: $servingMultiplier,
                            in: 0.25...4.0,
                            step: 0.25
                        ) {
                            Text("Servings")
                        } minimumValueLabel: {
                            Text("0.25x")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        } maximumValueLabel: {
                            Text("4x")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        } onEditingChanged: { editing in
                            if !editing {
                                HapticFeedback.selection()
                            }
                        }
                        .tint(.primaryAccent)
                        
                        Text("\(String(format: "%.2f", servingMultiplier))x")
                            .font(.h3)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Button(action: {
                        if servingMultiplier < 4.0 {
                            withAnimation(.spring(response: 0.3)) {
                                servingMultiplier += 0.25
                            }
                            HapticFeedback.selection()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(servingMultiplier < 4.0 ? .primaryAccent : .textTertiary)
                    }
                    .disabled(servingMultiplier >= 4.0)
                }
            }
        }
    }
    
    private func summarySection(summary: String) -> some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("About This Recipe")
                    .font(.h2)
                    .foregroundColor(.textPrimary)
                
                Text(summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                    .font(.input)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func ingredientsSection(recipe: RecipeDetail) -> some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Ingredients")
                        .font(.h2)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showIngredients.toggle()
                        }
                    }) {
                        Image(systemName: showIngredients ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                if showIngredients {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(recipe.extendedIngredients, id: \.id) { ingredient in
                            ingredientRow(ingredient: ingredient)
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
            }
        }
    }
    
    private func ingredientRow(ingredient: ExtendedIngredient) -> some View {
        let isChecked = checkedIngredients.contains(ingredient.id ?? 0)
        
        return Button(action: {
            HapticFeedback.selection()
            if let id = ingredient.id {
                if isChecked {
                    checkedIngredients.remove(id)
                } else {
                    checkedIngredients.insert(id)
                }
            }
        }) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(isChecked ? Color.primaryAccent : Color.border, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primaryAccent)
                    }
                }
                
                Text(ingredient.original)
                    .font(.input)
                    .foregroundColor(isChecked ? .textSecondary : .textPrimary)
                    .strikethrough(isChecked)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func instructionsSection(recipe: RecipeDetail) -> some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Instructions")
                        .font(.h2)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showInstructions.toggle()
                        }
                    }) {
                        Image(systemName: showInstructions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                if showInstructions {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ForEach(Array(recipe.instructionSteps.enumerated()), id: \.offset) { index, step in
                            instructionStepCard(stepNumber: index + 1, step: step)
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
            }
        }
    }
    
    private func instructionStepCard(stepNumber: Int, step: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Step Number Badge
            ZStack {
                Circle()
                    .fill(Color.primaryAccent)
                    .frame(width: 32, height: 32)
                
                Text("\(stepNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 2) // Align with first line of text
            
            // Step Text
            Text(step)
                .font(.input)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.bottom, Spacing.sm)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: Spacing.md) {
            PrimaryButton(
                title: "Log Recipe",
                action: {
                    HapticFeedback.selection()
                    showLogRecipeSheet = true
                },
                icon: "plus.circle.fill"
            )
        }
    }
    
    private func shareRecipe(_ recipe: RecipeDetail) {
        let text = "Check out this recipe: \(recipe.title)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
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
    let servingMultiplier: Double
    
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
                                    nutritionItem(label: "Calories", value: "\(Int(recipe.caloriesPerServing * servingMultiplier))")
                                    nutritionItem(label: "Protein", value: "\(Int(recipe.proteinPerServing * servingMultiplier))g")
                                    nutritionItem(label: "Carbs", value: "\(Int(recipe.carbsPerServing * servingMultiplier))g")
                                    nutritionItem(label: "Fat", value: "\(Int(recipe.fatPerServing * servingMultiplier))g")
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
        // Create FoodEntry from recipe with serving multiplier
        let entry = FoodEntry(
            name: recipe.title,
            source: .manual, // Recipes are logged as manual entries
            calories: recipe.caloriesPerServing * servingMultiplier,
            protein: recipe.proteinPerServing * servingMultiplier,
            carbs: recipe.carbsPerServing * servingMultiplier,
            fats: recipe.fatPerServing * servingMultiplier,
            servingSize: "\(String(format: "%.2f", servingMultiplier))x serving",
            mealType: selectedMealType
        )
        
        // Add to food log
        appState.addFoodEntry(entry)
        
        HapticFeedback.success()
        dismiss()
    }
}

