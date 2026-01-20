//
//  FoodService.swift
//  NutriNav
//
//  Food search service using USDA FoodData Central API
//  Free API - no key required
//

import Foundation

// MARK: - Food Search Protocol (for abstraction)
protocol FoodSearchService {
    func searchFoods(query: String) async throws -> [FoodSearchResult]
    func getFoodDetails(fdcId: Int) async throws -> FoodSearchResult?
}

// MARK: - Food Search Result Model
struct FoodSearchResult: Identifiable, Codable {
    let id: Int // fdcId from USDA
    let name: String
    let brand: String?
    let calories: Double // Per 100g (or per serving if servingSize is provided)
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double? // Serving size amount (e.g., 100.0)
    let servingSizeUnit: String? // Serving size unit (e.g., "g", "cup")
    
    // Display name
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }
    
    // Get serving size description for display
    var servingSizeDescription: String {
        if let size = servingSize, let unit = servingSizeUnit {
            // Format the number nicely (remove .0 if whole number)
            let formattedSize = size.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", size) : String(format: "%.1f", size)
            return "\(formattedSize) \(unit)"
        }
        // Default: per 100g (USDA standard)
        return "100 g"
    }
    
    // Get nutrition values for the serving size (or 100g if no serving size)
    var caloriesPerServing: Double {
        return calories // Already per serving or per 100g
    }
    
    var proteinPerServing: Double {
        return protein
    }
    
    var carbsPerServing: Double {
        return carbs
    }
    
    var fatPerServing: Double {
        return fat
    }
}

// MARK: - USDA FoodData Central Service
class FoodService: FoodSearchService {
    static let shared = FoodService()
    
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    private let session = URLSession.shared
    
    // USDA FoodData Central API Key (free - get one at https://fdc.nal.usda.gov/api-guide.html)
    private var apiKey: String? = "HT8GG5fiuxQhYCuZIhpvpl9xowVOAn6957vb6Xr5"
    
    private init() {
        // Try to load from UserDefaults if previously set, otherwise use default
        if let savedKey = UserDefaults.standard.string(forKey: "USDA_API_KEY"), !savedKey.isEmpty {
            apiKey = savedKey
        }
        // If no saved key, the default hardcoded key above will be used
    }
    
    // MARK: - API Key Management
    func setAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "USDA_API_KEY")
    }
    
    func hasAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    // MARK: - Get Common/Popular Foods
    /// Fetch common foods for quick add (fallback when user hasn't logged anything)
    func getCommonFoods() async throws -> [FoodSearchResult] {
        // Search for common foods that most people eat
        let commonFoodQueries = ["apple", "egg", "chicken breast", "banana"]
        var allResults: [FoodSearchResult] = []
        
        // Fetch top result for each common food
        for query in commonFoodQueries {
            do {
                let results = try await searchFoods(query: query)
                if let firstResult = results.first {
                    allResults.append(firstResult)
                }
            } catch {
                // Continue if one fails
                print("Failed to fetch \(query): \(error)")
            }
        }
        
        return allResults
    }
    
    // MARK: - Search Foods
    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        // Build URL
        var components = URLComponents(string: "\(baseURL)/foods/search")!
        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "50"), // Max results per page
            // Search all data types: Foundation (raw foods), SR Legacy (older generic), 
            // Branded (commercial products), FNDDS (foods as eaten in surveys)
            URLQueryItem(name: "dataType", value: "Foundation,SR%20Legacy,Branded,FNDDS")
        ]
        
        // Add API key if available
        if let apiKey = apiKey, !apiKey.isEmpty {
            queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw FoodServiceError.invalidURL
        }
        
        // Make request
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Provide helpful error message for 403
            if httpResponse.statusCode == 403 {
                throw FoodServiceError.apiKeyRequired
            }
            // Try to get error message from response body
            if let errorString = String(data: data, encoding: .utf8) {
                print("USDA API Error Response: \(errorString)")
            }
            throw FoodServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Debug: Print raw response (first 500 chars)
        if let responseString = String(data: data, encoding: .utf8) {
            print("USDA API Response (first 500 chars): \(String(responseString.prefix(500)))")
        }
        
        // Parse response
        let decoder = JSONDecoder()
        
        do {
            let searchResponse = try decoder.decode(USDASearchResponse.self, from: data)
            print("Parsed \(searchResponse.foods.count) foods from API")
            
            // Convert to FoodSearchResult
            let results = searchResponse.foods.compactMap { food in
                parseUSDAFood(food)
            }
            print("Successfully parsed \(results.count) valid foods out of \(searchResponse.foods.count) total")
            
            // If we got foods from API but parsed 0, log details about first food
            if searchResponse.foods.count > 0 && results.count == 0 {
                let firstFood = searchResponse.foods[0]
                print("First food details: \(firstFood.description), nutrients count: \(firstFood.foodNutrients?.count ?? 0)")
                if let nutrients = firstFood.foodNutrients {
                    print("Sample nutrients: \(nutrients.prefix(5).map { "\($0.nutrientId ?? 0): \($0.actualValue ?? 0)" })")
                }
            }
            
            return results
        } catch {
            print("Decoding error: \(error)")
            // Try to see what the actual structure is
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Response structure: \(json.keys)")
            }
            throw FoodServiceError.decodingError
        }
    }
    
    // MARK: - Get Food Details
    func getFoodDetails(fdcId: Int) async throws -> FoodSearchResult? {
        var components = URLComponents(string: "\(baseURL)/food/\(fdcId)")!
        
        // Add API key if available
        if let apiKey = apiKey, !apiKey.isEmpty {
            components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        }
        
        guard let url = components.url else {
            throw FoodServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Provide helpful error message for 403
            if httpResponse.statusCode == 403 {
                throw FoodServiceError.apiKeyRequired
            }
            throw FoodServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let food = try decoder.decode(USDAFood.self, from: data)
        
        return parseUSDAFood(food)
    }
    
    // MARK: - Parse USDA Food to FoodSearchResult
    private func parseUSDAFood(_ food: USDAFood) -> FoodSearchResult? {
        // Extract nutrition values from foodNutrients array
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        
        // Handle case where foodNutrients might be nil or empty
        if let nutrients = food.foodNutrients, !nutrients.isEmpty {
            for nutrient in nutrients {
                guard let nutrientId = nutrient.nutrientId else { continue }
                
                let value = nutrient.actualValue ?? 0
                
                switch nutrientId {
                case 1008: // Energy (kcal)
                    calories = value
                case 1003: // Protein
                    protein = value
                case 1005: // Carbohydrate, by difference
                    carbs = value
                case 1004: // Total lipid (fat)
                    fat = value
                default:
                    break
                }
            }
        }
        
        // If no calories found, try to use a default or estimate
        // Some foods might have nutrients but calories might be in a different field
        // For now, we'll still show foods even if calories are 0, but log it
        if calories == 0 {
            print("Warning: Food '\(food.description)' (ID: \(food.fdcId)) has no calories - showing anyway")
            // Don't filter out - let user see it and they can edit the values
            // Set a default of 0, user can edit in FoodDetailsView
        }
        
        // USDA API provides nutrition per 100g by default
        // If servingSize is provided, we need to scale the values
        // Otherwise, values are already per 100g
        var finalCalories = calories
        var finalProtein = protein
        var finalCarbs = carbs
        var finalFat = fat
        
        // If serving size is provided and different from 100g, scale the values
        if let servingSize = food.servingSize, let unit = food.servingSizeUnit {
            // Only scale if it's in grams and different from 100g
            if unit.lowercased() == "g" && servingSize != 100.0 {
                let scaleFactor = servingSize / 100.0
                finalCalories = calories * scaleFactor
                finalProtein = protein * scaleFactor
                finalCarbs = carbs * scaleFactor
                finalFat = fat * scaleFactor
            }
        }
        
        return FoodSearchResult(
            id: food.fdcId,
            name: food.description,
            brand: food.brandOwner,
            calories: finalCalories,
            protein: finalProtein,
            carbs: finalCarbs,
            fat: finalFat,
            servingSize: food.servingSize ?? 100.0, // Default to 100g if not provided
            servingSizeUnit: food.servingSizeUnit ?? "g"
        )
    }
}

// MARK: - USDA API Response Models
private struct USDASearchResponse: Codable {
    let foods: [USDAFood]
    let totalHits: Int?
    let currentPage: Int?
    let totalPages: Int?
    
    enum CodingKeys: String, CodingKey {
        case foods
        case totalHits
        case currentPage
        case totalPages
    }
}

private struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let foodNutrients: [USDANutrient]?
    let servingSize: Double?
    let servingSizeUnit: String?
    
    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case brandOwner
        case foodNutrients
        case servingSize
        case servingSizeUnit
    }
}

private struct USDANutrient: Codable {
    let nutrientId: Int?
    let nutrientName: String?
    let value: Double?
    let unitName: String?
    let amount: Double? // Some responses use 'amount' instead of 'value'
    
    // Get the actual value, preferring 'value' over 'amount'
    var actualValue: Double? {
        return value ?? amount
    }
}

// MARK: - Errors
enum FoodServiceError: LocalizedError {
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
            return "API key required. Get a free key at https://fdc.nal.usda.gov/api-guide.html"
        }
    }
}

