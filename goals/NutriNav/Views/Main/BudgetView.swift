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
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Summary Card
                    BudgetSummaryCard(budget: budget)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Weekly Spending Chart
                    WeeklySpendingChart(budget: budget, expenses: expenses)
                        .padding(.horizontal, 20)
                    
                    // Recent Expenses
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Recent Expenses")
                                .font(.system(size: 24, weight: .bold))
                            
                            Spacer()
                            
                            Button(action: {
                                showBudgetEditor = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.appPurple)
                                    .padding(8)
                                    .background(Color.appPurple.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if expenses.isEmpty {
                            EmptyExpensesView()
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(expenses.prefix(5)) { expense in
                                ExpenseRow(expense: expense)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    // Budget Tips
                    BudgetTipsCard()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Budget Tracker")
            .sheet(isPresented: $showBudgetEditor) {
                BudgetEditorView(budget: $budget)
            }
        }
    }
}

struct BudgetSummaryCard: View {
    let budget: Budget
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Budget")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    
                    Text("$\(String(format: "%.2f", budget.weeklyBudget))")
                        .font(.system(size: 32, weight: .bold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Remaining")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    
                    Text("$\(String(format: "%.2f", budget.remaining))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(budget.remaining > 0 ? .green : .red)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: budget.percentageUsed < 80 ? [.green, .blue] : [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (budget.percentageUsed / 100), height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("Spent: $\(String(format: "%.2f", budget.currentWeekSpending))")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text("\(Int(budget.percentageUsed))% used")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(budget.percentageUsed < 80 ? .green : .orange)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct WeeklySpendingChart: View {
    let budget: Budget
    let expenses: [MealExpense]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("This Week's Spending")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            // Simple bar chart for each day
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { dayIndex in
                    let dayExpenses = expenses.filter { Calendar.current.component(.weekday, from: $0.date) == dayIndex + 1 }
                    let dayTotal = dayExpenses.reduce(0) { $0 + $1.cost }
                    let maxSpending = expenses.map { $0.cost }.max() ?? 1
                    
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appPurple.opacity(0.6))
                            .frame(width: 40, height: max(20, CGFloat(dayTotal / maxSpending) * 100))
                        
                        Text(dayName(for: dayIndex))
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                        
                        Text("$\(String(format: "%.0f", dayTotal))")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
    
    private func dayName(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let date = Calendar.current.date(byAdding: .day, value: index - Calendar.current.component(.weekday, from: Date()) + 1, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

struct ExpenseRow: View {
    let expense: MealExpense
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(expenseTypeColor(expense.type).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: expenseTypeIcon(expense.type))
                    .font(.system(size: 24))
                    .foregroundColor(expenseTypeColor(expense.type))
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(expense.type.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Text(expense.date, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Cost
            Text("$\(String(format: "%.2f", expense.cost))")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appPurple)
        }
        .padding(15)
        .background(Color.cardBackground)
        .cornerRadius(12)
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

struct EmptyExpensesView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No expenses yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textSecondary)
            
            Text("Start tracking your meal spending to see it here")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

struct BudgetTipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("💰")
                    .font(.system(size: 24))
                Text("Budget Tips")
                    .font(.system(size: 20, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "lightbulb.fill", text: "Meal prep on weekends saves money")
                TipRow(icon: "cart.fill", text: "Buy ingredients in bulk for recipes")
                TipRow(icon: "star.fill", text: "Look for budget-friendly restaurants")
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.appOrange.opacity(0.1), Color.yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.appOrange)
            
            Text(text)
                .font(.system(size: 14))
        }
    }
}

struct BudgetEditorView: View {
    @Binding var budget: Budget
    @Environment(\.dismiss) var dismiss
    @State private var newBudget: Double = 100.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Text("Set Weekly Budget")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("How much do you want to spend on meals this week?")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                // Budget input
                VStack(spacing: 10) {
                    HStack {
                        Text("$")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.appPurple)
                        
                        TextField("", value: $newBudget, format: .number)
                            .font(.system(size: 48, weight: .bold))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal, 40)
                    
                    // Quick presets
                    HStack(spacing: 15) {
                        BudgetPresetButton(amount: 50, current: $newBudget)
                        BudgetPresetButton(amount: 100, current: $newBudget)
                        BudgetPresetButton(amount: 150, current: $newBudget)
                        BudgetPresetButton(amount: 200, current: $newBudget)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Save button
                Button(action: {
                    budget.weeklyBudget = newBudget
                    dismiss()
                }) {
                    Text("Save Budget")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPurple)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                newBudget = budget.weeklyBudget
            }
        }
    }
}

struct BudgetPresetButton: View {
    let amount: Double
    @Binding var current: Double
    
    var body: some View {
        Button(action: {
            current = amount
        }) {
            Text("$\(Int(amount))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(current == amount ? .white : .appPurple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(current == amount ? Color.appPurple : Color.appPurple.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

