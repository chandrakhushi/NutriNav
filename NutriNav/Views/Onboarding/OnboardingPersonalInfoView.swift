//
//  OnboardingPersonalInfoView.swift
//  NutriNav
//
//  Step 1: Personal info (Sex, DOB, height, weight) - Single Page
//

import SwiftUI

struct OnboardingPersonalInfoView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Data State
    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -23, to: Date()) ?? Date()
    @State private var selectedGender: Gender?
    @State private var height: Double = 164 // cm
    @State private var weight: Double = 65 // kg
    
    // Unit selection
    @State private var useMetric: Bool = true
    
    // Imperial height helpers
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 5
    @State private var weightPounds: Double = 143
    
    // Sheet State
    @State private var activeSheet: PersonalInfoSheet?
    private enum PersonalInfoSheet: Identifiable {
        case dob, height, weight
        var id: Self { self }
    }
    
    @State private var navigateToNext = false
    
    var body: some View {
        ZStack {
            // Background
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header moved inside ScrollView for centering, but kept separate for logic if needed
                
                // ScrollView with Centering
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            Spacer() // Push content to center
                            
                            // Header
                            headerView
                                .padding(.bottom, Spacing.md)
                            
                            // 1. Sex Section (Binary)
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Sex assigned at birth")
                                    .font(.heading3)
                                    .foregroundColor(.textPrimary)
                                
                                HStack(spacing: Spacing.md) {
                                    GenderCard(
                                        gender: .female,
                                        selected: selectedGender == .female
                                    ) {
                                        selectedGender = .female
                                        HapticFeedback.selection()
                                    }
                                    
                                    GenderCard(
                                        gender: .male,
                                        selected: selectedGender == .male
                                    ) {
                                        selectedGender = .male
                                        HapticFeedback.selection()
                                    }
                                }
                            }
                            
                            // 2. Date of Birth Section
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Date of Birth")
                                    .font(.heading3)
                                    .foregroundColor(.textPrimary)
                                
                                Button(action: { activeSheet = .dob }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Selected Date")
                                                .font(.labelSmall)
                                                .foregroundColor(.textSecondary)
                                            Text(dateFormatter.string(from: dateOfBirth))
                                                .font(.h3)
                                                .foregroundColor(.textPrimary)
                                        }
                                        Spacer()
                                        Image(systemName: "calendar")
                                            .foregroundColor(.textTertiary)
                                    }
                                    .padding()
                                    .background(Color.card)
                                    .cornerRadius(Radius.lg)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                            }
                            
                            // 3. Height & Weight
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Metrics")
                                    .font(.heading3)
                                    .foregroundColor(.textPrimary)
                                
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    InfoCard(title: "Height", value: heightString, unit: useMetric ? "cm" : "ft/in", icon: "ruler") {
                                        activeSheet = .height
                                    }
                                    InfoCard(title: "Weight", value: weightString, unit: useMetric ? "kg" : "lbs", icon: "scalemass") {
                                        activeSheet = .weight
                                    }
                                }
                            }
                            
                            // Unit Toggle
                            HStack {
                                Spacer()
                                UnitToggle(isMetric: $useMetric) { convertUnits() }
                            }
                            
                            Spacer() // Push content to center
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .frame(minHeight: geometry.size.height)
                    }
                }
                
                // Footer
                VStack {
                    PrimaryButton(
                        title: "Continue",
                        action: {
                            saveData()
                            navigateToNext = true
                        },
                        icon: "arrow.right"
                    )
                    .disabled(selectedGender == nil)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.sm)
                .background(Color.background.opacity(0.95))
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $activeSheet) { item in
            switch item {
            case .dob:
                DOBPickerSheet(date: $dateOfBirth)
            case .height:
                if useMetric {
                    HeightPickerSheetMetric(height: $height)
                } else {
                    HeightPickerSheetImperial(feet: $heightFeet, inches: $heightInches)
                }
            case .weight:
                if useMetric {
                    WeightPickerSheetMetric(weight: $weight)
                } else {
                    WeightPickerSheetImperial(weight: $weightPounds)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToNext) {
            OnboardingActivityView()
        }
    }
    
    // MARK: - Helpers
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var headerView: some View {
        VStack(spacing: Spacing.xs) {
            Text("Step 1 of 3")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            
            Text("Let's Get Personal")
                .font(.h2)
                .foregroundColor(.textPrimary)
            
            // Subtle progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary)
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.primaryAccent)
                        .frame(width: geo.size.width * 0.33, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.top, Spacing.sm)
            .padding(.horizontal, Spacing.xl)
        }
        .padding(.top, Spacing.sm)
    }
    
    private var heightString: String {
        if useMetric {
            return "\(Int(height))"
        } else {
            return "\(heightFeet)' \(heightInches)\""
        }
    }
    
    private var weightString: String {
        if useMetric {
            return "\(Int(weight))"
        } else {
            return "\(Int(weightPounds))"
        }
    }
    
    private func convertUnits() {
        if useMetric {
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
    
    private func saveData() {
        // Ensure we save in Metric
        var finalHeight = height
        var finalWeight = weight
        
        if !useMetric {
             finalHeight = Double(heightFeet * 12 + heightInches) * 2.54
             finalWeight = weightPounds * 0.453592
        }
        
        appState.user.dateOfBirth = dateOfBirth
        appState.user.gender = selectedGender
        appState.user.height = finalHeight
        appState.user.weight = finalWeight
    }
}

// MARK: - Components

struct GenderCard: View {
    let gender: Gender
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                Text(gender.emoji)
                    .font(.system(size: 32))
                
                Text(gender.rawValue)
                    .font(.labelSmall)
                    .foregroundColor(selected ? .primaryAccent : .textSecondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, 4)
            .background(selected ? Color.primaryAccent.opacity(0.1) : Color.card)
            .cornerRadius(Radius.lg)
            .overlay(
                 RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(selected ? Color.primaryAccent : Color.border, lineWidth: selected ? 2 : 1)
            )
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.primaryAccent)
                        .font(.system(size: 16))
                    Spacer()
                    Text(title)
                        .font(.labelSmall)
                        .foregroundColor(.textSecondary)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.h2)
                        .foregroundColor(.textPrimary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(unit)
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.card)
            .cornerRadius(Radius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct UnitToggle: View {
    @Binding var isMetric: Bool
    var onChange: () -> Void
    
    var body: some View {
        Button(action: {
            isMetric.toggle()
            onChange()
        }) {
            HStack(spacing: 6) {
                Text(isMetric ? "Metric" : "Imperial")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.primaryAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.card)
            .cornerRadius(Radius.md)
            .overlay(
                 RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
    }
}


// MARK: - Sheets

struct DOBPickerSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Capsule().fill(Color.border).frame(width: 40, height: 4).padding(.top, 10)
            Text("Date of Birth").font(.h3).padding(.top)
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            PrimaryButton(title: "Done", action: { dismiss() })
                .padding()
        }
        .presentationDetents([.fraction(0.40)])
    }
}

struct HeightPickerSheetMetric: View {
    @Binding var height: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Capsule().fill(Color.border).frame(width: 40, height: 4).padding(.top, 10)
            Text("Height (cm)").font(.h3).padding(.top)
            
            Picker("Height", selection: $height) {
                ForEach(Array(stride(from: 100.0, to: 251.0, by: 1.0)), id: \.self) { val in
                    Text(String(format: "%.0f", val)).tag(val)
                }
            }
            .pickerStyle(.wheel)
            
            PrimaryButton(title: "Done", action: { dismiss() })
                .padding()
        }
        .presentationDetents([.fraction(0.4)])
    }
}

struct HeightPickerSheetImperial: View {
    @Binding var feet: Int
    @Binding var inches: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Capsule().fill(Color.border).frame(width: 40, height: 4).padding(.top, 10)
            Text("Height (ft/in)").font(.h3).padding(.top)
            
            HStack {
                Picker("Feet", selection: $feet) {
                    ForEach(3...8, id: \.self) { val in Text("\(val) ft").tag(val) }
                }.pickerStyle(.wheel)
                
                Picker("Inches", selection: $inches) {
                    ForEach(0...11, id: \.self) { val in Text("\(val) in").tag(val) }
                }.pickerStyle(.wheel)
            }
            
            PrimaryButton(title: "Done", action: { dismiss() })
                .padding()
        }
        .presentationDetents([.fraction(0.4)])
    }
}

struct WeightPickerSheetMetric: View {
    @Binding var weight: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Capsule().fill(Color.border).frame(width: 40, height: 4).padding(.top, 10)
            Text("Weight (kg)").font(.h3).padding(.top)
            
            Picker("Weight", selection: $weight) {
                ForEach(Array(stride(from: 30.0, through: 200.0, by: 1.0)), id: \.self) { val in
                    Text(String(format: "%.0f", val)).tag(val)
                }
            }
            .pickerStyle(.wheel)
            
            PrimaryButton(title: "Done", action: { dismiss() })
                .padding()
        }
        .presentationDetents([.fraction(0.4)])
    }
}

struct WeightPickerSheetImperial: View {
    @Binding var weight: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Capsule().fill(Color.border).frame(width: 40, height: 4).padding(.top, 10)
            Text("Weight (lbs)").font(.h3).padding(.top)
            
             Picker("Weight", selection: $weight) {
                ForEach(Array(stride(from: 66.0, through: 440.0, by: 1.0)), id: \.self) { val in
                    Text(String(format: "%.0f", val)).tag(val)
                }
            }
            .pickerStyle(.wheel)
            
            PrimaryButton(title: "Done", action: { dismiss() })
                .padding()
        }
        .presentationDetents([.fraction(0.4)])
    }
}
