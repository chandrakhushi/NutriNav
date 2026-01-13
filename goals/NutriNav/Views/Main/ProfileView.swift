//
//  ProfileView.swift
//  NutriNav
//
//  Profile screen - using DesignSystem
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPremium = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xxl)
                        
                        // Goals Section
                        goalsSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Settings Section
                        settingsSection
                            .padding(.horizontal, Spacing.md)
                        
                        // Personal Info
                        personalInfoSection
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
                    .environmentObject(appState)
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    HapticFeedback.impact()
                    // TODO: Implement sign out logic
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Header (Design System: h2=20pt medium, h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private var headerSection: some View {
        VStack(spacing: Spacing.lg) {
            // Profile Info
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.primaryAccent)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(appState.user.name)
                        .font(.h2) // 20pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text(appState.user.email)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            
            // Premium Banner - Tappable
            Button(action: {
                showPremium = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Upgrade to Premium")
                            .font(.h3) // 18pt, medium
                            .foregroundColor(.white)
                        
                        Text("Unlock all features")
                            .font(.bodySmall)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(16) // Card.padding = 16
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FF9800"), Color(hex: "FFC107")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Radius.lg) // Card.cornerRadius = Radius.lg (10)
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Goals & Preferences")
            
            goalRow(
                title: "Nutrition Goals",
                subtitle: "\(Int(appState.dailyNutrition.calories.target)) cal, \(Int(appState.dailyNutrition.protein.target))g protein",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Color(hex: "FF9800"),
                action: {
                    // TODO: Navigate to nutrition goals editor
                }
            )
            
            goalRow(
                title: "Dietary Restrictions",
                subtitle: "Gluten-free, Vegetarian",
                icon: "leaf.fill",
                iconColor: Color(hex: "9C27B0"),
                action: {
                    // TODO: Navigate to dietary preferences
                }
            )
            
            NavigationLink(destination: CycleView().environmentObject(appState)) {
                goalRow(
                    title: "Cycle & Workout Sync",
                    subtitle: "Adapt recommendations",
                    icon: "calendar.badge.clock",
                    iconColor: Color(hex: "E91E63"),
                    action: nil // NavigationLink handles this
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Goal Row (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10, button cornerRadius=md=8)
    private func goalRow(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        action: (() -> Void)?
    ) -> some View {
        InteractiveCard(action: action) { // Card.padding=16, Card.cornerRadius=lg=10
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.h3) // 18pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "App Settings")
            
            settingsRow(title: "Notifications", icon: "bell.fill", iconColor: Color(hex: "2196F3")) {
                // TODO: Navigate to notifications settings
            }
            
            settingsRow(title: "Privacy & Security", icon: "shield.fill", iconColor: Color(hex: "4CAF50")) {
                // TODO: Navigate to privacy settings
            }
            
            settingsRow(title: "Help & Support", icon: "questionmark.circle.fill", iconColor: Color(hex: "9E9E9E")) {
                // TODO: Navigate to help & support
            }
        }
    }
    
    // MARK: - Settings Row (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private func settingsRow(title: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        InteractiveCard(action: action) { // Card.padding=16, Card.cornerRadius=lg=10
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    // MARK: - Personal Info (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Account")
            
            InteractiveCard(action: {
                // TODO: Navigate to personal info editor
            }) { // Card.padding=16, Card.cornerRadius=lg=10
                HStack {
                    Text("Personal Information")
                        .font(.h3) // 18pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textTertiary)
                }
            }
            
            Button(action: {
                showSignOutConfirmation = true
            }) {
                Text("Sign Out")
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            
            // App Version
            Text("NutriNav v1.0.0")
                .font(.bodySmall)
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.md)
        }
    }
}

// MARK: - Premium View (Placeholder)

// MARK: - Premium View (Design System: h1=24pt medium, input=16pt regular)
struct PremiumView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        Text("Premium Features")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Text("Unlock all features coming soon")
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationTitle("Premium")
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
        }
    }
}
