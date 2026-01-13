//
//  RecipesView.swift
//  NutriNav
//
//  Recipes screen - using DesignSystem
//

import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var fridgeIngredients = "chicken, rice, broccoli"
    @State private var recipes = MockDataService.shared.getRecipes()
    @State private var filteredRecipes: [Recipe] = []
    @State private var showIngredientEditor = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // Search Bar
                        searchBar
                            .padding(.horizontal, Spacing.md)
                        
                        // Fridge Ingredients
                        fridgeSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Recipes List
                        recipesSection
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .sheet(isPresented: $showIngredientEditor) {
                IngredientEditorView(ingredients: $fridgeIngredients)
            }
            .onAppear {
                filterRecipes()
            }
        }
    }
    
    // MARK: - Header
    
    // MARK: - Header (Design System: h1=24pt medium)
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text("Recipes")
                    .font(.h1) // 24pt, medium
                    .foregroundColor(.textPrimary)
                            
                Image(systemName: "fork.knife")
                    .font(.system(size: 24))
                    .foregroundColor(.primaryAccent)
            }
            
            Text("Healthy meals you'll love")
                .font(.input) // 16pt, regular
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - Search Bar (Design System: input=16pt regular, inputBackground=#f3f3f5, cornerRadius=md=8)
    private var searchBar: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            
            TextField("Search recipes...", text: $searchText)
                .font(.input) // 16pt, regular
                .foregroundColor(.textPrimary)
                .onChange(of: searchText) { _, _ in
                    filterRecipes()
                }
        }
        .padding(Spacing.md)
        .background(Color.inputBackground) // #f3f3f5
        .cornerRadius(Radius.md) // Button cornerRadius = 8
    }
    
    // MARK: - Fridge Section (Design System: h3=18pt medium, input=16pt regular, inputBackground=#f3f3f5, cornerRadius=md=8)
    private var fridgeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Available Ingredients")
                .font(.h3) // 18pt, medium
                .foregroundColor(.textPrimary)
            
            HStack {
                Text(fridgeIngredients)
                    .font(.input) // 16pt, regular
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.selection()
                    showIngredientEditor = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryAccent)
                }
            }
            .padding(Spacing.md)
            .background(Color.inputBackground) // #f3f3f5
            .cornerRadius(Radius.md) // Button cornerRadius = 8
        }
    }
    
    // MARK: - Recipes Section
    
    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader(title: "Suggested for You")
                
                Spacer()
                
                Text("\(filteredRecipes.isEmpty ? recipes.count : filteredRecipes.count) recipes")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            ForEach(filteredRecipes.isEmpty ? recipes : filteredRecipes) { recipe in
                recipeCard(recipe: recipe)
            }
        }
    }
    
    // MARK: - Recipe Card (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private func recipeCard(recipe: Recipe) -> some View {
        Button(action: {
            HapticFeedback.impact()
            AnalyticsService.shared.trackRecipeTried(
                recipeId: recipe.id.uuidString,
                recipeName: recipe.title
            )
            // TODO: Navigate to recipe detail view
        }) {
            PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
                HStack(spacing: Spacing.md) {
                    // Image placeholder
                    RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                        .fill(Color(hex: "E0E0E0"))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.textTertiary)
                        )
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(recipe.title)
                            .font(.h3) // 18pt, medium
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: Spacing.md) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                Text("\(recipe.prepTime)m")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.calorieColor)
                                Text("\(recipe.calories)")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 14))
                                    .foregroundColor(.proteinColor)
                                Text("\(recipe.protein)g")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        BadgeView(
                            text: recipe.difficulty.rawValue,
                            color: .success,
                            size: .small
                        )
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
    
    // MARK: - Helper
    
    private func filterRecipes() {
        if searchText.isEmpty && fridgeIngredients.isEmpty {
            filteredRecipes = []
            return
        }
        
        let ingredients = fridgeIngredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        filteredRecipes = MockDataService.shared.getRecipesForIngredients(ingredients)
    }
}

// MARK: - Ingredient Editor View

// MARK: - Ingredient Editor View (Design System: h2=20pt medium, input=16pt regular, cornerRadius=md=8)
struct IngredientEditorView: View {
    @Binding var ingredients: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    Text("Edit Ingredients")
                        .font(.h2) // 20pt, medium
                        .foregroundColor(.textPrimary)
                    
                    TextField("Enter ingredients (comma separated)", text: $ingredients)
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textPrimary)
                        .padding(Spacing.md)
                        .background(Color.inputBackground) // #f3f3f5
                        .cornerRadius(Radius.md) // Button cornerRadius = 8
                        .padding(.horizontal, Spacing.md)
                    
                    PrimaryButton(
                        title: "Save",
                        action: {
                            HapticFeedback.success()
                            dismiss()
                        },
                        icon: "checkmark"
                    )
                    .padding(.horizontal, Spacing.md)
                }
                .padding(Spacing.xl)
            }
            .navigationTitle("Ingredients")
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
}
