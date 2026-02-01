//
//  OnboardingWelcomeView.swift
//  NutriNav
//
//  Welcome/onboarding screen
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToOnboarding = false
    @State private var showSignIn = false
    
    var body: some View {
        ZStack {
            // Light green/off-white background
            Color(hex: "F1F8F4")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer()
                        .frame(height: 60)
                    
                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryAccent)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    // App Name (Design System: h1=24pt medium)
                    Text("NutriNav")
                        .font(.h1) // 24pt, medium
                        .foregroundColor(.textPrimary)
                    
                    // Tagline (Design System: input=16pt regular)
                    Text("Your smart nutrition assistant")
                        .font(.input) // 16pt, regular
                        .foregroundColor(.textSecondary)
                    
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
                    .padding(.top, Spacing.xl)
                    
                    // CTA Buttons
                    VStack(spacing: Spacing.md) {
                        PrimaryButton(
                            title: "Get Started",
                            action: {
                                navigateToOnboarding = true
                            }
                        )
                        
                        SecondaryButton(
                            title: "Sign In",
                            action: {
                                showSignIn = true
                            }
                        )
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                    
                    // Disclaimer
                    Text("By continuing, you agree to our Terms & Privacy Policy.")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xl)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToOnboarding) {
            OnboardingPersonalInfoView()
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .environmentObject(appState)
        }
    }
}

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

