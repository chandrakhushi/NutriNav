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
            LinearGradient(
                colors: [Color.appPink, Color(red: 0.9, green: 0.3, blue: 0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Progress indicator
                VStack(spacing: 10) {
                    HStack {
                        Text("Step 2 of 4")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "rocket.fill")
                                .font(.system(size: 12))
                            Text("50% there!")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 20)
                    
                    ProgressView(value: 0.5)
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
                        Text("Your Stats")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(15))
                    }
                    
                    Text("We need these to calculate your perfect nutrition plan")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Height input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Height (cm)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        TextField("", value: $height, format: .number)
                            .font(.system(size: 24, weight: .bold))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .height)
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
                
                // Weight input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Weight (kg)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        TextField("", value: $weight, format: .number)
                            .font(.system(size: 24, weight: .bold))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .weight)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(focusedField == .weight ? Color.yellow : Color.clear, lineWidth: 3)
                            )
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
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 15) {
                    Button(action: {
                        // Go back
                    }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        appState.user.height = height
                        appState.user.weight = weight
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingActivityView()
        }
    }
}

