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
                
                // Title
                VStack(spacing: Spacing.sm) {
                    Text("NutriNav")
                        .font(.h1)
                        .foregroundColor(.textPrimary)
                    
                    Text("Your glow-up starts here ✨")
                        .font(.input)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Sign In Button
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
                    
                    Text("We don’t see your password or email")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                    
                    #if DEBUG
                    Button("DEBUG: Skip Auth") {
                        appState.debugBypassAuth()
                    }
                    .padding(.top, 20)
                    .foregroundColor(.red)
                    #endif
                }
                .padding(.bottom, Spacing.xl * 2)
            }
        }
    }
}
