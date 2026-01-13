//
//  OnboardingPersonalInfoView.swift
//  NutriNav
//
//  Step 1: Personal info (age, gender)
//

import SwiftUI

struct OnboardingPersonalInfoView: View {
    @EnvironmentObject var appState: AppState
    @State private var age: Int = 23
    @State private var selectedGender: Gender?
    @State private var navigateToNext = false
    
    var body: some View {
        ZStack {
            // White background matching Figma design
            Color.primaryBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Progress indicator
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("Step 1 of 4")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text("25% there!")
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.warning)
                        }
                        .padding(.horizontal, Spacing.md)
                        
                        ProgressView(value: 0.25)
                            .tint(.primaryAccent)
                            .background(Color.textTertiary.opacity(0.2))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .padding(.horizontal, Spacing.md)
                    }
                    .padding(.top, Spacing.xxl)
                    
                    // Title
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            Text("Let's Get Personal!")
                                .font(.heading1)
                                .foregroundColor(.textPrimary)
                            
                            Text("✨")
                                .font(.body)
                        }
                        
                        Text("Tell us about you so we can customize your experience")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Age input
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("How old are you?")
                            .font(.heading3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        HStack {
                            TextField("", value: $age, format: .number)
                                .font(.heading2)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(Color.white)
                                .cornerRadius(CornerRadius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.button)
                                        .stroke(Color.textTertiary.opacity(0.2), lineWidth: 1)
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
                    
                    // Gender selection
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Gender")
                            .font(.heading3)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, Spacing.md)
                        
                        HStack(spacing: Spacing.md) {
                            GenderButton(
                                gender: .female,
                                isSelected: selectedGender == .female
                            ) {
                                HapticFeedback.selection()
                                selectedGender = .female
                            }
                            
                            GenderButton(
                                gender: .male,
                                isSelected: selectedGender == .male
                            ) {
                                HapticFeedback.selection()
                                selectedGender = .male
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                    
                    Spacer(minLength: Spacing.xl)
                    
                    // Continue button - using DesignSystem PrimaryButton
                    PrimaryButton(
                        title: "Continue",
                        action: {
                            appState.user.age = age
                            appState.user.gender = selectedGender
                            navigateToNext = true
                        },
                        icon: "arrow.right"
                    )
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                    .disabled(selectedGender == nil)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingStatsView()
        }
    }
}

// MARK: - Gender Button (DesignSystem aligned)
struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(gender.emoji)
                    .font(.system(size: 24))
                Text(gender.rawValue)
                    .font(.heading3)
            }
            .foregroundColor(isSelected ? .white : .primaryAccent)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(isSelected ? Color.primaryAccent : Color.white)
            .cornerRadius(CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(Color.primaryAccent, lineWidth: 1)
            )
        }
    }
}

