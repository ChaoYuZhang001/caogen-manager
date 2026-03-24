/**
 * 安全优化 - 权限控制
 * 细粒度权限管理、角色权限系统、权限审计日志、权限申请流程
 */

import Foundation
import Combine

/// 权限管理器
class PermissionManager: ObservableObject {
    @Published var currentUserRole: Role = .user
    @Published var permissions: [Permission] = []
    @Published var auditLogs: [AuditLog] = []

    static let shared = PermissionManager()

    private init() {
        loadPermissions()
    }

    /// 加载权限
    private func loadPermissions() {
        // 预设权限
        permissions = [
            Permission(id: "chat.read", name: "查看聊天", resource: "chat", action: .read),
            Permission(id: "chat.send", name: "发送消息", resource: "chat", action: .write),
            Permission(id: "data.read", name: "查看数据", resource: "data", action: .read),
            Permission(id: "data.write", name: "修改数据", resource: "data", action: .write),
            Permission(id: "data.delete", name: "删除数据", resource: "data", action: .delete),
            Permission(id: "settings.read", name: "查看设置", resource: "settings", action: .read),
            Permission(id: "settings.write", name: "修改设置", resource: "settings", action: .write),
            Permission(id: "admin.all", name: "全部权限", resource: "admin", action: .all)
        ]

        // 加载审计日志
        loadAuditLogs()
    }

    /// 检查权限
    func hasPermission(_ permissionId: String) -> Bool {
        let rolePermissions = getPermissions(for: currentUserRole)
        return rolePermissions.contains(permissionId)
    }

    /// 检查多个权限
    func hasAllPermissions(_ permissionIds: [String]) -> Bool {
        return permissionIds.allSatisfy { hasPermission($0) }
    }

    /// 获取角色的权限
    func getPermissions(for role: Role) -> [String] {
        switch role {
        case .guest:
            return ["chat.read", "data.read", "settings.read"]
        case .user:
            return ["chat.read", "chat.send", "data.read", "data.write", "settings.read", "settings.write"]
        case .admin:
            return permissions.map { $0.id }
        case .superAdmin:
            return permissions.map { $0.id }
        }
    }

    /// 授予权限
    func grantPermission(_ permissionId: String, to role: Role) {
        print("🔑 授予权限: \(permissionId) -> \(role.rawValue)")

        // 记录审计日志
        addAuditLog(
            action: .grant,
            permissionId: permissionId,
            targetRole: role.rawValue,
            details: "授予权限"
        )
    }

    /// 撤销权限
    func revokePermission(_ permissionId: String, from role: Role) {
        print("🔑 撤销权限: \(permissionId) -> \(role.rawValue)")

        // 记录审计日志
        addAuditLog(
            action: .revoke,
            permissionId: permissionId,
            targetRole: role.rawValue,
            details: "撤销权限"
        )
    }

    /// 请求权限
    func requestPermission(_ permissionId: String, reason: String) async -> PermissionRequestResult {
        print("📝 申请权限: \(permissionId)")

        // 检查是否已有权限
        if hasPermission(permissionId) {
            return PermissionRequestResult(success: true, message: "已有该权限")
        }

        // 记录审计日志
        addAuditLog(
            action: .request,
            permissionId: permissionId,
            details: "申请原因: \(reason)"
        )

        // 模拟审批
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // 自动审批（模拟）
        let approved = Bool.random()

        if approved {
            // 授予权限
            grantPermission(permissionId, to: currentUserRole)

            return PermissionRequestResult(success: true, message: "权限已授予")
        } else {
            return PermissionRequestResult(success: false, message: "权限申请被拒绝")
        }
    }

    /// 添加审计日志
    private func addAuditLog(action: AuditAction, permissionId: String, targetRole: String? = nil, details: String = "") {
        let log = AuditLog(
            id: UUID().uuidString,
            timestamp: Date(),
            action: action,
            permissionId: permissionId,
            targetRole: targetRole,
            details: details,
            userId: "current_user"
        )

        auditLogs.append(log)

        // 保留最近 100 条日志
        if auditLogs.count > 100 {
            auditLogs = Array(auditLogs.suffix(100))
        }

        print("📝 审计日志已记录")
    }

    /// 加载审计日志
    private func loadAuditLogs() {
        // 实际应用中从数据库加载
    }

    /// 获取审计日志
    func getAuditLogs(limit: Int = 20) -> [AuditLog] {
        return Array(auditLogs.suffix(limit)).reversed()
    }

    /// 清空审计日志
    func clearAuditLogs() {
        auditLogs.removeAll()
    }

    /// 切换角色（仅用于测试）
    func switchRole(to role: Role) {
        currentUserRole = role
        print("🔄 角色已切换: \(role.rawValue)")
    }
}

/// 权限
struct Permission: Identifiable, Codable {
    let id: String
    let name: String
    let resource: String
    let action: PermissionAction
}

/// 权限动作
enum PermissionAction: String, Codable {
    case read
    case write
    case delete
    case all
}

/// 角色
enum Role: String, Codable {
    case guest
    case user
    case admin
    case superAdmin
}

/// 审计日志
struct AuditLog: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let action: AuditAction
    let permissionId: String
    let targetRole: String?
    let details: String
    let userId: String
}

/// 审计动作
enum AuditAction: String, Codable {
    case grant
    case revoke
    case request
    case approve
    case deny
}

/// 权限申请结果
struct PermissionRequestResult {
    let success: Bool
    let message: String
}

/// 权限视图
struct PermissionView: View {
    @StateObject private var permissionManager = PermissionManager.shared

    var body: some View {
        List {
            Section(header: Text("当前角色")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)

                    Text(permissionManager.currentUserRole.rawValue.uppercased())
                        .font(.headline)

                    Spacer()

                    Picker("角色", selection: Binding(
                        get: { permissionManager.currentUserRole },
                        set: { permissionManager.switchRole(to: $0) }
                    )) {
                        Text("访客").tag(Role.guest)
                        Text("用户").tag(Role.user)
                        Text("管理员").tag(Role.admin)
                        Text("超级管理员").tag(Role.superAdmin)
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section(header: Text("权限列表")) {
                ForEach(permissionManager.permissions) { permission in
                    PermissionRow(
                        permission: permission,
                        hasPermission: permissionManager.hasPermission(permission.id)
                    )
                }
            }

            Section(header: Text("权限申请")) {
                Button("申请数据删除权限") {
                    Task {
                        let result = await permissionManager.requestPermission("data.delete", reason: "需要删除过期数据")
                        print("申请结果: \(result.message)")
                    }
                }
                .buttonStyle(.bordered)

                Button("申请管理员权限") {
                    Task {
                        let result = await permissionManager.requestPermission("admin.all", reason: "需要管理后台")
                        print("申请结果: \(result.message)")
                    }
                }
                .buttonStyle(.bordered)
            }

            Section(header: Text("审计日志")) {
                if permissionManager.auditLogs.isEmpty {
                    Text("暂无日志")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(permissionManager.getAuditLogs()) { log in
                        AuditLogRow(log: log)
                    }
                }
            }
        }
        .navigationTitle("🔑 权限管理")
    }
}

/// 权限行
struct PermissionRow: View {
    let permission: Permission
    let hasPermission: Bool

    var body: some View {
        HStack {
            Image(systemName: hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(hasPermission ? .green : .red)

            VStack(alignment: .leading, spacing: 4) {
                Text(permission.name)
                    .font(.headline)

                Text("\(permission.resource).\(permission.action.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

/// 审计日志行
struct AuditLogRow: View {
    let log: AuditLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(actionIcon(log.action))
                    .font(.caption)

                Text(log.permissionId)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatTime(log.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let targetRole = log.targetRole {
                Text("目标角色: \(targetRole)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !log.details.isEmpty {
                Text(log.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func actionIcon(_ action: AuditAction) -> String {
        switch action {
        case .grant: return "✅"
        case .revoke: return "❌"
        case .request: return "📝"
        case .approve: return "👍"
        case .deny: return "🚫"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

/// 角色视图
struct RoleView: View {
    @StateObject private var permissionManager = PermissionManager.shared

    var body: some View {
        List {
            ForEach([Role.guest, Role.user, Role.admin, Role.superAdmin], id: \.self) { role in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(role.rawValue.uppercased())
                            .font(.headline)

                        Spacer()

                        if role == permissionManager.currentUserRole {
                            Text("当前角色")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    Text("权限数量: \(permissionManager.getPermissions(for: role).count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("权限列表: \(permissionManager.getPermissions(for: role).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("👥 角色管理")
    }
}

/// 使用示例
struct PermissionExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🔑 权限控制示例")
                .font(.title)

            // 权限检查
            VStack(alignment: .leading, spacing: 8) {
                Text("1. 权限检查")
                    .font(.headline)

                let canDelete = PermissionManager.shared.hasPermission("data.delete")

                if canDelete {
                    Text("✅ 您有数据删除权限")
                        .foregroundColor(.green)
                } else {
                    Text("❌ 您没有数据删除权限")
                        .foregroundColor(.red)
                }
            }

            Divider()

            // 角色信息
            VStack(alignment: .leading, spacing: 8) {
                Text("2. 当前角色")
                    .font(.headline)

                Text("角色: \(PermissionManager.shared.currentUserRole.rawValue)")
                    .font(.subheadline)

                let permissions = PermissionManager.shared.getPermissions(for: PermissionManager.shared.currentUserRole)
                Text("权限数: \(permissions.count)")
                    .font(.caption)
            }

            Divider()

            // 审计日志
            VStack(alignment: .leading, spacing: 8) {
                Text("3. 审计日志")
                    .font(.headline)

                let logs = PermissionManager.shared.getAuditLogs(limit: 3)

                if logs.isEmpty {
                    Text("暂无日志")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(logs) { log in
                        Text("\(formatTime(log.timestamp)) - \(log.permissionId)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
