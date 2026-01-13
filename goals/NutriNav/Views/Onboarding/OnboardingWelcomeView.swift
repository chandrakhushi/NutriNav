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
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.appPurple, Color.appPink, Color.appOrange],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 60)
                    
                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    }
                    .overlay(
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 35, y: -35)
                    )
                    
                    // App Name
                    Text("NutriNav")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Tagline
                    Text("Your glow-up starts here ✨")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Feature Cards
                    VStack(spacing: 15) {
                        FeatureCard(
                            icon: "chart.bar.fill",
                            title: "Track Your Wins",
                            subtitle: "Hit your goals & celebrate progress"
                        )
                        
                        FeatureCard(
                            icon: "fork.knife",
                            title: "Delicious Recipes",
                            subtitle: "Eat well without the stress"
                        )
                        
                        FeatureCard(
                            icon: "figure.strengthtraining.traditional",
                            title: "Feel Amazing",
                            subtitle: "Energy, confidence, & balance"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // CTA Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            navigateToOnboarding = true
                        }) {
                            HStack {
                                Text("Let's Glow!")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("✨")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.appPurple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                        }
                        
                        Button(action: {
                            // Handle existing account
                        }) {
                            Text("I Already Have an Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appPink.opacity(0.3))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Disclaimer
                    Text("Free to start • No credit card required")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToOnboarding) {
            OnboardingPersonalInfoView()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.appPink.opacity(0.3))
        .cornerRadius(15)
    }
}

