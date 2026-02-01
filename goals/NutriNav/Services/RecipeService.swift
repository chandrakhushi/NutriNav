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
    func searchRecipes(query: String, filters: RecipeFilters?) async throws -> [RecipeSearchResult]
    func getRecipeDetails(id: Int) async throws -> RecipeDetail?
}

// MARK: - Recipe Filters
struct RecipeFilters {
    var maxReadyTime: Int? // in minutes
    var minCalories: Int?
    var maxCalories: Int?
    var minProtein: Int? // in grams
    var maxProtein: Int? // in grams
    var diet: String? // e.g., "vegetarian", "vegan", "gluten-free", "keto", "paleo"
    var type: String? // e.g., "main course", "dessert", "appetizer", "salad", "soup"
    
    static var none: RecipeFilters {
        RecipeFilters()
    }
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
        guard let nutrition = nutrition else { return nil }
        // Try different possible names for calories
        return nutrition.nutrients.first(where: { nutrient in
            let name = nutrient.name.lowercased()
            return name.contains("calorie") || name.contains("energy")
        })?.amount
    }
    
    // Extract protein from nutrition object
    var protein: Double? {
        guard let nutrition = nutrition else { return nil }
        // Try different possible names for protein
        return nutrition.nutrients.first(where: { nutrient in
            let name = nutrient.name.lowercased()
            return name == "protein" || name.contains("protein")
        })?.amount
    }
    
    var displayCalories: Int {
        if let calories = calories, calories > 0 {
            return Int(calories)
        }
        return 0
    }
    
    var displayProtein: Int {
        if let protein = protein, protein > 0 {
            return Int(protein)
        }
        return 0
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
        
        // Remove HTML tags first
        var cleanedInstructions = instructions
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Try splitting by newlines first
        var steps = cleanedInstructions
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // If no newlines found, try splitting by numbered patterns (1., 2., etc.)
        if steps.count <= 1 {
            let pattern = #"(\d+\.\s*)"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = cleanedInstructions as NSString
                let matches = regex.matches(in: cleanedInstructions, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if matches.count > 1 {
                    var newSteps: [String] = []
                    for (index, match) in matches.enumerated() {
                        let startRange = match.range.location
                        let endRange = index < matches.count - 1 ? matches[index + 1].range.location : nsString.length
                        let stepRange = NSRange(location: startRange, length: endRange - startRange)
                        let step = nsString.substring(with: stepRange)
                            .trimmingCharacters(in: .whitespaces)
                            .replacingOccurrences(of: pattern, with: "", options: .regularExpression)
                        if !step.isEmpty {
                            newSteps.append(step)
                        }
                    }
                    if !newSteps.isEmpty {
                        steps = newSteps
                    }
                }
            }
        }
        
        // If still a single paragraph, try splitting by sentence endings
        if steps.count <= 1 {
            steps = cleanedInstructions
                .components(separatedBy: CharacterSet(charactersIn: ".!?"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.count > 10 } // Filter out very short fragments
        }
        
        // Final cleanup
        return steps.map { step in
            step.trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
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
    func searchRecipes(query: String, filters: RecipeFilters? = nil) async throws -> [RecipeSearchResult] {
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
        
        // Add filters if provided
        if let filters = filters {
            if let maxReadyTime = filters.maxReadyTime {
                queryItems.append(URLQueryItem(name: "maxReadyTime", value: "\(maxReadyTime)"))
            }
            if let minCalories = filters.minCalories {
                queryItems.append(URLQueryItem(name: "minCalories", value: "\(minCalories)"))
            }
            if let maxCalories = filters.maxCalories {
                queryItems.append(URLQueryItem(name: "maxCalories", value: "\(maxCalories)"))
            }
            if let minProtein = filters.minProtein {
                queryItems.append(URLQueryItem(name: "minProtein", value: "\(minProtein)"))
            }
            if let maxProtein = filters.maxProtein {
                queryItems.append(URLQueryItem(name: "maxProtein", value: "\(maxProtein)"))
            }
            if let diet = filters.diet, !diet.isEmpty {
                queryItems.append(URLQueryItem(name: "diet", value: diet))
            }
            if let type = filters.type, !type.isEmpty {
                queryItems.append(URLQueryItem(name: "type", value: type))
            }
        }
        
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

