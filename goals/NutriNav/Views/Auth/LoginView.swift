//
//  LoginView.swift
//  NutriNav
//
//  Sign up / Login screen - using DesignSystem
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea() // Design System: background = #ffffff
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .fill(Color.cardBackground)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.success)
                }
                .overlay(
                    Circle()
                        .fill(Color.warning)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.primaryBackground)
                        )
                        .offset(x: 35, y: -35)
                )
                
                // Title (Design System: h1=24pt medium, input=16pt regular)
                VStack(spacing: Spacing.sm) {
                    Text("NutriNav")
                        .font(.h1) // 24pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text("Your glow-up starts here ✨")
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Login/Sign Up Form
                VStack(spacing: Spacing.lg) {
                    // Email (Design System: label=16pt medium, input=16pt regular, inputBackground=#f3f3f5, cornerRadius=md=8)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Email")
                            .font(.label) // 16pt, medium
                            .foregroundColor(.textPrimary)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textPrimary)
                            .padding(Spacing.md)
                            .background(Color.inputBackground) // #f3f3f5
                            .cornerRadius(Radius.md) // Button cornerRadius = 8
                    }
                    
                    // Password (Design System: label=16pt medium, input=16pt regular, inputBackground=#f3f3f5, cornerRadius=md=8)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Password")
                            .font(.label) // 16pt, medium
                            .foregroundColor(.textPrimary)
                        
                        SecureField("Enter your password", text: $password)
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textPrimary)
                            .padding(Spacing.md)
                            .background(Color.inputBackground) // #f3f3f5
                            .cornerRadius(Radius.md) // Button cornerRadius = 8
                    }
                    
                    // Primary action button
                    PrimaryButton(
                        title: isLogin ? "Sign In" : "Sign Up",
                        action: {
                            HapticFeedback.impact()
                            // TODO: Implement authentication
                            // For MVP, just proceed to onboarding
                            showOnboarding = true
                            AnalyticsService.shared.trackOnboardingCompleted(age: 0, gender: "Unknown", goal: "Unknown")
                        },
                        icon: isLogin ? "person.fill" : "person.badge.plus"
                    )
                    
                    // Toggle login/signup
                    TextButton(
                        title: isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
                        action: {
                            HapticFeedback.selection()
                            isLogin.toggle()
                        }
                    )
                    
                    // Skip for now
                    TextButton(
                        title: "Continue as Guest",
                        action: {
                            HapticFeedback.selection()
                            showOnboarding = true
                        },
                        color: .textSecondary
                    )
                }
                .padding(.horizontal, Spacing.xl)
                
                Spacer()
                
                // Disclaimer
                Text("Free to start • No credit card required")
                    .font(.bodySmall)
                    .foregroundColor(.textTertiary)
                    .padding(.bottom, Spacing.xl)
            }
        }
        .navigationDestination(isPresented: $showOnboarding) {
            OnboardingWelcomeView()
        }
    }
}
