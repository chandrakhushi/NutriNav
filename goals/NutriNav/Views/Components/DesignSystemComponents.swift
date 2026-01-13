//
//  DesignSystemComponents.swift
//  NutriNav
//
//  Reusable UI components using DesignSystem
//

import SwiftUI

// MARK: - Buttons

// MARK: - Primary Button (Design System: padding=12, cornerRadius=md=8, font=16pt medium)
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: {
            if isEnabled {
                HapticFeedback.impact()
                action()
            }
        }) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.button) // 16pt, medium
                    .foregroundColor(isEnabled ? .white : .textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(12) // Button.padding = 12
            .background(isEnabled ? Color.primaryAccent : Color.buttonDisabled)
            .cornerRadius(Radius.md) // Button.cornerRadius = Radius.md (8)
            .shadow(
                color: isEnabled ? Shadow.button.color : Color.clear,
                radius: isEnabled ? Shadow.button.radius : 0,
                x: Shadow.button.x,
                y: Shadow.button.y
            )
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Secondary Button (Design System: padding=12, cornerRadius=md=8, font=16pt medium)
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: {
            if isEnabled {
                HapticFeedback.selection()
                action()
            }
        }) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.button) // 16pt, medium
                    .foregroundColor(isEnabled ? .primaryAccent : .textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(12) // Button.padding = 12
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md) // Button.cornerRadius = Radius.md (8)
                    .stroke(isEnabled ? Color.primaryAccent : Color.buttonDisabled, lineWidth: 1)
            )
            .cornerRadius(Radius.md) // Button.cornerRadius = Radius.md (8)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Text Button (Design System: font=16pt medium)
struct TextButton: View {
    let title: String
    let action: () -> Void
    var color: Color = .primaryAccent
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: {
            if isEnabled {
                HapticFeedback.selection()
                action()
            }
        }) {
            Text(title)
                .font(.label) // 16pt, medium
                .foregroundColor(isEnabled ? color : .textTertiary)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Primary Card (Design System: padding=16, cornerRadius=lg=10)
struct PrimaryCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16 // Card.padding = 16
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding) // Card.padding = 16
            .background(Color.card) // Card background = #ffffff
            .cornerRadius(Radius.lg) // Card.cornerRadius = Radius.lg (10)
            .shadow(
                color: Shadow.card.color,
                radius: Shadow.card.radius,
                x: Shadow.card.x,
                y: Shadow.card.y
            )
    }
}

// MARK: - Progress Indicators

struct ProgressBar: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let height: CGFloat
    
    init(
        value: Double,
        maxValue: Double,
        color: Color = .primaryAccent,
        height: CGFloat = 8
    ) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.height = height
    }
    
    private var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.textTertiary.opacity(0.2))
                    .frame(height: height)
                
                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(
                        width: geometry.size.width * percentage,
                        height: height
                    )
            }
        }
        .frame(height: height)
    }
}

struct StatRing: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(
        value: Double,
        maxValue: Double,
        color: Color = .primaryAccent,
        lineWidth: CGFloat = 12,
        size: CGFloat = 80
    ) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }
    
    private var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.textTertiary.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            
            // Value text
            VStack(spacing: 2) {
                Text("\(Int(value))")
                    .font(.system(size: size * 0.25, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                if maxValue > 0 {
                    Text("of \(Int(maxValue))")
                        .font(.system(size: size * 0.15, weight: .regular))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Badges

// MARK: - Badge View (Design System: cornerRadius=sm=6)
struct BadgeView: View {
    let text: String
    var color: Color = .primaryAccent
    var size: BadgeSize = .medium
    
    enum BadgeSize {
        case small
        case medium
        case large
        
        var font: Font {
            switch self {
            case .small: return .labelSmall
            case .medium: return .label // 16pt, medium
            case .large: return .bodySmall
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return Spacing.xs
            case .medium: return Spacing.sm
            case .large: return Spacing.md
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(color == .success ? .white : .textPrimary)
            .padding(.horizontal, size.padding)
            .padding(.vertical, size.padding / 2)
            .background(color == .success ? color : color.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm) // Badge cornerRadius = Radius.sm (6)
                    .stroke(color == .success ? Color.clear : color, lineWidth: color == .success ? 0 : 1)
            )
            .cornerRadius(Radius.sm) // Badge cornerRadius = Radius.sm (6)
    }
}

// MARK: - Section Headers (Design System: font=h2=20pt medium)
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.h2) // 20pt, medium
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            if let action = action, let actionTitle = actionTitle {
                TextButton(title: actionTitle, action: action)
            }
        }
    }
}

// MARK: - Interactive Card (for tappable items - uses PrimaryCard with padding=16, cornerRadius=lg=10)
struct InteractiveCard<Content: View>: View {
    let content: Content
    let action: (() -> Void)?
    var isEnabled: Bool = true
    
    init(
        isEnabled: Bool = true,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isEnabled = isEnabled
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Group {
            if let action = action, isEnabled {
                Button(action: {
                    HapticFeedback.selection()
                    action()
                }) {
                    PrimaryCard { // Uses Card.padding=16, Card.cornerRadius=lg=10
                        content
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                PrimaryCard { // Uses Card.padding=16, Card.cornerRadius=lg=10
                    content
                        .opacity(isEnabled ? 1.0 : 0.6)
                }
            }
        }
    }
}

