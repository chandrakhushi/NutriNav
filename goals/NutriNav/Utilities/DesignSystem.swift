//
//  DesignSystem.swift
//  NutriNav
//
//  SINGLE SOURCE OF TRUTH for all UI design elements
//  Based on Figma design specifications
    //

import SwiftUI

// MARK: - Color Palette (Figma Design System)

extension Color {
    // Background Colors
    static let background = Color.white // #ffffff
    static let card = Color.white // #ffffff
    static let cardForeground = Color(hex: "252525") // oklch(0.145 0 0) - dark gray approximation
    
    // Primary Colors
    static let primary = Color(hex: "030213") // #030213
    static let primaryForeground = Color.white // oklch(1 0 0) - white
    
    // Secondary Colors
    static let secondary = Color(hex: "f2f2f5") // oklch(0.95 0.0058 264.53) - light gray/purple tint approximation
    static let secondaryForeground = Color(hex: "030213") // #030213
    
    // Accent Colors
    static let accent = Color(hex: "e9ebef") // #e9ebef
    static let accentForeground = Color(hex: "030213") // #030213
    
    // Destructive Colors
    static let destructive = Color(hex: "d4183d") // #d4183d
    static let destructiveForeground = Color.white // #ffffff
    
    // Border & Input Colors
    static let border = Color.black.opacity(0.1) // rgba(0,0,0,0.1)
    static let inputBackground = Color(hex: "f3f3f5") // #f3f3f5
    static let switchBackground = Color(hex: "cbced4") // #cbced4
    static let ring = Color(hex: "b5b5b5") // oklch(0.708 0 0) - medium gray approximation
    
    // Chart Colors (approximated from oklch)
    static let chart1 = Color(hex: "ff9500") // oklch(0.646 0.222 41.116) - orange approximation
    static let chart2 = Color(hex: "00a8cc") // oklch(0.6 0.118 184.704) - cyan approximation
    static let chart3 = Color(hex: "5a5a5a") // oklch(0.398 0.07 227.392) - dark gray approximation
    static let chart4 = Color(hex: "ffd700") // oklch(0.828 0.189 84.429) - gold approximation
    static let chart5 = Color(hex: "ffaa00") // oklch(0.769 0.188 70.08) - amber approximation
    
    // Legacy/Compatibility Colors (mapped to new system)
    static let primaryBackground = Color.background
    static let cardBackground = Color.card
    static let primaryAccent = Color(hex: "4CAF50") // Green accent for buttons/actions
    static let secondaryAccent = Color(hex: "4CAF50")
    
    // Semantic Colors (for status indicators)
    static let success = Color(hex: "4CAF50") // Green for success/open status
    static let warning = Color(hex: "FFC107") // Yellow/amber for ratings
    static let error = Color.destructive // Red for closed/error
    
    // Text Colors
    static let textPrimary = Color.primary // #030213
    static let textSecondary = Color.cardForeground.opacity(0.7) // oklch(0.145 0 0) with opacity
    static let textTertiary = Color.cardForeground.opacity(0.5) // oklch(0.145 0 0) with opacity
    
    // Nutrition Colors (matching Figma)
    static let calorieColor = Color(hex: "FF9800") // Orange for calories (flame icon)
    static let proteinColor = Color(hex: "2196F3") // Blue for protein
    static let carbColor = Color(hex: "4CAF50") // Green for carbs
    static let fatColor = Color(hex: "FFC107") // Yellow/amber for fats
    
    // Interactive States
    static let buttonDisabled = Color(hex: "E0E0E0") // Light gray for disabled
    static let buttonPressed = Color.primaryAccent.opacity(0.8)
    
    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
}

// MARK: - Typography Scale (Figma Design System)

extension Font {
    // Headings - Medium weight
    static let h1 = Font.system(size: 24, weight: .medium) // 24pt, medium
    static let h2 = Font.system(size: 20, weight: .medium) // 20pt, medium
    static let h3 = Font.system(size: 18, weight: .medium) // 18pt, medium
    static let h4 = Font.system(size: 16, weight: .medium) // 16pt, medium
    
    // Labels & Buttons
    static let label = Font.system(size: 16, weight: .medium) // 16pt, medium
    static let button = Font.system(size: 16, weight: .medium) // 16pt, medium
    
    // Input
    static let input = Font.system(size: 16, weight: .regular) // 16pt, regular
    
    // Legacy/Compatibility Fonts (mapped to new system)
    static let heading1 = Font.h1
    static let heading2 = Font.h2
    static let heading3 = Font.h3
    static let body = Font.input // 16pt regular
    static let bodyLarge = Font.system(size: 18, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)
    static let labelSmall = Font.system(size: 12, weight: .medium)
    static let buttonText = Font.button
    static let buttonTextSmall = Font.system(size: 14, weight: .medium)
}

// MARK: - Spacing System

struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius (Figma Design System)

struct Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 10
    static let xl: CGFloat = 14
}

// Legacy/Compatibility Corner Radius
struct CornerRadius {
    static let card: CGFloat = Radius.lg // 10
    static let button: CGFloat = Radius.md // 8
    static let badge: CGFloat = Radius.sm // 6
    static let small: CGFloat = Radius.sm // 6
}

// MARK: - Shadow System (Subtle for white cards)

struct Shadow {
    static let card = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let button = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 2,
        x: 0,
        y: 1
    )
    
    static let elevated = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 6,
        x: 0,
        y: 3
    )
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Gradient System (Removed - Figma uses solid colors)

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

