//
//  ColorExtensions.swift
//  NutriNav
//
//  Legacy color extensions (for backward compatibility with onboarding views)
//  NOTE: All new code should use DesignSystem.swift colors instead
//

import SwiftUI

extension Color {
    // Legacy brand colors (used in onboarding views)
    // TODO: Migrate onboarding views to use DesignSystem colors
    static let appPurple = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let appPink = Color(red: 0.9, green: 0.4, blue: 0.6)
    static let appOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    // NOTE: All other colors (calorieColor, proteinColor, cardBackground, textPrimary, etc.)
    // are now defined in DesignSystem.swift to avoid duplicate declarations
}

