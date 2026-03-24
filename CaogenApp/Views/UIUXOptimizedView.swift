/**
 * UI/UX 改进 - 动态主题 + 流畅动画
 * 目标：提升用户体验，增加视觉吸引力
 */

import SwiftUI

/// 主题管理器
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .auto
    @Published var customColor: Color = .green

    // 预设主题
    enum AppTheme: String, CaseIterable {
        case auto = "auto"
        case light = "light"
        case dark = "dark"
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case night = "night"
        case custom = "custom"

        var displayName: String {
            switch self {
            case .auto: return "自动"
            case .light: return "浅色"
            case .dark: return "深色"
            case .morning: return "清晨"
            case .afternoon: return "午后"
            case .evening: return "傍晚"
            case .night: return "夜间"
            case .custom: return "自定义"
            }
        }

        var icon: String {
            switch self {
            case .auto: return "sparkles"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            case .custom: return "paintbrush.fill"
            }
        }
    }

    /// 根据时间自动选择主题
    func autoSelectTheme() {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<9:
            currentTheme = .morning
        case 9..<12:
            currentTheme = .light
        case 12..<17:
            currentTheme = .afternoon
        case 17..<20:
            currentTheme = .evening
        case 20..<24, 0..<5:
            currentTheme = .night
        default:
            currentTheme = .light
        }

        print("🎨 自动切换主题: \(currentTheme.displayName)")
    }

    /// 获取主题配色
    func getThemeColors() -> ThemeColors {
        switch currentTheme {
        case .auto:
            return autoSelectThemeAndGetColors()
        case .light:
            return ThemeColors(
                primary: .green,
                secondary: .green.opacity(0.8),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: .blue
            )
        case .dark:
            return ThemeColors(
                primary: Color.green.opacity(0.8),
                secondary: Color.green.opacity(0.6),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.blue.opacity(0.8)
            )
        case .morning:
            return ThemeColors(
                primary: Color.orange,
                secondary: Color.yellow,
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.pink
            )
        case .afternoon:
            return ThemeColors(
                primary: Color.green,
                secondary: Color.teal,
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.blue
            )
        case .evening:
            return ThemeColors(
                primary: Color.orange.opacity(0.8),
                secondary: Color.purple.opacity(0.8),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.pink
            )
        case .night:
            return ThemeColors(
                primary: Color.indigo.opacity(0.8),
                secondary: Color.purple.opacity(0.6),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.blue.opacity(0.8)
            )
        case .custom:
            return ThemeColors(
                primary: customColor,
                secondary: customColor.opacity(0.8),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: customColor
            )
        }
    }

    private func autoSelectThemeAndGetColors() -> ThemeColors {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour >= 5 && hour < 9 {
            // 清晨
            return ThemeColors(
                primary: Color.orange,
                secondary: Color.yellow,
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.pink
            )
        } else if hour >= 9 && hour < 12 {
            // 上午
            return ThemeColors(
                primary: Color.green,
                secondary: Color.green.opacity(0.8),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.blue
            )
        } else if hour >= 12 && hour < 17 {
            // 下午
            return ThemeColors(
                primary: Color.green,
                secondary: Color.teal,
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.blue
            )
        } else if hour >= 17 && hour < 20 {
            // 傍晚
            return ThemeColors(
                primary: Color.orange.opacity(0.8),
                secondary: Color.purple.opacity(0.8),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.pink
            )
        } else {
            // 夜间
            return ThemeColors(
                primary: Color.indigo.opacity(0.8),
                secondary: Color.purple.opacity(0.6),
                background: Color(.systemBackground),
                text: Color(.label),
                accent: Color.blue.opacity(0.8)
            )
        }
    }
}

/// 主题配色
struct ThemeColors {
    var primary: Color
    var secondary: Color
    var background: Color
    var text: Color
    var accent: Color
}

/// 流畅动画修饰符
struct SmoothAnimationModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.0 : 0.95)
            .opacity(isAnimating ? 1.0 : 0.9)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAnimating)
            .onAppear {
                withAnimation {
                    isAnimating = true
                }
            }
    }
}

extension View {
    /// 添加流畅动画
    func smoothAnimation() -> some View {
        self.modifier(SmoothAnimationModifier())
    }
}

/// 卡片样式
struct CardStyle: ViewModifier {
    var themeColors: ThemeColors

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeColors.background)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeColors.secondary, lineWidth: 1)
            )
    }
}

extension View {
    /// 卡片样式
    func cardStyle(themeColors: ThemeColors) -> some View {
        self.modifier(CardStyle(themeColors: themeColors))
    }
}

/// 按钮样式
struct ButtonStyle: ViewModifier {
    var themeColors: ThemeColors

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(themeColors.primary)
            )
            .foregroundColor(.white)
            .font(.headline)
    }
}

extension View {
    /// 按钮样式
    func buttonStyle(themeColors: ThemeColors) -> some View {
        self.modifier(ButtonStyle(themeColors: themeColors))
    }
}

/// 页面过渡动画
struct PageTransition: ViewModifier {
    @State private var offset: CGFloat = 300
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .opacity(opacity)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: offset)
            .onAppear {
                withAnimation {
                    offset = 0
                    opacity = 1.0
                }
            }
    }
}

extension View {
    /// 页面过渡动画
    func pageTransition() -> some View {
        self.modifier(PageTransition())
    }
}

/// 加载动画
struct LoadingAnimation: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                .frame(width: 40, height: 40)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .blue]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

/// 手势操作视图
struct GestureView: View {
    @State private var offset: CGSize = .zero
    @State private var isPressed = false

    var body: some View {
        VStack {
            // 滑动删除示例
            Text("滑动删除")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .offset(x: offset.width)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { value in
                            if value.translation.width < -100 {
                                // 删除
                                withAnimation {
                                    offset.width = -300
                                }
                            } else {
                                // 复位
                                withAnimation {
                                    offset = .zero
                                }
                            }
                        }
                )

            // 长按菜单示例
            Text("长按显示菜单")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .contextMenu {
                    Button("选项 1") {}
                    Button("选项 2") {}
                    Button("选项 3") {}
                }

            // 双击操作示例
            Text("双击点赞")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .scaleEffect(isPressed ? 1.5 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
                .onTapGesture(count: 2) {
                    withAnimation {
                        isPressed.toggle()
                    }
                }
        }
        .padding()
    }
}

/// 主题设置视图
struct ThemeSettingsView: View {
    @StateObject private var themeManager = ThemeManager()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("主题模式")) {
                    ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            themeManager.currentTheme = theme
                        }) {
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.displayName)
                                Spacer()
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("自定义颜色")) {
                    ColorPicker("主色调", selection: $themeManager.customColor)
                }
            }
            .navigationTitle("主题设置")
        }
    }
}

/// 主题预览视图
struct ThemePreviewView: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var selectedTheme: ThemeManager.AppTheme = .auto

    var themeColors: ThemeColors {
        themeManager.getThemeColors()
    }

    var body: some View {
        VStack(spacing: 20) {
            // 主题选择器
            Picker("主题", selection: $selectedTheme) {
                ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                    Label(theme.displayName, systemImage: theme.icon)
                        .tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTheme) { newValue in
                themeManager.currentTheme = newValue
            }

            // 预览卡片
            VStack(spacing: 16) {
                Text("主题预览")
                    .font(.title)
                    .foregroundColor(themeColors.text)

                Button("主要按钮") {}
                    .buttonStyle(themeColors: themeColors)

                Text("这是一段示例文本")
                    .foregroundColor(themeColors.text)
                    .padding()
                    .cardStyle(themeColors: themeColors)

                LoadingAnimation()
            }
            .padding()
        }
        .background(themeColors.background)
    }
}

/// 使用示例
struct UIUXDemoView: View {
    @StateObject private var themeManager = ThemeManager()

    var themeColors: ThemeColors {
        themeManager.getThemeColors()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 自动主题切换按钮
                Button("自动切换主题") {
                    themeManager.autoSelectTheme()
                }
                .buttonStyle(themeColors: themeColors)

                // 主题信息
                Text("当前主题: \(themeManager.currentTheme.displayName)")
                    .foregroundColor(themeColors.text)

                // 示例卡片
                VStack(alignment: .leading, spacing: 10) {
                    Text("这是一个示例卡片")
                        .font(.headline)
                    Text("使用了流畅动画和动态主题")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .cardStyle(themeColors: themeColors)
                .smoothAnimation()

                // 手势操作演示
                GestureView()
            }
            .padding()
            .navigationTitle("UI/UX 演示")
            .background(themeColors.background)
        }
        .onAppear {
            // 启动时自动选择主题
            themeManager.autoSelectTheme()
        }
    }
}
