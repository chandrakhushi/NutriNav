//
//  OnboardingStatsView.swift
//  NutriNav
//
//  Step 2: Stats (height, weight)
//

import SwiftUI

struct OnboardingStatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var height: Double = 164
    @State private var weight: Double = 65
    @State private var navigateToNext = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case height, weight
    }
    
    var body: some View {
        ZStack {
            // White background matching Figma design
            Color.primaryBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Progress indicator
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("Step 2 of 4")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "rocket.fill")
                                    .font(.system(size: 12))
                                Text("50% there!")
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.warning)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        ProgressView(value: 0.5)
                            .tint(.primaryAccent)
                            .background(Color.textTertiary.opacity(0.2))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .padding(.horizontal, Spacing.md)
                    }
                    .padding(.top, Spacing.xxl)
                    
                    // Title
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            Text("Your Stats")
                                .font(.heading1)
                                .foregroundColor(.textPrimary)
                            
                            Image(systemName: "ruler.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.proteinColor)
                                .rotationEffect(.degrees(15))
                        }
                        
                        Text("We need these to calculate your perfect nutrition plan")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Height input
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Height (cm)")
                            .font(.heading3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        HStack {
                            TextField("", value: $height, format: .number)
                                .font(.heading2)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .height)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(Color.white)
                                .cornerRadius(CornerRadius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.button)
                                        .stroke(focusedField == .height ? Color.primaryAccent : Color.textTertiary.opacity(0.2), lineWidth: focusedField == .height ? 2 : 1)
                                )
                                .overlay(
                                    HStack {
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.textTertiary)
                                            .padding(.trailing, Spacing.md)
                                    }
                                )
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    // Weight input
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Weight (kg)")
                            .font(.heading3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        HStack {
                            TextField("", value: $weight, format: .number)
                                .font(.heading2)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: .weight)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(Color.white)
                                .cornerRadius(CornerRadius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.button)
                                        .stroke(focusedField == .weight ? Color.primaryAccent : Color.textTertiary.opacity(0.2), lineWidth: focusedField == .weight ? 2 : 1)
                                )
                                .overlay(
                                    HStack {
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.textTertiary)
                                            .padding(.trailing, Spacing.md)
                                    }
                                )
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    Spacer(minLength: Spacing.xl)
                    
                    // Navigation buttons - using DesignSystem
                    HStack(spacing: Spacing.md) {
                        SecondaryButton(
                            title: "Back",
                            action: {
                                // Go back handled by navigation
                            }
                        )
                        
                        PrimaryButton(
                            title: "Continue",
                            action: {
                                appState.user.height = height
                                appState.user.weight = weight
                                navigateToNext = true
                            },
                            icon: "arrow.right"
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingActivityView()
        }
    }
}

