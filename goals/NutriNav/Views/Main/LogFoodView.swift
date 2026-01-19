//
//  LogFoodView.swift
//  NutriNav
//
//  Food logging screen - accessible from dashboard
//

import SwiftUI

struct LogFoodView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let initialMealType: MealType?
    @State private var selectedMealType: MealType
    @State private var searchText: String = ""
    @State private var showManualEntry = false
    @State private var selectedFoodForDetails: FoodDetailsItem? = nil
    
    // Search state
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var searchError: String? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    
    private let foodService = FoodService.shared
    
    struct FoodDetailsItem: Identifiable {
        let id = UUID()
        let name: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let servingSize: String // e.g., "100 g" or "1 cup"
    }
    
    init(initialMealType: MealType? = nil) {
        self.initialMealType = initialMealType
        _selectedMealType = State(initialValue: initialMealType ?? .breakfast)
    }
    
    // Quick add foods (2x2 grid)
    private let quickAddFoods: [(name: String, calories: Double, protein: Double)] = [
        (name: "Apple", calories: 95, protein: 0.5),
        (name: "Egg", calories: 70, protein: 6),
        (name: "Protein Shake", calories: 120, protein: 25),
        (name: "Chicken Breast", calories: 165, protein: 31)
    ]
    
    // Favorites (sample data)
    private let favoriteFoods: [(name: String, calories: Double, protein: Double)] = [
        (name: "Greek Yogurt", calories: 120, protein: 15),
        (name: "Banana", calories: 105, protein: 1),
        (name: "Almonds", calories: 160, protein: 6)
    ]
    
    // Get today's food entries for Recent section
    private var todaysEntries: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        let todayLog = appState.foodLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        return Array((todayLog?.entries ?? []).prefix(3).reversed()) // Show last 3, most recent first
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Search Bar
                    searchBar
                        .padding(.horizontal, Spacing.md)
                    
                    // Search Results Section
                    if !searchText.isEmpty {
                        searchResultsSection
                            .padding(.horizontal, Spacing.md)
                    } else {
                        // Log with Photo Card
                        logWithPhotoCard
                            .padding(.horizontal, Spacing.md)
                        
                        // Quick Add Section
                        quickAddSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Favorites Section
                        favoritesSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Recent Section
                        if !todaysEntries.isEmpty {
                            recentSection
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .scrollContentBackground(.hidden)
            .onChange(of: searchText) { oldValue, newValue in
                performSearch(query: newValue)
            }
        }
        .navigationTitle("Log Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Manual") {
                    HapticFeedback.selection()
                    showManualEntry = true
                }
                .foregroundColor(.primaryAccent)
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(selectedMealType: selectedMealType)
                .environmentObject(appState)
        }
        .sheet(item: $selectedFoodForDetails) { food in
            FoodDetailsView(
                foodName: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                servingSize: food.servingSize,
                initialMealType: selectedMealType
            )
            .environmentObject(appState)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            
            TextField("Search foods...", text: $searchText)
                .font(.input)
                .foregroundColor(.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
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
        .padding(Spacing.sm)
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
                Text("Error: \(error)")
                    .font(.bodySmall)
                    .foregroundColor(.red)
                    .padding()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                Text("No results found")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .padding()
            } else {
                ForEach(searchResults) { result in
                    searchResultRow(result: result)
                }
            }
        }
    }
    
    // MARK: - Search Result Row
    private func searchResultRow(result: FoodSearchResult) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedFoodForDetails = FoodDetailsItem(
                name: result.displayName,
                calories: result.caloriesPerServing,
                protein: result.proteinPerServing,
                carbs: result.carbsPerServing,
                fat: result.fatPerServing,
                servingSize: result.servingSizeDescription
            )
        }) {
            PrimaryCard {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(result.displayName)
                            .font(.input)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: Spacing.sm) {
                            Text("\(Int(result.caloriesPerServing)) cal")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            if result.proteinPerServing > 0 {
                                Text("• \(Int(result.proteinPerServing))g protein")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            // Show serving size clearly
                            Text("• per \(result.servingSizeDescription)")
                                .font(.bodySmall)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
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
                let results = try await foodService.searchFoods(query: query)
                
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
    
    // MARK: - Log with Photo Card
    private var logWithPhotoCard: some View {
        Button(action: {
            HapticFeedback.selection()
            // TODO: Implement photo logging
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Log with Photo")
                        .font(.h3)
                        .foregroundColor(.white)
                    
                    Text("Take a picture of your meal")
                        .font(.bodySmall)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding(Spacing.md)
            .background(Color(hex: "2196F3")) // Blue
            .cornerRadius(Radius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Quick Add Section
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Add")
                .font(.h3)
                .foregroundColor(.textPrimary)
            
            // 2x2 Grid
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    quickAddCard(food: quickAddFoods[0])
                    quickAddCard(food: quickAddFoods[1])
                }
                HStack(spacing: Spacing.sm) {
                    quickAddCard(food: quickAddFoods[2])
                    quickAddCard(food: quickAddFoods[3])
                }
            }
        }
    }
    
    private func quickAddCard(food: (name: String, calories: Double, protein: Double)) -> some View {
        Button(action: {
            HapticFeedback.selection()
            // Show food details instead of directly adding
            selectedFoodForDetails = FoodDetailsItem(
                name: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: 0.0,
                fat: 0.0,
                servingSize: "1 serving"
            )
        }) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(food.name)
                    .font(.input)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(Int(food.calories)) cal")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Color.inputBackground)
            .cornerRadius(Radius.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Favorites Section
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "FFC107"))
                
                Text("Favorites")
                    .font(.h3)
                    .foregroundColor(.textPrimary)
            }
            
            VStack(spacing: Spacing.sm) {
                ForEach(favoriteFoods, id: \.name) { food in
                    favoriteRow(food: food)
                }
            }
        }
    }
    
    private func favoriteRow(food: (name: String, calories: Double, protein: Double)) -> some View {
        PrimaryCard {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(food.name)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(Int(food.calories)) cal • \(Int(food.protein))g protein")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.selection()
                    // Show food details instead of directly adding
                    selectedFoodForDetails = FoodDetailsItem(
                        name: food.name,
                        calories: food.calories,
                        protein: food.protein,
                        carbs: 0.0,
                        fat: 0.0,
                        servingSize: "1 serving"
                    )
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryAccent)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Recent Section
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                
                Text("Recent")
                    .font(.h3)
                    .foregroundColor(.textPrimary)
            }
            
            VStack(spacing: Spacing.sm) {
                ForEach(todaysEntries) { entry in
                    recentRow(entry: entry)
                }
            }
        }
    }
    
    private func recentRow(entry: FoodEntry) -> some View {
        PrimaryCard {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(entry.name)
                        .font(.input)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: Spacing.xs) {
                        Text("\(Int(entry.calories)) cal")
                        if entry.protein > 0 {
                            Text("• \(Int(entry.protein))g protein")
                        }
                        if let servingSize = entry.servingSize {
                            Text("• \(servingSize)")
                        }
                    }
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.selection()
                    // Show food details instead of directly adding
                    let servingSize = entry.servingSize ?? "1 serving"
                    selectedFoodForDetails = FoodDetailsItem(
                        name: entry.name,
                        calories: entry.calories,
                        protein: entry.protein,
                        carbs: entry.carbs,
                        fat: entry.fats,
                        servingSize: servingSize
                    )
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryAccent)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Functions
    private func quickAddFood(_ food: (name: String, calories: Double, protein: Double, carbs: Double, fat: Double)) {
        let entry = FoodEntry(
            name: food.name,
            source: .manual,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fats: food.fat,
            mealType: selectedMealType
        )
        
        appState.addFoodEntry(entry)
        HapticFeedback.success()
    }
}

// MARK: - Food Details View
struct FoodDetailsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let initialFoodName: String
    let initialCalories: Double
    let initialProtein: Double
    let initialCarbs: Double
    let initialFat: Double
    
    @State private var foodName: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var servingMultiplier: Double = 1.0
    @State private var servingSizeText: String
    @State private var selectedMealType: MealType
    
    init(foodName: String, calories: Double, protein: Double, carbs: Double, fat: Double, servingSize: String = "100 g", initialMealType: MealType? = nil) {
        self.initialFoodName = foodName
        self.initialCalories = calories
        self.initialProtein = protein
        self.initialCarbs = carbs
        self.initialFat = fat
        
        _foodName = State(initialValue: foodName)
        _calories = State(initialValue: String(format: "%.0f", calories))
        _protein = State(initialValue: String(format: "%.0f", protein))
        _carbs = State(initialValue: String(format: "%.0f", carbs))
        _fat = State(initialValue: String(format: "%.0f", fat))
        // Use the provided serving size (e.g., "100 g" or "1 cup")
        _servingSizeText = State(initialValue: servingSize)
        _selectedMealType = State(initialValue: initialMealType ?? .breakfast)
    }
    
    private var calculatedCalories: Double {
        (Double(calories) ?? initialCalories) * servingMultiplier
    }
    
    private var calculatedProtein: Double {
        (Double(protein) ?? initialProtein) * servingMultiplier
    }
    
    private var calculatedCarbs: Double {
        (Double(carbs) ?? initialCarbs) * servingMultiplier
    }
    
    private var calculatedFat: Double {
        (Double(fat) ?? initialFat) * servingMultiplier
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Food Details Card
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                // Food Name (displayed prominently, editable)
                                TextField("Food name", text: $foodName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Serving Size Adjustment
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Serving Size")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.textSecondary)
                                    
                                    HStack(spacing: Spacing.lg) {
                                        Button(action: {
                                            HapticFeedback.selection()
                                            if servingMultiplier > 0.5 {
                                                servingMultiplier -= 0.5
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text(servingMultiplier == 1.0 ? "1" : String(format: "%.1f", servingMultiplier))
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.textPrimary)
                                            TextField("serving", text: $servingSizeText)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.textSecondary)
                                                .multilineTextAlignment(.center)
                                                .frame(width: 100)
                                        }
                                        
                                        Button(action: {
                                            HapticFeedback.selection()
                                            servingMultiplier += 0.5
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.top, Spacing.sm)
                                
                                Divider()
                                    .background(Color.textTertiary.opacity(0.2))
                                    .padding(.vertical, Spacing.xs)
                                
                                // Nutritional Information (editable)
                                VStack(spacing: Spacing.md) {
                                    nutritionRow(label: "Calories", value: $calories, unit: "")
                                    Divider().background(Color.textTertiary.opacity(0.2))
                                    nutritionRow(label: "Protein", value: $protein, unit: "g")
                                    Divider().background(Color.textTertiary.opacity(0.2))
                                    nutritionRow(label: "Carbohydrates", value: $carbs, unit: "g")
                                    Divider().background(Color.textTertiary.opacity(0.2))
                                    nutritionRow(label: "Fat", value: $fat, unit: "g")
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        
                        // Add to Meal Section (in a card)
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Add to Meal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                
                                // Meal Type Selection (2x2 grid)
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
                        
                        // Add to Meal Button
                        Button(action: {
                            HapticFeedback.impact()
                            addFood()
                        }) {
                            Text("Add to \(selectedMealType.rawValue)")
                                .font(.button)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(Radius.lg)
                                .shadow(
                                    color: Shadow.button.color,
                                    radius: Shadow.button.radius,
                                    x: Shadow.button.x,
                                    y: Shadow.button.y
                                )
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        HapticFeedback.impact()
                        addFood()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
    }
    
    private func nutritionRow(label: String, value: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: value)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
    
    private func mealTypeButton(_ mealType: MealType) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedMealType = mealType
        }) {
            Text(mealType.rawValue)
                .font(.system(size: 16, weight: .regular))
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
    
    private func addFood() {
        let entry = FoodEntry(
            name: foodName.isEmpty ? initialFoodName : foodName,
            source: .manual,
            calories: calculatedCalories,
            protein: calculatedProtein,
            carbs: calculatedCarbs,
            fats: calculatedFat,
            servingSize: servingSizeText.isEmpty ? nil : servingSizeText,
            mealType: selectedMealType
        )
        
        appState.addFoodEntry(entry)
        HapticFeedback.success()
        dismiss()
    }
}

// MARK: - Manual Entry View
struct ManualEntryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let initialMealType: MealType
    
    @State private var selectedMealType: MealType
    @State private var mealName: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var servingMultiplier: Double = 1.0
    @State private var servingSize: String = "1 cup"
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    init(selectedMealType: MealType = .breakfast) {
        self.initialMealType = selectedMealType
        _selectedMealType = State(initialValue: selectedMealType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Food Entry Form
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                // Food Name (displayed prominently)
                                TextField("e.g., Grilled Chicken Salad", text: $mealName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Serving Size Adjustment
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Serving Size")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.textSecondary)
                                    
                                    HStack(spacing: Spacing.lg) {
                                        Button(action: {
                                            HapticFeedback.selection()
                                            if servingMultiplier > 0.5 {
                                                servingMultiplier -= 0.5
                                            }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text(servingMultiplier == 1.0 ? "1" : String(format: "%.1f", servingMultiplier))
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.textPrimary)
                                            TextField("serving", text: $servingSize)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.textSecondary)
                                                .multilineTextAlignment(.center)
                                                .frame(width: 100)
                                        }
                                        
                                        Button(action: {
                                            HapticFeedback.selection()
                                            servingMultiplier += 0.5
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.top, Spacing.sm)
                                
                                Divider()
                                    .background(Color.textTertiary.opacity(0.2))
                                    .padding(.vertical, Spacing.xs)
                                
                                // Nutritional Information (editable)
                                VStack(spacing: Spacing.md) {
                                    nutritionRow(label: "Calories", value: $calories, unit: "")
                                    Divider().background(Color.textTertiary.opacity(0.2))
                                    nutritionRow(label: "Protein", value: $protein, unit: "g")
                                    Divider().background(Color.textTertiary.opacity(0.2))
                                    nutritionRow(label: "Carbohydrates", value: $carbs, unit: "g")
                                    Divider().background(Color.textTertiary.opacity(0.2))
                                    nutritionRow(label: "Fat", value: $fat, unit: "g")
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.md)
                        
                        // Add to Meal Section (in a card)
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Text("Add to Meal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                
                                // Meal Type Selection (2x2 grid)
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
                        
                        // Add to Meal Button
                        Button(action: {
                            HapticFeedback.impact()
                            addFood()
                        }) {
                            Text("Add to \(selectedMealType.rawValue)")
                                .font(.button)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(Radius.lg)
                                .shadow(
                                    color: Shadow.button.color,
                                    radius: Shadow.button.radius,
                                    x: Shadow.button.x,
                                    y: Shadow.button.y
                                )
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Manual Entry")
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
            .alert("Validation Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func nutritionRow(label: String, value: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: value)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
    
    private func mealTypeButton(_ mealType: MealType) -> some View {
        Button(action: {
            HapticFeedback.selection()
            selectedMealType = mealType
        }) {
            Text(mealType.rawValue)
                .font(.system(size: 16, weight: .regular))
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
    
    private func addFood() {
        // Validate inputs
        guard !mealName.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Food name is required"
            showValidationError = true
            return
        }
        
        guard let caloriesValue = Double(calories), caloriesValue > 0 else {
            validationMessage = "Calories must be greater than 0"
            showValidationError = true
            return
        }
        
        // Parse optional values
        let proteinValue = Double(protein) ?? 0
        let carbsValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        
        // Apply serving multiplier
        let finalCalories = caloriesValue * servingMultiplier
        let finalProtein = proteinValue * servingMultiplier
        let finalCarbs = carbsValue * servingMultiplier
        let finalFat = fatValue * servingMultiplier
        
        // Create food entry
        let entry = FoodEntry(
            name: mealName.trimmingCharacters(in: .whitespaces),
            source: .manual,
            calories: finalCalories,
            protein: finalProtein,
            carbs: finalCarbs,
            fats: finalFat,
            servingSize: servingSize.isEmpty ? nil : servingSize,
            mealType: selectedMealType
        )
        
        // Add to app state
        appState.addFoodEntry(entry)
        
        // Dismiss
        dismiss()
        
        // Haptic feedback
        HapticFeedback.success()
    }
}
