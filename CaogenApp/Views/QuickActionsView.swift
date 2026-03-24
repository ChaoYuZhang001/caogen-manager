import SwiftUI

struct QuickActionsView: View {
    @EnvironmentObject var quickActionManager: QuickActionManager
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingEditor = false

    var body: some View {
        NavigationView {
            List {
                // 系统预设快捷指令
                Section("常用指令") {
                    ForEach(quickActionManager.quickActions.filter { $0.isSystem }) { action in
                        QuickActionRow(action: action) {
                            executeAction(action)
                        }
                    }
                }

                // 自定义快捷指令
                if quickActionManager.quickActions.contains(where: { !$0.isSystem }) {
                    Section("自定义指令") {
                        ForEach(quickActionManager.quickActions.filter { !$0.isSystem }) { action in
                            QuickActionRow(action: action) {
                                executeAction(action)
                            }
                        }
                        .onDelete { indexSet in
                            deleteCustomAction(at: indexSet)
                        }
                    }
                }

                // 使用统计
                Section("使用统计") {
                    ForEach(quickActionManager.quickActions.sorted(by: { $0.executionCount > $1.executionCount }).prefix(5)) { action in
                        HStack {
                            Image(systemName: action.icon)
                                .foregroundColor(.green)
                            Text(action.name)
                            Spacer()
                            Text("\(action.executionCount) 次")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("⚡ 快捷指令")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingEditor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                QuickActionEditorView()
                    .environmentObject(quickActionManager)
            }
        }
    }

    private func executeAction(_ action: QuickAction) {
        Task {
            await quickActionManager.executeQuickAction(action, chatManager: chatManager)
        }
    }

    private func deleteCustomAction(at indexSet: IndexSet) {
        let customActions = quickActionManager.quickActions.filter { !$0.isSystem }
        for index in indexSet {
            if index < customActions.count {
                quickActionManager.deleteQuickAction(customActions[index])
            }
        }
    }
}

// 快捷指令行
struct QuickActionRow: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: action.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }

                // 名称和描述
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(action.prompt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 执行按钮
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .padding(.vertical, 4)
        }
    }
}

// 预览
struct QuickActionsView_Previews: PreviewProvider {
    static var previews: some View {
        QuickActionsView()
            .environmentObject(QuickActionManager())
            .environmentObject(ChatManager())
            .environmentObject(ThemeManager())
    }
}
