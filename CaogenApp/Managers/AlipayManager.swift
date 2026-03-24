/**
 * 支付宝集成 - Alipay Integration
 * 账单自动同步、消费分析、支付宝登录
 */

import Foundation
import Combine

/// 支付宝管理器
class AlipayManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var bills: [AlipayBill] = []
    @Published var expenseAnalysis: ExpenseAnalysis?
    @Published var balance: Double = 0.0

    private let apiURL = "https://openapi.alipay.com"
    private let appId = "" // 需要从支付宝开放平台获取
    private let privateKey = "" // 需要配置私钥

    /// 登录
    func login() async -> Bool {
        print("🔐 支付宝登录中...")

        // 模拟登录
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        isLoggedIn = true
        balance = 5000.00

        print("✅ 支付宝登录成功")

        return true
    }

    /// 同步账单
    func syncBills(startDate: Date, endDate: Date) async -> SyncResult {
        guard isLoggedIn else {
            return SyncResult(success: false, message: "未登录")
        }

        print("💰 同步账单...")

        // 模拟同步
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // 生成模拟账单
        let bills = generateMockBills(startDate: startDate, endDate: endDate)

        self.bills = bills

        return SyncResult(
            success: true,
            message: "同步成功，共 \(bills.count) 条账单",
            billCount: bills.count
        )
    }

    /// 生成模拟账单
    private func generateMockBills(startDate: Date, endDate: Date) -> [AlipayBill] {
        let categories = ["餐饮", "交通", "购物", "娱乐", "医疗", "教育"]
        let merchants = ["美团", "滴滴", "淘宝", "京东", "医院", "学校"]

        return (0..<20).map { i in
            let category = categories.randomElement()!
            let merchant = merchants.randomElement()!
            let amount = Double.random(in: 10...500)
            let timestamp = startDate.addingTimeInterval(Double(i) * 86400)

            return AlipayBill(
                id: UUID().uuidString,
                title: "\(category)消费",
                merchant: merchant,
                category: category,
                amount: amount,
                timestamp: timestamp,
                type: .expense
            )
        }
    }

    /// 消费分析
    func analyzeExpenses() -> ExpenseAnalysis {
        guard !bills.isEmpty else {
            return ExpenseAnalysis(
                totalExpense: 0,
                categoryBreakdown: [:],
                topCategory: nil,
                averageDaily: 0,
                trend: "稳定"
            )
        }

        // 计算总消费
        let totalExpense = bills.reduce(0.0) { $0 + $1.amount }

        // 按分类统计
        var categoryBreakdown: [String: Double] = [:]

        for bill in bills {
            categoryBreakdown[bill.category, default: 0] += bill.amount
        }

        // 找出最高消费分类
        let topCategory = categoryBreakdown.max(by: { $0.value < $1.value })

        // 计算日均消费
        let days = Set(bills.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        let averageDaily = days > 0 ? totalExpense / Double(days) : 0

        // 趋势分析
        let trend = analyzeTrend()

        return ExpenseAnalysis(
            totalExpense: totalExpense,
            categoryBreakdown: categoryBreakdown,
            topCategory: topCategory?.key,
            averageDaily: averageDaily,
            trend: trend
        )
    }

    /// 分析趋势
    private func analyzeTrend() -> String {
        let sortedBills = bills.sorted { $0.timestamp < $1.timestamp }

        guard sortedBills.count >= 2 else { return "数据不足" }

        let firstHalf = sortedBills.prefix(sortedBills.count / 2)
        let secondHalf = sortedBills.suffix(sortedBills.count / 2)

        let firstTotal = firstHalf.reduce(0.0) { $0 + $1.amount }
        let secondTotal = secondHalf.reduce(0.0) { $0 + $1.amount }

        if secondTotal > firstTotal * 1.2 {
            return "上升"
        } else if secondTotal < firstTotal * 0.8 {
            return "下降"
        } else {
            return "稳定"
        }
    }

    /// 按日期筛选账单
    func filterBillsByDate(startDate: Date, endDate: Date) -> [AlipayBill] {
        return bills.filter { bill in
            bill.timestamp >= startDate && bill.timestamp <= endDate
        }
    }

    /// 按分类筛选账单
    func filterBillsByCategory(_ category: String) -> [AlipayBill] {
        return bills.filter { $0.category == category }
    }

    /// 导出账单
    func exportBills() -> String {
        var csv = "日期,商家,分类,金额,类型\n"

        for bill in bills.sorted(by: { $0.timestamp < $1.timestamp }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = formatter.string(from: bill.timestamp)

            csv += "\(dateStr),\(bill.merchant),\(bill.category),\(bill.amount),\(bill.type.rawValue)\n"
        }

        return csv
    }

    /// 获取账单统计
    func getBillStatistics() -> BillStatistics {
        let expenseBills = bills.filter { $0.type == .expense }
        let incomeBills = bills.filter { $0.type == .income }

        let totalExpense = expenseBills.reduce(0.0) { $0 + $1.amount }
        let totalIncome = incomeBills.reduce(0.0) { $0 + $1.amount }
        let averageAmount = bills.isEmpty ? 0 : bills.reduce(0.0) { $0 + $1.amount } / Double(bills.count)

        return BillStatistics(
            totalBills: bills.count,
            totalExpense: totalExpense,
            totalIncome: totalIncome,
            averageAmount: averageAmount
        )
    }

    /// 支付
    func pay(_ amount: Double, to merchant: String, category: String) async -> Bool {
        guard isLoggedIn else {
            print("❌ 未登录")
            return false
        }

        guard balance >= amount else {
            print("❌ 余额不足")
            return false
        }

        print("💰 支付 ¥\(amount) 到 \(merchant)")

        // 模拟支付
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        balance -= amount

        // 添加账单记录
        let bill = AlipayBill(
            id: UUID().uuidString,
            title: "支付",
            merchant: merchant,
            category: category,
            amount: amount,
            timestamp: Date(),
            type: .expense
        )

        bills.append(bill)

        print("✅ 支付成功")

        return true
    }
}

/// 支付宝账单
struct AlipayBill: Identifiable, Codable {
    let id: String
    let title: String
    let merchant: String
    let category: String
    let amount: Double
    let timestamp: Date
    let type: BillType

    enum BillType: String, Codable {
        case expense
        case income
        case transfer
    }
}

/// 消费分析
struct ExpenseAnalysis {
    let totalExpense: Double
    let categoryBreakdown: [String: Double]
    let topCategory: String?
    let averageDaily: Double
    let trend: String
}

/// 账单统计
struct BillStatistics {
    let totalBills: Int
    let totalExpense: Double
    let totalIncome: Double
    let averageAmount: Double
}

/// 同步结果
struct SyncResult {
    let success: Bool
    let message: String
    let billCount: Int?
}

/// 支付宝视图
struct AlipayView: View {
    @StateObject private var manager = AlipayManager()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("账户状态")) {
                    HStack {
                        Image(systemName: manager.isLoggedIn ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(manager.isLoggedIn ? .green : .red)

                        Text(manager.isLoggedIn ? "已登录" : "未登录")
                            .font(.headline)

                        Spacer()

                        if !manager.isLoggedIn {
                            Button("登录") {
                                Task {
                                    await manager.login()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if manager.isLoggedIn {
                        HStack {
                            Text("余额:")
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("¥\(String(format: "%.2f", manager.balance))")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                }

                if manager.isLoggedIn {
                    Section(header: Text("账单同步")) {
                        Button("同步本月账单") {
                            Task {
                                let now = Date()
                                let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!

                                await manager.syncBills(startDate: startOfMonth, endDate: now)

                                // 自动分析
                                manager.expenseAnalysis = manager.analyzeExpenses()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section(header: Text("消费分析")) {
                        if let analysis = manager.expenseAnalysis {
                            HStack {
                                Text("总消费:")
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("¥\(String(format: "%.2f", analysis.totalExpense))")
                                    .font(.headline)
                            }

                            HStack {
                                Text("日均消费:")
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("¥\(String(format: "%.2f", analysis.averageDaily))")
                            }

                            if let topCategory = analysis.topCategory {
                                HStack {
                                    Text("主要消费:")
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text(topCategory)
                                        .font(.headline)
                                }
                            }

                            HStack {
                                Text("趋势:")
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(analysis.trend)
                                    .foregroundColor(analysis.trend == "上升" ? .red : (analysis.trend == "下降" ? .green : .gray))
                            }

                            NavigationLink(destination: CategoryBreakdownView(analysis: analysis)) {
                                Label("分类明细", systemImage: "chart.bar.fill")
                            }
                        } else {
                            Text("暂无数据")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section(header: Text("账单列表")) {
                        if manager.bills.isEmpty {
                            Text("暂无账单")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(manager.bills.sorted(by: { $0.timestamp > $1.timestamp })) { bill in
                                BillRow(bill: bill)
                            }
                        }
                    }

                    Section(header: Text("工具")) {
                        NavigationLink(destination: PaymentView(manager: manager)) {
                            Label("支付", systemImage: "creditcard.fill")
                        }

                        NavigationLink(destination: ExportView(manager: manager)) {
                            Label("导出账单", systemImage: "square.and.arrow.up.fill")
                        }
                    }
                }
            }
            .navigationTitle("💰 支付宝")
        }
    }
}

/// 账单行
struct BillRow: View {
    let bill: AlipayBill

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.title)
                    .font(.headline)

                Text(bill.merchant)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(bill.type == .expense ? "-¥\(String(format: "%.2f", bill.amount))" : "+¥\(String(format: "%.2f", bill.amount))")
                    .font(.headline)
                    .foregroundColor(bill.type == .expense ? .red : .green)

                Text(bill.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// 分类明细视图
struct CategoryBreakdownView: View {
    let analysis: ExpenseAnalysis

    var body: some View {
        List {
            ForEach(analysis.categoryBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                HStack {
                    Text(category)
                        .font(.headline)

                    Spacer()

                    Text("¥\(String(format: "%.2f", amount))")
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("分类明细")
    }
}

/// 支付视图
struct PaymentView: View {
    @ObservedObject var manager: AlipayManager
    @State private var amount: String = ""
    @State private var merchant: String = ""
    @State private var category: String = "餐饮"

    let categories = ["餐饮", "交通", "购物", "娱乐", "医疗", "教育"]

    var body: some View {
        Form {
            Section(header: Text("支付信息")) {
                TextField("金额", text: $amount)
                    .keyboardType(.decimalPad)

                TextField("商家", text: $merchant)

                Picker("分类", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
            }

            Section {
                Button("支付") {
                    if let amountValue = Double(amount), !merchant.isEmpty {
                        Task {
                            await manager.pay(amountValue, to: merchant, category: category)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(amount.isEmpty || merchant.isEmpty)
            }
        }
        .navigationTitle("支付")
    }
}

/// 导出视图
struct ExportView: View {
    @ObservedObject var manager: AlipayManager
    @State private var csvContent = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("导出账单")
                .font(.title)

            if csvContent.isEmpty {
                Button("生成 CSV") {
                    csvContent = manager.exportBills()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text(csvContent)
                    .font(.caption)
                    .padding()
                    .frame(maxHeight: 300)

                ShareLink(item: csvContent) {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
            }
        }
        .padding()
        .navigationTitle("导出")
    }
}
