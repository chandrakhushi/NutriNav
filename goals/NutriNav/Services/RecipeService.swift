//
//  RecipeService.swift
//  NutriNav
//
//  Recipe search service using Spoonacular API
//  Free tier: 150 points/day
//

import Foundation

// MARK: - Recipe Service Protocol
protocol RecipeServiceProtocol {
    func searchRecipes(query: String) async throws -> [RecipeSearchResult]
    func getRecipeDetails(id: Int) async throws -> RecipeDetail?
}

// MARK: - Recipe Search Result Model
struct RecipeSearchResult: Identifiable, Codable, Hashable {
    let id: Int // Spoonacular recipe ID
    let title: String
    let image: String?
    let readyInMinutes: Int
    let servings: Int
    let nutrition: RecipeNutrition?
    
    // Computed properties for display
    var imageURL: URL? {
        guard let image = image, !image.isEmpty else { return nil }
        return URL(string: image)
    }
    
    // Extract calories from nutrition object
    var calories: Double? {
        nutrition?.nutrients.first(where: { $0.name.lowercased().contains("calorie") })?.amount
    }
    
    // Extract protein from nutrition object
    var protein: Double? {
        nutrition?.nutrients.first(where: { $0.name.lowercased() == "protein" })?.amount
    }
    
    var displayCalories: Int {
        Int(calories ?? 0)
    }
    
    var displayProtein: Int {
        Int(protein ?? 0)
    }
}

// MARK: - Recipe Detail Model
struct RecipeDetail: Identifiable, Codable {
    let id: Int
    let title: String
    let image: String?
    let readyInMinutes: Int
    let servings: Int
    let summary: String?
    let instructions: String?
    let extendedIngredients: [ExtendedIngredient]
    let nutrition: RecipeNutrition?
    
    // Parsed instructions as array
    var instructionSteps: [String] {
        guard let instructions = instructions, !instructions.isEmpty else {
            return []
        }
        // Instructions come as HTML or numbered text, parse them
        return instructions
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { step in
                // Remove HTML tags if present
                step.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
            }
    }
    
    var imageURL: URL? {
        guard let image = image, !image.isEmpty else { return nil }
        return URL(string: image)
    }
    
    // Nutrition values per serving
    var caloriesPerServing: Double {
        nutrition?.nutrients.first(where: { $0.name.lowercased().contains("calorie") })?.amount ?? 0
    }
    
    var proteinPerServing: Double {
        nutrition?.nutrients.first(where: { $0.name.lowercased() == "protein" })?.amount ?? 0
    }
    
    var carbsPerServing: Double {
        nutrition?.nutrients.first(where: { $0.name.lowercased().contains("carbohydrate") })?.amount ?? 0
    }
    
    var fatPerServing: Double {
        nutrition?.nutrients.first(where: { $0.name.lowercased() == "fat" })?.amount ?? 0
    }
}

struct ExtendedIngredient: Codable {
    let id: Int?
    let name: String
    let original: String
    let amount: Double?
    let unit: String?
}

struct RecipeNutrition: Codable, Hashable {
    let nutrients: [Nutrient]
}

struct Nutrient: Codable, Hashable {
    let name: String
    let amount: Double
    let unit: String
}

// MARK: - Spoonacular Recipe Service
class RecipeService: RecipeServiceProtocol {
    static let shared = RecipeService()
    
    private let baseURL = "https://api.spoonacular.com/recipes"
    private let session = URLSession.shared
    
    // Spoonacular API Key - Free tier: 150 points/day
    // Get your free API key at: https://spoonacular.com/food-api
    // To set the API key, call: RecipeService.shared.setAPIKey("your-api-key-here")
    // Or set it programmatically in your app initialization
    private var apiKey: String? = "fa8781b6ea35472290e1e133fc81606e"
    
    private init() {
        // Try to load from UserDefaults if previously set, otherwise use default key
        if let savedKey = UserDefaults.standard.string(forKey: "SPOONACULAR_API_KEY"), !savedKey.isEmpty {
            apiKey = savedKey
        }
        // If no saved key, the default hardcoded key above will be used
    }
    
    // MARK: - API Key Management
    func setAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "SPOONACULAR_API_KEY")
    }
    
    func hasAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    // MARK: - Search Recipes
    func searchRecipes(query: String) async throws -> [RecipeSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw RecipeServiceError.apiKeyRequired
        }
        
        // Build URL for complex search
        var components = URLComponents(string: "\(baseURL)/complexSearch")!
        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "number", value: "20"), // Max results per request
            URLQueryItem(name: "addRecipeNutrition", value: "true"), // Include nutrition
            URLQueryItem(name: "fillIngredients", value: "false"), // Don't need full ingredient details for search
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw RecipeServiceError.invalidURL
        }
        
        // Make request
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecipeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 402 {
                throw RecipeServiceError.apiKeyRequired
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("Spoonacular API Error Response: \(errorString)")
            }
            throw RecipeServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let searchResponse = try decoder.decode(SpoonacularSearchResponse.self, from: data)
            return searchResponse.results
        } catch {
            print("Decoding error: \(error)")
            throw RecipeServiceError.decodingError
        }
    }
    
    // MARK: - Get Recipe Details
    func getRecipeDetails(id: Int) async throws -> RecipeDetail? {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw RecipeServiceError.apiKeyRequired
        }
        
        // Build URL for recipe information
        var components = URLComponents(string: "\(baseURL)/\(id)/information")!
        var queryItems = [
            URLQueryItem(name: "includeNutrition", value: "true"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw RecipeServiceError.invalidURL
        }
        
        // Make request
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecipeServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 402 {
                throw RecipeServiceError.apiKeyRequired
            }
            if let errorString = String(data: data, encoding: .utf8) {
                print("Spoonacular API Error Response: \(errorString)")
            }
            throw RecipeServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let recipeDetail = try decoder.decode(RecipeDetail.self, from: data)
            return recipeDetail
        } catch {
            print("Decoding error: \(error)")
            throw RecipeServiceError.decodingError
        }
    }
}

// MARK: - Spoonacular API Response Models
private struct SpoonacularSearchResponse: Codable {
    let results: [RecipeSearchResult]
    let offset: Int
    let number: Int
    let totalResults: Int
}

// MARK: - Errors
enum RecipeServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case apiKeyRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .apiKeyRequired:
            return "API key required. Get a free key at https://spoonacular.com/food-api"
        }
    }
}

