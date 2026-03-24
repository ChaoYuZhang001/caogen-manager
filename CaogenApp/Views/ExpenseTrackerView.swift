import SwiftUI
import Charts
import CoreData

// 支出类别
enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "餐饮"
    case transport = "交通"
    case shopping = "购物"
    case entertainment = "娱乐"
    case housing = "住房"
    case healthcare = "医疗"
    case education = "教育"
    case other = "其他"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .housing: return "house.fill"
        case .healthcare: return "heart.fill"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .pink
        case .entertainment: return .purple
        case .housing: return .green
        case .healthcare: return .red
        case .education: return .yellow
        case .other: return .gray
        }
    }
}

// 记账管理器 - 使用 CoreData
class ExpenseManager: ObservableObject {
    @Published var expenses: [NSManagedObject] = []
    @Published var selectedCategory: ExpenseCategory = .food

    private let dataManager = DataManager.shared

    init() {
        loadExpenses()
    }

    func loadExpenses() {
        expenses = dataManager.fetchExpenseRecords().map { $0 as NSManagedObject }
    }

    func addExpense(amount: Double, category: ExpenseCategory, note: String = "", paymentMethod: String = "") {
        _ = dataManager.createExpenseRecord(
            amount: amount,
            category: category.rawValue,
            description: note.isEmpty ? nil : note,
            paymentMethod: paymentMethod.isEmpty ? nil : paymentMethod
        )
        loadExpenses()
    }
        saveExpenses()
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
    }

    func getTodayTotal() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        return expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.map { $0.amount }.reduce(0, +)
    }

    func getMonthTotal() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return expenses.filter { $0.date >= startOfMonth }.map { $0.amount }.reduce(0, +)
    }

    func getCategoryData() -> [CategorySum] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthExpenses = expenses.filter { $0.date >= startOfMonth }

        var categorySums: [Expense.ExpenseCategory: Double] = [:]
        for expense in monthExpenses {
            categorySums[expense.category, default: 0] += expense.amount
        }

        return categorySums.map { CategorySum(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    func getRecentExpenses(days: Int = 7) -> [Expense] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return expenses.filter { $0.date >= cutoff }
    }
}

struct CategorySum: Identifiable {
    let id = UUID()
    let category: Expense.ExpenseCategory
    let amount: Double
}

// 记账视图
struct ExpenseTrackerView: View {
    @StateObject private var expenseManager = ExpenseManager()
    @State private var showingAddExpense = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计卡片
                    StatsCards(
                        todayTotal: expenseManager.getTodayTotal(),
                        monthTotal: expenseManager.getMonthTotal()
                    )

                    // 分类图表
                    if !expenseManager.getCategoryData().isEmpty {
                        CategoryChartSection(data: expenseManager.getCategoryData())
                    }

                    // 近期记录
                    RecentExpensesSection(
                        expenses: expenseManager.getRecentExpenses(),
                        onDelete: { expenseManager.deleteExpense($0) }
                    )
                }
                .padding()
            }
            .navigationTitle("💰 记账")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseSheet(onAdd: { expense in
                    expenseManager.addExpense(expense)
                })
            }
        }
    }
}

// 统计卡片
struct StatsCards: View {
    let todayTotal: Double
    let monthTotal: Double

    var body: some View {
        HStack(spacing: 12) {
            StatCard(title: "今日支出", amount: todayTotal, color: .orange)
            StatCard(title: "本月支出", amount: monthTotal, color: .red)
        }
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("¥\(Int(amount))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 分类图表
struct CategoryChartSection: View {
    let data: [CategorySum]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月支出分类")
                .font(.headline)

            // 简化饼图
            HStack(spacing: 16) {
                // 饼图
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)

                    ForEach(data) { item in
                        // 简化显示
                        EmptyView()
                    }

                    Text("¥\(Int(data.map { $0.amount }.reduce(0, +)))")
                        .font(.headline)
                }
                .frame(width: 100, height: 100)

                // 分类列表
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(data.prefix(5)) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 8, height: 8)
                            Text(item.category.rawValue)
                                .font(.caption)
                            Spacer()
                            Text("¥\(Int(item.amount))")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// 近期记录
struct RecentExpensesSection: View {
    let expenses: [Expense]
    let onDelete: (Expense) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近期记录")
                .font(.headline)

            if expenses.isEmpty {
                Text("暂无记录")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(expenses) { expense in
                    ExpenseRow(expense: expense)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDelete(expense)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundColor(expense.category.color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category.rawValue)
                    .font(.headline)

                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("-¥\(Int(expense.amount))")
                    .font(.headline)
                    .foregroundColor(.red)

                Text(expense.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 添加支出
struct AddExpenseSheet: View {
    let onAdd: (Expense) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var amount = ""
    @State private var category: Expense.ExpenseCategory = .food
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section("金额") {
                    HStack {
                        Text("¥")
                            .font(.title2)
                        TextField("0", text: $amount)
                            .font(.title2)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("分类") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Expense.ExpenseCategory.allCases, id: \.self) { cat in
                            Button(action: { category = cat }) {
                                VStack(spacing: 4) {
                                    Image(systemName: cat.icon)
                                        .font(.title2)
                                    Text(cat.rawValue)
                                        .font(.caption)
                                }
                                .foregroundColor(category == cat ? .white : cat.color)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(category == cat ? cat.color : cat.color.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                Section("备注") {
                    TextField("添加备注（可选）", text: $note)
                }
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let amountValue = Double(amount) else { return }
                        let expense = Expense(
                            amount: amountValue,
                            category: category,
                            note: note
                        )
                        onAdd(expense)
                        dismiss()
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
}

struct ExpenseTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseTrackerView()
    }
}
