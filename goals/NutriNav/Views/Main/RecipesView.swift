//
//  RecipesView.swift
//  NutriNav
//
//  Recipes screen with search and ingredient-based suggestions
//

import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var fridgeIngredients = "chicken, rice, broccoli"
    @State private var recipes = MockDataService.shared.getRecipes()
    @State private var filteredRecipes: [Recipe] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with gradient
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tasty Recipes")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "fork.knife")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Text("Delicious meals made just for you")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    .background(
                        LinearGradient(
                            colors: [Color.appPink, Color.appOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Search for your next fave meal...", text: $searchText)
                                    .onChange(of: searchText) { _, newValue in
                                        filterRecipes()
                                    }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Fridge ingredients section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("What's in your fridge?")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("👨‍🍳")
                                        .font(.system(size: 16))
                                }
                                .padding(.horizontal, 20)
                                
                                HStack {
                                    Text(fridgeIngredients)
                                        .font(.system(size: 16))
                                        .foregroundColor(.textSecondary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Update ingredients and filter recipes
                                        filterRecipes()
                                    }) {
                                        Text("Update")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.appPurple)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(15)
                                .padding(.horizontal, 20)
                            }
                            
                            // Perfect For You section
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    HStack(spacing: 8) {
                                        Text("Perfect For You")
                                            .font(.system(size: 24, weight: .bold))
                                        Text("✨")
                                            .font(.system(size: 18))
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {}) {
                                        Text("\(recipes.count) recipes")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.appOrange)
                                            .cornerRadius(20)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Recipe cards
                                ForEach(filteredRecipes.isEmpty ? recipes : filteredRecipes) { recipe in
                                    RecipeCard(recipe: recipe)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .onAppear {
                filterRecipes()
            }
        }
    }
    
    private func filterRecipes() {
        if searchText.isEmpty && fridgeIngredients.isEmpty {
            filteredRecipes = []
            return
        }
        
        let ingredients = fridgeIngredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        filteredRecipes = MockDataService.shared.getRecipesForIngredients(ingredients)
    }
}

struct RecipeCard: View {
    @State var recipe: Recipe
    
    var body: some View {
        VStack(spacing: 0) {
            // Recipe image placeholder
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 200)
                
                // Tags overlay
                HStack(spacing: 8) {
                    ForEach(recipe.tags.prefix(2), id: \.self) { tag in
                        Text(tag.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                    }
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Favorite button
                                    Button(action: {
                                        recipe.isFavorite.toggle()
                                        AnalyticsService.shared.trackRecipeViewed(recipeId: recipe.id.uuidString, recipeName: recipe.title)
                                    }) {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(recipe.isFavorite ? .appPink : .white)
                        .padding(10)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
                .padding(15)
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 12) {
                Text(recipe.title)
                    .font(.system(size: 22, weight: .bold))
                
                // Stats row
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.appOrange)
                        Text("\(recipe.prepTime)m")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                        Text("\(recipe.calories)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.blue)
                        Text("\(recipe.protein)g")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                // Difficulty and view button
                HStack {
                    Text(recipe.difficulty.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    Button(action: {
                        AnalyticsService.shared.trackRecipeTried(recipeId: recipe.id.uuidString, recipeName: recipe.title)
                    }) {
                        HStack(spacing: 4) {
                            Text("View Recipe")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.appPink)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(15)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

