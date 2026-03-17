//
//  SignInView.swift
//  NutriNav
//
//  Authentication screen using Sign in with Apple
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer()
                        .frame(height: 60)
                    
                    // App Icon
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.button)
                                .stroke(Color.border, lineWidth: 1)
                        )
                    // Title
                    VStack(spacing: Spacing.sm) {
                        Text("NutriNav")
                            .font(.h1)
                            .foregroundColor(.textPrimary)
                        
                        Text("Your smart nutrition assistant")
                            .font(.input)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Feature Cards
                    VStack(spacing: Spacing.lg) {
                        FeatureCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Track Your Goals",
                            subtitle: "Monitor calories, protein, and hit your nutrition targets."
                        )
                        
                        FeatureCard(
                            icon: "book.closed.fill",
                            title: "Smart Recipes",
                            subtitle: "Get personalized recipes based on what you have."
                        )
                        
                        FeatureCard(
                            icon: "mappin.circle.fill",
                            title: "Find Nearby Options",
                            subtitle: "Discover restaurants with nutrition info and budget filters."
                        )
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.md)
                    
                    // Sign In Options
                    VStack(spacing: Spacing.lg) {
                        Button(action: {
                            Task {
                                await appState.signInWithApple()
                            }
                        }) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20))
                                Text("Continue with Apple")
                                    .font(.system(size: 19, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(colorScheme == .dark ? Color.white : Color.black)
                            .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                            .cornerRadius(Radius.md)
                        }
                        .padding(.horizontal, Spacing.xl)
                        
                        Button(action: {
                            appState.signInAsGuest()
                        }) {
                            Text("Continue as Guest")
                                .font(.button)
                                .foregroundColor(.textSecondary)
                                .underline()
                        }
                        
                        Text("By continuing, you agree to our Terms & Privacy Policy.")
                            .font(.bodySmall)
                            .foregroundColor(.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.top, Spacing.sm)
                    }
                    .padding(.bottom, Spacing.xl * 2)
                }
            }
        }
    }
}

// Struct for the feature points
struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.primaryAccent.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.primaryAccent)
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
        }
        .padding(Spacing.md)
    }
}
