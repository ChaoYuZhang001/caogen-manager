// 主题管理

import SwiftUI

// 主题类型
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        case .auto: return "跟随系统"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }
}

// 主题管理器
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .auto {
        didSet {
            saveTheme()
        }
    }

    private let themeKey = "app_theme"

    init() {
        loadTheme()
    }

    // 加载主题设置
    private func loadTheme() {
        if let themeRaw = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeRaw) {
            currentTheme = theme
        }
    }

    // 保存主题设置
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        UserDefaults.standard.synchronize()
    }

    // 切换主题
    func switchTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
}

// 自定义颜色方案
struct AppColorScheme {
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    static let accent = Color("AccentColor")
    static let background = Color("BackgroundColor")
    static let surface = Color("SurfaceColor")
    static let error = Color("ErrorColor")
    static let success = Color("SuccessColor")
    static let warning = Color("WarningColor")
}

// 字体大小管理
class FontSizeManager: ObservableObject {
    @Published var currentScale: Double = 1.0 {
        didSet {
            saveScale()
        }
    }

    private let scaleKey = "font_scale"

    // 可选的字体大小
    let availableScales: [(scale: Double, name: String)] = [
        (0.85, "小"),
        (1.0, "标准"),
        (1.15, "中"),
        (1.3, "大"),
        (1.5, "特大")
    ]

    init() {
        loadScale()
    }

    private func loadScale() {
        currentScale = UserDefaults.standard.double(forKey: scaleKey)
        if currentScale == 0 {
            currentScale = 1.0
        }
    }

    private func saveScale() {
        UserDefaults.standard.set(currentScale, forKey: scaleKey)
        UserDefaults.standard.synchronize()
    }

    func setScale(_ scale: Double) {
        currentScale = scale
    }
}

// 字体扩展
extension Font {
    static func appFont(size: CGFloat, scale: Double = 1.0) -> Font {
        .system(size: size * scale)
    }

    static func appBoldFont(size: CGFloat, scale: Double = 1.0) -> Font {
        .system(size: size * scale, weight: .bold)
    }
}

// 使用示例
/*
// 在 App 入口
@StateObject private var themeManager = ThemeManager()

var body: some Scene {
    WindowGroup {
        ContentView()
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}

// 在视图中
@EnvironmentObject var themeManager: ThemeManager
@StateObject var fontSizeManager = FontSizeManager

Text("Hello")
    .font(.appFont(size: 16, scale: fontSizeManager.currentScale))
*/
