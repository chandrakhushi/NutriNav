//
//  BudgetView.swift
//  NutriNav
//
//  Budget tracking and meal planner screen
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var appState: AppState
    @State private var budget = Budget(weeklyBudget: 100.0, currentWeekSpending: 45.50)
    @State private var expenses: [MealExpense] = []
    @State private var showBudgetEditor = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // White background matching Figma design
                Color.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Budget Summary Card
                        BudgetSummaryCard(budget: budget)
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.xxl)
                        
                        // Weekly Spending Chart
                        WeeklySpendingChart(budget: budget, expenses: expenses)
                            .padding(.horizontal, Spacing.md)
                        
                        // Recent Expenses
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack {
                                SectionHeader(title: "Recent Expenses")
                                
                                Spacer()
                                
                                Button(action: {
                                    HapticFeedback.selection()
                                    showBudgetEditor = true
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primaryAccent)
                                        .padding(Spacing.sm)
                                        .background(Color.primaryAccent.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            
                            if expenses.isEmpty {
                                EmptyExpensesView()
                                    .padding(.horizontal, Spacing.md)
                            } else {
                                ForEach(expenses.prefix(5)) { expense in
                                    ExpenseRow(expense: expense)
                                        .padding(.horizontal, Spacing.md)
                                }
                            }
                        }
                        .padding(.top, Spacing.sm)
                        
                        // Budget Tips
                        BudgetTipsCard()
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, Spacing.xl)
                    }
                }
            }
            .navigationTitle("Budget Tracker")
            .sheet(isPresented: $showBudgetEditor) {
                BudgetEditorView(budget: $budget)
            }
        }
    }
}

// MARK: - Budget Summary Card (DesignSystem aligned)
struct BudgetSummaryCard: View {
    let budget: Budget
    
    // MARK: - Budget Summary Card (Design System: label=16pt medium, h1=24pt medium, card padding=16, cornerRadius=lg=10)
    var body: some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Weekly Budget")
                            .font(.label) // 16pt, medium
                            .foregroundColor(.textSecondary)
                        
                        Text("$\(String(format: "%.2f", budget.weeklyBudget))")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        Text("Remaining")
                            .font(.label) // 16pt, medium
                            .foregroundColor(.textSecondary)
                        
                        Text("$\(String(format: "%.2f", budget.remaining))")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(budget.remaining > 0 ? .success : .error)
                    }
                }
                
                // Progress bar - using DesignSystem ProgressBar
                ProgressBar(
                    value: budget.currentWeekSpending,
                    maxValue: budget.weeklyBudget,
                    color: budget.percentageUsed < 80 ? .success : .calorieColor,
                    height: 8
                )
                
                HStack {
                    Text("Spent: $\(String(format: "%.2f", budget.currentWeekSpending))")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(budget.percentageUsed))% used")
                        .font(.label)
                        .foregroundColor(budget.percentageUsed < 80 ? .success : .calorieColor)
                }
            }
        }
    }
}

// MARK: - Weekly Spending Chart (DesignSystem aligned)
struct WeeklySpendingChart: View {
    let budget: Budget
    let expenses: [MealExpense]
    
    // MARK: - Weekly Spending Chart (Design System: card padding=16, cornerRadius=lg=10, cornerRadius=sm=6)
    var body: some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "This Week's Spending")
                
                // Simple bar chart for each day
                HStack(alignment: .bottom, spacing: Spacing.sm) {
                    ForEach(0..<7) { dayIndex in
                        let dayExpenses = expenses.filter { Calendar.current.component(.weekday, from: $0.date) == dayIndex + 1 }
                        let dayTotal = dayExpenses.reduce(0) { $0 + $1.cost }
                        let maxSpending = expenses.map { $0.cost }.max() ?? 1
                        
                        VStack(spacing: Spacing.xs) {
                            RoundedRectangle(cornerRadius: Radius.sm) // Small cornerRadius = 6
                                .fill(Color.primaryAccent.opacity(0.6))
                                .frame(width: 40, height: max(20, CGFloat(dayTotal / maxSpending) * 100))
                            
                            Text(dayName(for: dayIndex))
                                .font(.labelSmall)
                                .foregroundColor(.textSecondary)
                            
                            Text("$\(String(format: "%.0f", dayTotal))")
                                .font(.labelSmall)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
        }
    }
    
    private func dayName(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let date = Calendar.current.date(byAdding: .day, value: index - Calendar.current.component(.weekday, from: Date()) + 1, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Expense Row (DesignSystem aligned)
struct ExpenseRow: View {
    let expense: MealExpense
    
    var body: some View {
        PrimaryCard {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(expenseTypeColor(expense.type).opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: expenseTypeIcon(expense.type))
                        .font(.system(size: 24))
                        .foregroundColor(expenseTypeColor(expense.type))
                }
                
                // Details
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(expense.name)
                        .font(.h3) // 18pt, medium
                        .foregroundColor(.textPrimary)
                    
                    Text(expense.type.rawValue)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Text(expense.date, style: .date)
                        .font(.labelSmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Cost
                Text("$\(String(format: "%.2f", expense.cost))")
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.primaryAccent)
            }
        }
    }
    
    private func expenseTypeColor(_ type: ExpenseType) -> Color {
        switch type {
        case .recipe: return .green
        case .restaurant: return .orange
        case .grocery: return .blue
        case .other: return .gray
        }
    }
    
    private func expenseTypeIcon(_ type: ExpenseType) -> String {
        switch type {
        case .recipe: return "fork.knife"
        case .restaurant: return "building.2"
        case .grocery: return "cart.fill"
        case .other: return "dollarsign.circle"
        }
    }
}

// MARK: - Empty Expenses View (DesignSystem aligned)
struct EmptyExpensesView: View {
    // MARK: - Empty Expenses View (Design System: h3=18pt medium, card padding=16, cornerRadius=lg=10)
    var body: some View {
        PrimaryCard { // Card.padding=16, Card.cornerRadius=lg=10
            VStack(spacing: Spacing.md) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 50))
                    .foregroundColor(.textTertiary)
                
                Text("No expenses yet")
                    .font(.h3) // 18pt, medium
                    .foregroundColor(.textPrimary)
                
                Text("Start tracking your meal spending to see it here")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.xl)
        }
    }
}

// MARK: - Budget Tips Card (DesignSystem aligned - using solid color background)
struct BudgetTipsCard: View {
    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Text("💰")
                        .font(.system(size: 24))
                    SectionHeader(title: "Budget Tips")
                }
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    TipRow(icon: "lightbulb.fill", text: "Meal prep on weekends saves money")
                    TipRow(icon: "cart.fill", text: "Buy ingredients in bulk for recipes")
                    TipRow(icon: "star.fill", text: "Look for budget-friendly restaurants")
                }
            }
        }
    }
}

// MARK: - Tip Row (DesignSystem aligned)
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.warning)
            
            Text(text)
                .font(.bodySmall)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Budget Editor View (DesignSystem aligned)
struct BudgetEditorView: View {
    @Binding var budget: Budget
    @Environment(\.dismiss) var dismiss
    @State private var newBudget: Double = 100.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // White background matching Figma design
                Color.background.ignoresSafeArea() // Design System: background = #ffffff
                
                VStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.md) {
                        Text("Set Weekly Budget")
                            .font(.h1) // 24pt, medium
                            .foregroundColor(.textPrimary)
                        
                        Text("How much do you want to spend on meals this week?")
                            .font(.input) // 16pt, regular
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, Spacing.xxl)
                    
                    // Budget input
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("$")
                                .font(.h1) // 24pt, medium
                                .foregroundColor(.primaryAccent)
                            
                            TextField("", value: $newBudget, format: .number)
                                .font(.system(size: 48, weight: .bold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.textPrimary)
                        }
                        .padding(Spacing.md)
                        .background(Color.inputBackground) // #f3f3f5
                        .cornerRadius(Radius.md) // Button cornerRadius = 8
                        .padding(.horizontal, Spacing.xl)
                        
                        // Quick presets
                        HStack(spacing: Spacing.md) {
                            BudgetPresetButton(amount: 50, current: $newBudget)
                            BudgetPresetButton(amount: 100, current: $newBudget)
                            BudgetPresetButton(amount: 150, current: $newBudget)
                            BudgetPresetButton(amount: 200, current: $newBudget)
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                    
                    Spacer()
                    
                    // Save button - using DesignSystem
                    PrimaryButton(
                        title: "Save Budget",
                        action: {
                            HapticFeedback.success()
                            budget.weeklyBudget = newBudget
                            dismiss()
                        }
                    )
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticFeedback.selection()
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
            .onAppear {
                newBudget = budget.weeklyBudget
            }
        }
    }
}

// MARK: - Budget Preset Button (DesignSystem aligned)
struct BudgetPresetButton: View {
    let amount: Double
    @Binding var current: Double
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            current = amount
        }) {
            Text("$\(Int(amount))")
                .font(.label) // 16pt, medium
                .foregroundColor(current == amount ? .white : .primaryAccent)
                .frame(maxWidth: .infinity)
                .padding(12) // Button.padding = 12
                .background(current == amount ? Color.primaryAccent : Color.primaryAccent.opacity(0.1))
                .cornerRadius(Radius.md) // Button cornerRadius = 8
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md) // Button cornerRadius = 8
                        .stroke(Color.primaryAccent, lineWidth: 1)
                )
        }
    }
}

