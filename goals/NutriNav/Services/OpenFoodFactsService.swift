//
//  OpenFoodFactsService.swift
//  NutriNav
//
//  Free barcode-based nutrition lookup using OpenFoodFacts API
//  API Documentation: https://wiki.openfoodfacts.org/API
//

import Foundation

// MARK: - OpenFoodFacts API Response Models

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let statusVerbose: String?
    let product: OpenFoodFactsProduct?
    
    enum CodingKeys: String, CodingKey {
        case status
        case statusVerbose = "status_verbose"
        case product
    }
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let productNameEn: String?
    let brands: String?
    let servingSize: String?
    let servingQuantity: Double?
    let nutriments: OpenFoodFactsNutriments?
    let imageUrl: String?
    let imageFrontUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameEn = "product_name_en"
        case brands
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutriments
        case imageUrl = "image_url"
        case imageFrontUrl = "image_front_url"
    }
    
    var displayName: String {
        let name = productNameEn ?? productName ?? "Unknown Product"
        if let brand = brands, !brand.isEmpty {
            return "\(brand) - \(name)"
        }
        return name
    }
}

struct OpenFoodFactsNutriments: Codable {
    // Per 100g values
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let fiber100g: Double?
    let sugars100g: Double?
    let sodium100g: Double?
    
    // Per serving values (preferred when available)
    let energyKcalServing: Double?
    let proteinsServing: Double?
    let carbohydratesServing: Double?
    let fatServing: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
        case sodium100g = "sodium_100g"
        case energyKcalServing = "energy-kcal_serving"
        case proteinsServing = "proteins_serving"
        case carbohydratesServing = "carbohydrates_serving"
        case fatServing = "fat_serving"
    }
}

// MARK: - Scanned Food Result

struct ScannedFoodResult {
    let barcode: String
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String
    let imageUrl: String?
    
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) - \(name)"
        }
        return name
    }
}

// MARK: - OpenFoodFacts Service

enum OpenFoodFactsError: LocalizedError {
    case productNotFound
    case invalidBarcode
    case networkError(Error)
    case decodingError(Error)
    case noNutritionData
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in database. Try manual entry instead."
        case .invalidBarcode:
            return "Invalid barcode format."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Could not read product data."
        case .noNutritionData:
            return "No nutrition information available for this product."
        }
    }
}

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    /// Lookup a product by barcode
    /// - Parameter barcode: UPC, EAN, or other barcode string
    /// - Returns: ScannedFoodResult with nutrition data
    func lookupBarcode(_ barcode: String) async throws -> ScannedFoodResult {
        // Validate barcode format (basic check)
        let cleanBarcode = barcode.trimmingCharacters(in: .whitespaces)
        guard !cleanBarcode.isEmpty, cleanBarcode.allSatisfy({ $0.isNumber }) else {
            throw OpenFoodFactsError.invalidBarcode
        }
        
        // Build URL
        guard let url = URL(string: "\(baseURL)/\(cleanBarcode).json") else {
            throw OpenFoodFactsError.invalidBarcode
        }
        
        // Add User-Agent as required by OpenFoodFacts API
        var request = URLRequest(url: url)
        request.setValue("NutriNav iOS App - Contact: nutrinav@example.com", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenFoodFactsError.networkError(NSError(domain: "HTTP", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw OpenFoodFactsError.productNotFound
                }
                throw OpenFoodFactsError.networkError(NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: nil))
            }
            
            // Decode response
            let decoder = JSONDecoder()
            let result = try decoder.decode(OpenFoodFactsResponse.self, from: data)
            
            // Check if product was found
            guard result.status == 1, let product = result.product else {
                throw OpenFoodFactsError.productNotFound
            }
            
            // Check if we have nutrition data
            guard let nutriments = product.nutriments else {
                throw OpenFoodFactsError.noNutritionData
            }
            
            // Prefer per-serving values, fall back to per-100g
            let hasServingData = nutriments.energyKcalServing != nil
            
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
            let servingSize: String
            
            if hasServingData, let servingAmount = product.servingSize {
                // Use per-serving values
                calories = nutriments.energyKcalServing ?? 0
                protein = nutriments.proteinsServing ?? 0
                carbs = nutriments.carbohydratesServing ?? 0
                fat = nutriments.fatServing ?? 0
                servingSize = servingAmount
            } else {
                // Use per-100g values
                calories = nutriments.energyKcal100g ?? 0
                protein = nutriments.proteins100g ?? 0
                carbs = nutriments.carbohydrates100g ?? 0
                fat = nutriments.fat100g ?? 0
                servingSize = "100 g"
            }
            
            // Validate we have at least calories
            guard calories > 0 || protein > 0 || carbs > 0 || fat > 0 else {
                throw OpenFoodFactsError.noNutritionData
            }
            
            return ScannedFoodResult(
                barcode: cleanBarcode,
                name: product.productName ?? product.productNameEn ?? "Unknown Product",
                brand: product.brands,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                servingSize: servingSize,
                imageUrl: product.imageFrontUrl ?? product.imageUrl
            )
            
        } catch let error as OpenFoodFactsError {
            throw error
        } catch let error as DecodingError {
            print("OpenFoodFacts decoding error: \(error)")
            throw OpenFoodFactsError.decodingError(error)
        } catch {
            throw OpenFoodFactsError.networkError(error)
        }
    }
}

