//
//  LoginView.swift
//  NutriNav
//
//  Sign up / Login screen
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
            // Gradient background
            LinearGradient(
                colors: [Color.appPurple, Color.appPink, Color.appOrange],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
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
                
                // Title
                VStack(spacing: 8) {
                    Text("NutriNav")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your glow-up starts here ✨")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Login/Sign Up Form
                VStack(spacing: 20) {
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        SecureField("Enter your password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    // Primary action button
                    Button(action: {
                        // TODO: Implement authentication
                        // For MVP, just proceed to onboarding
                        showOnboarding = true
                        AnalyticsService.shared.trackOnboardingCompleted(age: 0, gender: "Unknown", goal: "Unknown")
                    }) {
                        Text(isLogin ? "Sign In" : "Sign Up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appPurple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                    }
                    
                    // Toggle login/signup
                    Button(action: {
                        isLogin.toggle()
                    }) {
                        Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Skip for now
                    Button(action: {
                        showOnboarding = true
                    }) {
                        Text("Continue as Guest")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Disclaimer
                Text("Free to start • No credit card required")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 40)
            }
        }
        .navigationDestination(isPresented: $showOnboarding) {
            OnboardingWelcomeView()
        }
    }
}

