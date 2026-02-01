//
//  EditProfileView.swift
//  NutriNav
//
//  Edit personal information and goals
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    // Form State
    @State private var name: String = ""
    @State private var height: Double = 164 // cm
    @State private var weight: Double = 65 // kg
    @State private var dateOfBirth: Date = Date()
    @State private var gender: Gender = .female
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var goal: FitnessGoal = .maintainWeight
    
    // UI State
    @State private var useMetric: Bool = true
    
    // Imperial Helpers
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 5
    @State private var weightPounds: Double = 143
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Name", text: $name)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                }
                
                Section(header: Text("Body Metrics")) {
                    Toggle("Use Metric Units", isOn: $useMetric)
                        .onChange(of: useMetric) { newValue in
                            convertUnits(toMetric: newValue)
                        }
                    
                    if useMetric {
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Height", value: $height, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("cm").foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("Weight", value: $weight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("kg").foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Height")
                            Spacer()
                            Picker("", selection: $heightFeet) {
                                ForEach(3...8, id: \.self) { Text("\($0) ft").tag($0) }
                            }.labelsHidden()
                            
                            Picker("", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                            }.labelsHidden()
                        }
                        
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("Weight", value: $weightPounds, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("lbs").foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Goals & Activity")) {
                    Picker("Goal", selection: $goal) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
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
    
    // MARK: - Logic
    
    private func loadData() {
        name = appState.user.name
        if let h = appState.user.height { height = h }
        if let w = appState.user.weight { weight = w }
        if let dob = appState.user.dateOfBirth { dateOfBirth = dob }
        if let g = appState.user.gender { gender = g }
        if let a = appState.user.activityLevel { activityLevel = a }
        if let gl = appState.user.goal { goal = gl }
        
        // Initialize imperial values
        convertUnits(toMetric: false) // Calculate imperial from loaded metric
        useMetric = true // Default to metric view initially or load pref
    }
    
    private func saveChanges() {
        appState.user.name = name
        appState.user.dateOfBirth = dateOfBirth
        appState.user.gender = gender
        appState.user.activityLevel = activityLevel
        appState.user.goal = goal
        
        if useMetric {
            appState.user.height = height
            appState.user.weight = weight
        } else {
            let totalInches = Double(heightFeet * 12 + heightInches)
            appState.user.height = totalInches * 2.54
            appState.user.weight = weightPounds * 0.453592
        }
        
        // Recalculate
        appState.recalculateNutritionGoals()
    }
    
    private func convertUnits(toMetric: Bool) {
        if toMetric {
            // Imperial -> Metric
            let totalInches = Double(heightFeet * 12 + heightInches)
            height = totalInches * 2.54
            weight = weightPounds * 0.453592
        } else {
            // Metric -> Imperial
            let totalInches = Int(height / 2.54)
            heightFeet = totalInches / 12
            heightInches = totalInches % 12
            weightPounds = weight * 2.20462
        }
    }
}
