//
//  NutritionGoalsView.swift
//  NutriNav
//
//  Edit nutrition targets (Macros & Calories)
//

import SwiftUI

struct NutritionGoalsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    // Editing State
    @State private var calorieTarget: Double = 2000
    @State private var proteinTarget: Double = 150
    @State private var carbsTarget: Double = 200
    @State private var fatsTarget: Double = 60
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Daily Targets")) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("Calories", value: $calorieTarget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kcal").foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("Protein", value: $proteinTarget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g").foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("Carbs", value: $carbsTarget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g").foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Fats")
                        Spacer()
                        TextField("Fats", value: $fatsTarget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g").foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Reset to Recommended") {
                        resetToCalculated()
                    }
                    .foregroundColor(.blue)
                } footer: {
                    if appState.dailyNutrition.isCustom {
                        Text("You are currently using custom goals.")
                    } else {
                        Text("Example calculated based on your profile.")
                    }
                }
            }
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.headline)
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        calorieTarget = appState.dailyNutrition.calories.target
        proteinTarget = appState.dailyNutrition.protein.target
        carbsTarget = appState.dailyNutrition.carbs.target
        fatsTarget = appState.dailyNutrition.fats.target
    }
    
    private func saveChanges() {
        appState.updateNutritionTargets(
            calories: calorieTarget,
            protein: proteinTarget,
            carb: carbsTarget,
            fat: fatsTarget
        )
    }
    
    private func resetToCalculated() {
        // Reset the custom flag
        appState.dailyNutrition.isCustom = false
        // Trigger recalculation
        appState.recalculateNutritionGoals()
        // Reload local state
        loadData()
    }
}
