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
            LinearGradient(
                colors: [Color.appPurple, Color.appPink],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Progress indicator
                VStack(spacing: 10) {
                    HStack {
                        Text("Step 1 of 4")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text("25% there!")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 20)
                    
                    ProgressView(value: 0.25)
                        .tint(.yellow)
                        .background(Color.white.opacity(0.3))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Title
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Let's Get Personal!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("✨")
                            .font(.system(size: 20))
                    }
                    
                    Text("Tell us about you so we can customize your experience")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Age input
                VStack(alignment: .leading, spacing: 10) {
                    Text("How old are you?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        TextField("", value: $age, format: .number)
                            .font(.system(size: 24, weight: .bold))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                HStack {
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 15)
                                }
                            )
                    }
                    .padding(.horizontal, 20)
                }
                
                // Gender selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Gender")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 15) {
                        GenderButton(
                            gender: .female,
                            isSelected: selectedGender == .female
                        ) {
                            selectedGender = .female
                        }
                        
                        GenderButton(
                            gender: .male,
                            isSelected: selectedGender == .male
                        ) {
                            selectedGender = .male
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    appState.user.age = age
                    appState.user.gender = selectedGender
                    navigateToNext = true
                }) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.appPurple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .disabled(selectedGender == nil)
                .opacity(selectedGender == nil ? 0.6 : 1.0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingStatsView()
        }
    }
}

struct GenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(gender.emoji)
                    .font(.system(size: 24))
                Text(gender.rawValue)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(isSelected ? .appPurple : .white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.white : Color.appPurple.opacity(0.3))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.appPurple : Color.appPurple.opacity(0.5), lineWidth: 2)
            )
        }
    }
}

