import CoreMotion
import SwiftUI
import UIKit

// 使用Core/Extensions/PreferenceKeys中定义的ScrollOffsetPreferenceKey

// MARK: - 设备方向管理器
class MotionManager: ObservableObject {
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0

    // 添加基准角度属性
    private var basePitch: Double = 0.0
    private var baseRoll: Double = 0.0

    // 添加相对角度计算属性
    var relativePitch: Double {
        return pitch - basePitch
    }

    var relativeRoll: Double {
        return roll - baseRoll
    }

    private let motionManager = CMMotionManager()

    init() {
        self.motionManager.deviceMotionUpdateInterval = 1 / 60
    }

    func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("设备方向数据不可用")
            return
        }

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motionData, error) in
            guard let self = self, error == nil else {
                print("获取设备方向数据错误: \(error?.localizedDescription ?? "未知错误")")
                return
            }

            if let motionData = motionData {
                // 更新当前角度
                self.pitch = motionData.attitude.pitch
                self.roll = motionData.attitude.roll

                // 如果基准角度还未设置，就使用第一次读取的角度作为基准
                if self.basePitch == 0.0 && self.baseRoll == 0.0 {
                    self.setCurrentAsBase()
                }
            }
        }
    }

    // 添加设置当前角度为基准的方法
    func setCurrentAsBase() {
        self.basePitch = self.pitch
        self.baseRoll = self.roll
        print("设置基准角度 - Pitch: \(basePitch), Roll: \(baseRoll)")
    }

    func stopDeviceMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    // 重置基准角度
    func resetBase() {
        basePitch = 0.0
        baseRoll = 0.0
    }
}

// MARK: - 视差效果修饰器
struct ParallaxMotionModifier: ViewModifier {
    @ObservedObject var manager: MotionManager
    var magnitude: Double

    func body(content: Content) -> some View {
        content
            .offset(
                x: CGFloat(manager.relativeRoll * magnitude),
                y: CGFloat(manager.relativePitch * magnitude)
            )
    }
}

// MARK: - 金属/玻璃反光效果修饰器 - 卡片主体反光
struct MetallicReflectionModifier: ViewModifier {
    @ObservedObject var manager: MotionManager
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        // 卡片主体反光效果
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark
                                    ? Color.white.opacity(0.4)  // 深色模式下的不透明度
                                    : Color.white.opacity(0.07),  // 浅色模式下大幅降低不透明度
                                Color.clear,
                            ]),
                            center: UnitPoint(
                                x: 0.5 + CGFloat(manager.relativeRoll * 0.3),
                                y: 0.5 + CGFloat(manager.relativePitch * 0.3)
                            ),
                            startRadius: 5,
                            endRadius: max(geometry.size.width, geometry.size.height)
                                * (colorScheme == .dark ? 0.4 : 0.2)
                        )
                        .blendMode(colorScheme == .dark ? .overlay : .plusLighter)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            )
    }
}

// MARK: - 边缘反光效果修饰器
struct EdgeReflectionModifier: ViewModifier {
    @ObservedObject var manager: MotionManager
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        colorScheme == .dark
                            ? LinearGradient(
                                colors: [
                                    Color.white.opacity(
                                        0.4 + CGFloat(abs(manager.relativeRoll) * 0.2)),
                                    Color.white.opacity(0.2),
                                    Color.clear,
                                    Color.white.opacity(
                                        0.2 + CGFloat(abs(manager.relativePitch) * 0.2)
                                    ),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    // 更优雅的浅色模式边框 - 更柔和的深色渐变
                                    Color(UIColor.systemGray).opacity(
                                        0.5 + CGFloat(abs(manager.relativeRoll) * 0.1)),
                                    Color(UIColor.systemGray2).opacity(0.4),
                                    Color(UIColor.systemGray3).opacity(0.3),
                                    Color(UIColor.systemGray).opacity(
                                        0.4 + CGFloat(abs(manager.relativePitch) * 0.1)
                                    ),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),  // 浅色模式添加更柔和的灰色边框，带有反光效果
                        lineWidth: colorScheme == .dark ? 1.5 * 1.3 : 1.2 * 1.3  // 边框宽度增加30%
                    )
            )
    }
}

// MARK: - 文字内容反光效果修饰器
struct ContentReflectionModifier: ViewModifier {
    @ObservedObject var manager: MotionManager
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        // 不再为文字内容添加反光效果，无论深色还是浅色模式
        content
    }
}

// 为View添加扩展，方便使用这些修饰器
extension View {
    func parallaxMotion(manager: MotionManager, magnitude: Double = 10) -> some View {
        self.modifier(ParallaxMotionModifier(manager: manager, magnitude: magnitude))
    }

    func metallicReflection(manager: MotionManager) -> some View {
        self.modifier(MetallicReflectionModifier(manager: manager))
    }

    func edgeReflection(manager: MotionManager) -> some View {
        self.modifier(EdgeReflectionModifier(manager: manager))
    }

    func contentReflection(manager: MotionManager) -> some View {
        self.modifier(ContentReflectionModifier(manager: manager))
    }
}

// 定义三角形形状
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

struct HomeTabView: View {
    @StateObject private var userModel = UserModel.shared
    @ObservedObject private var testEnvironment = TestEnvironment.shared
    @StateObject private var timetableViewModel = TimetableViewModel()
    @StateObject private var navigationManager = NavigationManager.shared
    @Environment(\.colorScheme) var colorScheme

    // 添加设备方向管理器
    @StateObject private var motionManager = MotionManager()

    // 默认的陀螺仪角度偏移常量
    private let defaultPitchOffset: Double = -0.785  // 约等于-45度（弧度制）

    // 动画状态控制
    @State private var showProfile = false
    @State private var showEvents = false
    @State private var isRefreshing = false
    @State private var scrollOffset = 0.0

    // MARK: - 设置相关
    // 移除本地path变量

    private var userData: (fullName: String, department: String, email: String) {
        if testEnvironment.isTestMode {
            let profile = testEnvironment.mockUserProfile
            return (profile.fullName, profile.department, profile.email)
        } else {
            return (userModel.fullName, userModel.department, userModel.email)
        }
    }

    // 获取当前日期
    private var currentDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        return dateFormatter.string(from: Date())
    }

    var body: some View {
        GeometryReader { geometry in
            // 计算ScrollView的内容区域
            let topSafeArea = geometry.safeAreaInsets.top

            ZStack(alignment: .top) {
                // 背景渐变 - 修改为覆盖整个屏幕
                backgroundGradient
                    .ignoresSafeArea()

                // 主要内容
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        // 使用GeometryReader跟踪滚动位置
                        GeometryReader { scrollGeo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: scrollGeo.frame(in: .named("scrollView")).minY
                            )
                        }
                        .frame(height: 0)  // 不占用空间

                        VStack(spacing: 0) {
                            // 顶部安全区域空间
                            Spacer().frame(height: topSafeArea)

                            // 头部区域 - 欢迎信息和日期显示
                            headerView
                                .padding(.top, 0)
                                .padding(.horizontal, 30)
                                .id("header")  // 添加ID以便定位

                            // 个人资料卡片区域
                            if !userData.email.isEmpty {
                                modernProfileCard
                                    .padding(.top, 20)
                                    .offset(y: showProfile ? 0 : 20)
                                    .opacity(showProfile ? 1 : 0)
                            }

                            // 显示即将到来的课程区域
                            upcomingEventsView
                                .padding(.top, 25)
                                .padding(.bottom, 30)
                                .offset(y: showEvents ? 0 : 20)
                                .opacity(showEvents ? 1 : 0)
                        }
                        .padding(.bottom, 20)  // 底部内边距
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        // 更新滚动偏移量
                        scrollOffset = offset
                    }
                }

                // 设置和搜索按钮 - 固定在右上角，但会随上滑而上滑
                HeaderButtons(
                    scrollOffset: scrollOffset, topSafeArea: topSafeArea,
                    onSearchTap: {
                        showSearchView()
                    },
                    onSettingsTap: {
                        showSettingsView()
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .task {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showProfile = true
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                showEvents = true
            }

            if !testEnvironment.isTestMode {
                // 同步用户数据
                try? await userModel.syncUserData()
            }

            // 加载课程数据
            await loadTimeTableDataIfNeeded()

            // 重置导航状态
            NavigationManager.shared.navigateTo(.home)

            // 启动设备方向更新
            motionManager.startDeviceMotionUpdates()
        }
        .onAppear {
            // 确保每次视图出现时都重置导航状态
            NavigationManager.shared.navigateTo(.home)

            // 清除导航路径，防止堆积
            NavigationManager.shared.navigateToRoot()

            // 打印导航状态，帮助调试
            print("HomeTabView出现，导航路径长度: \(navigationManager.navigationPath.count)")

            // 启动设备方向更新并重置基准角度
            motionManager.resetBase()
            motionManager.startDeviceMotionUpdates()

            // 延迟一小段时间等待设备方向数据稳定后再设置基准
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                motionManager.setCurrentAsBase()
            }
        }
        .onDisappear {
            // 停止设备方向更新
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: - 背景渐变
    private var backgroundGradient: some View {
        // 使用系统默认背景色，移除所有渐变效果
        Color(UIColor.systemBackground)
            .edgesIgnoringSafeArea(.all)
    }

    // MARK: - 头部区域
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Good \(greeting)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()
            }
            .padding(.top, -8)  // 向上调整greeting的位置

            // 日期显示
            Text("Today is \(currentDate)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 现代个人资料卡片
    private var modernProfileCard: some View {
        return VStack(spacing: 15) {
            // 数字名片设计 - 银行卡比例
            VStack(alignment: .leading, spacing: 0) {
                // 上半部分 - 个人信息区域
                VStack(alignment: .leading, spacing: 0) {
                    // 顶部区域 - 学校标识和用户类型
                    HStack {
                        // 左侧 - UCL标识
                        Text("UCL")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .primary.opacity(0.9))
                            .contentReflection(manager: motionManager)  // 添加文字反光效果

                        Spacer()

                        // 右侧 - 用户类型标签
                        Text(getUserType())
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(colorScheme == .dark ? 0.25 : 0.15))
                            )
                            .foregroundColor(
                                colorScheme == .dark ? .white.opacity(0.9) : Color.blue.opacity(0.8)
                            )
                            .contentReflection(manager: motionManager)  // 添加文字反光效果
                    }
                    .padding(.bottom, 15)
                    .contentReflection(manager: motionManager)  // 添加padding区域反光效果

                    // 中部区域 - 姓名和部门
                    VStack(alignment: .leading, spacing: 6) {
                        // 姓名 - 大号字体
                        Text(userData.fullName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .lineLimit(1)
                            .contentReflection(manager: motionManager)  // 添加文字反光效果

                        // 部门 - 次要信息
                        Text(userData.department)
                            .font(.system(size: 15))
                            .foregroundColor(
                                colorScheme == .dark ? .white.opacity(0.7) : .secondary
                            )
                            .lineLimit(2)
                            .contentReflection(manager: motionManager)  // 添加文字反光效果
                    }
                    .padding(.bottom, 15)
                    .contentReflection(manager: motionManager)  // 添加padding区域反光效果

                    Spacer()

                    // 底部区域 - 邮箱和ID信息
                    HStack(alignment: .bottom) {
                        // 左侧 - 邮箱信息
                        if !userData.email.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 13))
                                    .foregroundColor(
                                        colorScheme == .dark ? .white.opacity(0.7) : .secondary)

                                Text(userData.email)
                                    .font(.system(size: 13))
                                    .foregroundColor(
                                        colorScheme == .dark ? .white.opacity(0.7) : .secondary
                                    )
                                    .lineLimit(1)
                            }
                            .contentReflection(manager: motionManager)  // 添加文字反光效果
                        }

                        Spacer()

                        // 右侧 - 学生UPI - 使用真实API数据
                        Text(
                            "UPI: \(testEnvironment.isTestMode ? testEnvironment.mockUserProfile.upi : userModel.upi)"
                        )
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            colorScheme == .dark ? .white.opacity(0.7) : .secondary.opacity(0.8)
                        )
                        .contentReflection(manager: motionManager)  // 添加文字反光效果
                    }
                    .contentReflection(manager: motionManager)  // 添加padding区域反光效果
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(height: 180)  // 调整高度以符合卡片比例
                .background(
                    ZStack {
                        // 背景材质 - 提高亮度，使用暗白色背景（浅色模式下降低亮度）
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                colorScheme == .dark
                                    ? Color(UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1.0))
                                        .opacity(0.95)  // 暗白色背景
                                    : Color.white.opacity(0.92)  // 降低浅色模式下的亮度
                            )

                        // 重新设计背景装饰 - 更加模糊的色块和噪点
                        ZStack {
                            // 右上角大型蓝色圆形 (讲座/Lecture - 蓝色)
                            Circle()
                                .fill(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.07))
                                .frame(width: 180, height: 180)
                                .blur(radius: 35)  // 增加模糊半径
                                .offset(x: 100, y: -80)  // 稍微往外移动
                                .parallaxMotion(manager: motionManager, magnitude: -15)  // 从-22降低到-15
                                .blendMode(.plusLighter)  // 使用更柔和的混合模式

                            // 左下角大型紫色圆形 (研讨会/Seminar - 紫色)
                            Circle()
                                .fill(Color.purple.opacity(colorScheme == .dark ? 0.15 : 0.06))
                                .frame(width: 200, height: 200)
                                .blur(radius: 40)  // 增加模糊半径
                                .offset(x: -100, y: 90)  // 稍微往外移动
                                .parallaxMotion(manager: motionManager, magnitude: -17)  // 从-25降低到-17
                                .blendMode(.plusLighter)  // 使用更柔和的混合模式

                            // 左上角橙色三角形 (教程/Tutorial - 橙色)
                            Triangle()
                                .fill(Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.05))
                                .frame(width: 160, height: 160)
                                .blur(radius: 38)  // 增加模糊半径
                                .rotationEffect(.degrees(180))
                                .offset(x: -85, y: -75)  // 稍微往外移动
                                .parallaxMotion(manager: motionManager, magnitude: -12)  // 从-18降低到-12
                                .blendMode(.plusLighter)  // 使用更柔和的混合模式

                            // 右下角绿色圆形 (实践/Practical - 绿色)
                            Circle()
                                .fill(Color.green.opacity(colorScheme == .dark ? 0.12 : 0.05))
                                .frame(width: 170, height: 170)
                                .blur(radius: 38)  // 增加模糊半径
                                .offset(x: 90, y: 85)  // 稍微往外移动
                                .parallaxMotion(manager: motionManager, magnitude: -14)  // 从-20降低到-14
                                .blendMode(.plusLighter)  // 使用更柔和的混合模式

                            // 中央小型青色三角形 (会议/Meeting - 青色)
                            Triangle()
                                .fill(Color.cyan.opacity(colorScheme == .dark ? 0.1 : 0.04))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)  // 增加模糊半径
                                .rotationEffect(.degrees(45))
                                .offset(x: 15, y: 15)  // 稍微往外移动
                                .parallaxMotion(manager: motionManager, magnitude: -10)  // 从-15降低到-10
                                .blendMode(.plusLighter)  // 使用更柔和的混合模式

                            // 添加噪点纹理
                            Rectangle()
                                .fill(
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.015) : Color.black.opacity(0.008)  // 降低噪点不透明度
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .transformEffect(.init(scaleX: 3, y: 3))  // 放大噪点
                                .opacity(0.35)  // 降低整体不透明度
                                .blendMode(.overlay)
                                .parallaxMotion(manager: motionManager, magnitude: -3)  // 从-5降低到-3
                        }
                    }
                )
                .cornerRadius(16)
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.15),
                    radius: 15, x: 0, y: 8
                )
                // 添加卡片主体反光效果
                .metallicReflection(manager: motionManager)
                // 添加边缘反光效果
                .edgeReflection(manager: motionManager)
                // 调整视差强度为2.5 (从3.5降低)
                .parallaxMotion(manager: motionManager, magnitude: 2.5)
            }
            .padding(.horizontal, 20)
            .onTapGesture {
                // 点击卡片时导航到个人资料页面
                navigationManager.navigateTo(.profile)
            }

            // 课程统计 - 移到卡片外部
            HStack(spacing: 15) {
                // 数字卡片 - 使用更加鲜明的设计
                ZStack {
                    // 背景 - 添加随陀螺仪变化的渐变
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    // 使用陀螺仪角度影响渐变的起始颜色
                                    Color.blue.opacity(
                                        0.8 + min(0.2, abs(motionManager.relativeRoll) * 0.5)),
                                    Color.purple.opacity(
                                        0.7
                                            + min(
                                                0.3,
                                                abs(motionManager.relativePitch) * 0.5)
                                    ),
                                ],
                                // 使用陀螺仪角度调整渐变方向
                                startPoint: UnitPoint(
                                    x: 0.0 + CGFloat(motionManager.relativeRoll * 0.1),
                                    y: 0.0 + CGFloat(motionManager.relativePitch * 0.1)
                                ),
                                endPoint: UnitPoint(
                                    x: 1.0 + CGFloat(motionManager.relativeRoll * 0.1),
                                    y: 1.0 + CGFloat(motionManager.relativePitch * 0.1)
                                )
                            )
                        )
                        .frame(width: 56, height: 56)

                    // 数字
                    Text(remainingClassesThisWeek == 0 ? "0" : "\(remainingClassesThisWeek)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .contentReflection(manager: motionManager)  // 添加文字反光效果
                }
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                // 移除课程计数器的视差效果，但保留卡片阴影效果
                // .parallaxMotion(manager: motionManager, magnitude: 5)

                // 描述文本
                VStack(alignment: .leading, spacing: 4) {
                    Text(remainingClassesThisWeek == 0 ? "No classes" : "Classes")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                        .contentReflection(manager: motionManager)  // 添加文字反光效果

                    Text("remaining this week")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .contentReflection(manager: motionManager)  // 添加文字反光效果
                }

                Spacer()

                // 添加一个箭头引导用户点击查看课程表
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.blue.opacity(0.7))
                    .contentReflection(manager: motionManager)  // 添加图标反光效果
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        colorScheme == .dark
                            ? Color(.systemGray6).opacity(0.7)
                            : Color(.systemBackground)
                    )
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                        radius: 5, x: 0, y: 2
                    )
            )
            .padding(.horizontal, 20)
            .onTapGesture {
                navigationManager.navigateTo(.timetable)
            }
        }
    }

    // 获取用户姓名首字母
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1,
            let firstInitial = components.first?.first,
            let lastInitial = components.last?.first
        {
            return "\(firstInitial)\(lastInitial)"
        } else if let firstInitial = components.first?.first {
            return String(firstInitial)
        }
        return "U"  // 默认值
    }

    // MARK: - 即将到来的课程视图
    var upcomingEventsView: some View {
        return VStack(alignment: .leading, spacing: 16) {
            // 标题区域
            HStack {
                Text("Upcoming Events")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.bottom, 4)
            .padding(.horizontal, 20)

            // 今日课程
            VStack(alignment: .leading, spacing: 15) {
                let todayEvents = getTodayEvents()

                if todayEvents.isEmpty {
                    EmptyEventView(message: "No class today, enjoy your free time!")
                        .padding(.horizontal, 20)
                        .environmentObject(motionManager)
                } else {
                    Text("Today")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    ForEach(todayEvents) { event in
                        SimplifiedEventCard(event: event)
                            .padding(.horizontal, 20)
                            .environmentObject(motionManager)
                            .onTapGesture {
                                prepareAndNavigateToTimetable(event: event)
                            }
                    }
                }
            }

            // 明日课程
            if !getTomorrowEvents().isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Tomorrow")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    ForEach(getTomorrowEvents()) { event in
                        SimplifiedEventCard(event: event)
                            .padding(.horizontal, 20)
                            .environmentObject(motionManager)
                            .onTapGesture {
                                prepareAndNavigateToTimetable(event: event)
                            }
                    }
                }
            }
        }
    }

    // MARK: - 工具函数
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Morning"
        case 12..<17:
            return "Afternoon"
        default:
            return "Evening"
        }
    }

    // 计算本周剩余课程数量
    private var remainingClassesThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()

        // 获取本周结束日期（周日）
        let weekday = calendar.component(.weekday, from: now)
        let daysUntilEndOfWeek = 8 - weekday

        guard
            let endOfWeek = calendar.date(
                byAdding: .day, value: daysUntilEndOfWeek, to: calendar.startOfDay(for: now))
        else {
            return 0
        }

        // 计算从现在到本周末的剩余课程
        return timetableViewModel.allEvents.filter { event in
            // 使用calendar.startOfDay获取事件的纯日期部分
            return event.startTime >= now && calendar.startOfDay(for: event.startTime) <= endOfWeek
        }.count
    }

    // 获取用户类型
    func getUserType() -> String {
        if testEnvironment.isTestMode {
            let groups = testEnvironment.mockUserProfile.uclGroups
            if groups.contains("ucl-ug") {
                return "Undergraduate"
            } else if groups.contains("ucl-pg") {
                return "Postgraduate"
            } else if groups.contains("ucl-staff") {
                return "Staff"
            }
        } else {
            let groups = userModel.uclGroups
            if groups.contains("ucl-ug") {
                return "Undergraduate"
            } else if groups.contains("ucl-pg") {
                return "Postgraduate"
            } else if groups.contains("ucl-staff") {
                return "Staff"
            }
        }
        return "Student"
    }

    // 获取今天的课程
    private func getTodayEvents() -> [TimetableEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        return timetableViewModel.allEvents.filter { event in
            Calendar.current.isDate(
                Calendar.current.startOfDay(for: event.startTime), inSameDayAs: today)
        }.sorted { $0.startTime < $1.startTime }
    }

    // 获取明天的课程
    private func getTomorrowEvents() -> [TimetableEvent] {
        guard
            let tomorrow = Calendar.current.date(
                byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
        else {
            return []
        }

        return timetableViewModel.allEvents.filter { event in
            Calendar.current.isDate(
                Calendar.current.startOfDay(for: event.startTime), inSameDayAs: tomorrow)
        }.sorted { $0.startTime < $1.startTime }
    }

    // 准备并导航到时间表视图
    func prepareAndNavigateToTimetable(event: TimetableEvent) {
        // 添加记录以便调试
        print("准备导航到时间表，事件: \(event.module.name), 开始时间: \(event.startTime)")

        // 使用Task包装异步操作，确保不会阻塞UI
        Task { @MainActor in
            do {
                // 获取事件日期的开始时间（0点0分0秒）
                let eventDate = Calendar.current.startOfDay(for: event.startTime)
                print("事件日期: \(eventDate)")

                // 确保先加载课程表数据
                if timetableViewModel.allEvents.isEmpty {
                    print("正在加载课程表数据...")
                    try await timetableViewModel.fetchTimetable()
                }

                // 使用安全操作更新视图模型中的事件
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    // 更新TimetableViewModel中的事件
                    timetableViewModel.updateEventsForDate(eventDate)

                    // 延迟一点点再导航，确保数据已经准备好
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // 使用新方法导航到时间表并设置日期
                        navigationManager.navigateToTimetableWithDate(eventDate)
                        print("已导航到时间表，日期: \(eventDate)")
                    }
                }
            } catch {
                print("导航到时间表时出错: \(error)")
            }
        }
    }

    // 刷新数据 - 注意：此方法不再被下拉刷新功能使用，但保留以备将来可能的需求
    func refreshData() async {
        isRefreshing = true

        // 刷新用户数据
        if !testEnvironment.isTestMode {
            try? await userModel.syncUserData()
        }

        // 刷新课程数据
        await loadTimeTableDataIfNeeded()

        isRefreshing = false
    }

    // 加载时间表数据（如果需要）
    func loadTimeTableDataIfNeeded() async {
        if timetableViewModel.allEvents.isEmpty {
            try? await timetableViewModel.fetchTimetable()
        }
    }

    // MARK: - 辅助方法

    // 显示搜索视图
    private func showSearchView() {
        // 触发震动反馈
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        // 打印导航状态，帮助调试
        print("搜索前导航路径: \(navigationManager.navigationPath.count) 项")
        print("搜索前活动目标: \(navigationManager.activeDestination)")

        // 确保只执行一次导航操作，直接通过navigationDetail打开搜索视图
        navigationManager.navigateToDetail(.search)

        // 再次打印导航状态，帮助调试
        print("搜索后导航路径: \(navigationManager.navigationPath.count) 项")
        print("搜索后活动目标: \(navigationManager.activeDestination)")
    }

    // 显示设置视图
    private func showSettingsView() {
        // 触发震动反馈
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        // 打印导航状态，帮助调试
        print("设置前导航路径: \(navigationManager.navigationPath.count) 项")
        print("设置前活动目标: \(navigationManager.activeDestination)")

        // 确保只执行一次导航操作，通过navigationDetail打开设置视图
        navigationManager.navigateToDetail(.settings)

        // 再次打印导航状态，帮助调试
        print("设置后导航路径: \(navigationManager.navigationPath.count) 项")
        print("设置后活动目标: \(navigationManager.activeDestination)")
    }
}

// MARK: - 用户类型标签
struct UserTypeTag: View {
    let userType: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(userType)
            .font(.system(size: 14))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        colorScheme == .dark
                            ? Color.green.opacity(0.15)
                            : Color.green.opacity(0.1))
            )
            .foregroundColor(.green)
    }
}

// MARK: - 渐变用户类型标签
struct GradientUserTypeTag: View {
    let userType: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(userType)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .blue.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                .purple.opacity(colorScheme == .dark ? 0.2 : 0.1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

// MARK: - 现代课程卡片
struct ModernEventCard: View {
    let event: TimetableEvent
    @Environment(\.colorScheme) var colorScheme

    private var eventColor: Color {
        // 检查sessionType和sessionTypeStr中是否包含特定关键词
        let sessionTypeLower = event.sessionType.lowercased()
        let sessionTypeStrLower = event.sessionTypeStr.lowercased()

        // 检查sessionType和sessionTypeStr中是否包含特定关键词
        if sessionTypeLower.contains("workshop") || sessionTypeStrLower.contains("workshop")
            || sessionTypeLower == "w" || sessionTypeStrLower == "w"
        {
            return .teal
        } else if sessionTypeLower.contains("lecture") || sessionTypeStrLower.contains("lecture")
            || sessionTypeLower == "l" || sessionTypeStrLower == "l"
        {
            return .blue
        } else if sessionTypeLower.contains("practical")
            || sessionTypeStrLower.contains("practical") || sessionTypeLower.contains("lab")
            || sessionTypeStrLower.contains("lab") || sessionTypeLower == "p"
            || sessionTypeStrLower == "p"
        {
            return .green
        } else if sessionTypeLower.contains("tutorial") || sessionTypeStrLower.contains("tutorial")
            || sessionTypeLower == "t" || sessionTypeStrLower == "t"
        {
            return .orange
        } else if sessionTypeLower.contains("seminar") || sessionTypeStrLower.contains("seminar")
            || sessionTypeLower == "s" || sessionTypeStrLower == "s"
        {
            return .purple
        } else if sessionTypeLower.contains("field") || sessionTypeStrLower.contains("field")
            || sessionTypeLower.contains("trip") || sessionTypeStrLower.contains("trip")
            || sessionTypeLower == "f" || sessionTypeStrLower == "f"
        {
            return .pink
        } else if sessionTypeLower.contains("meeting") || sessionTypeStrLower.contains("meeting")
            || sessionTypeLower == "m" || sessionTypeStrLower == "m"
        {
            return .cyan
        } else if sessionTypeLower.contains("exam") || sessionTypeStrLower.contains("exam")
            || sessionTypeLower == "e" || sessionTypeStrLower == "e"
        {
            return .red
        } else {
            return .brown
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }

    var body: some View {
        HStack(spacing: 16) {
            // 左侧时间和指示条
            VStack(spacing: 4) {
                // 时间条
                Rectangle()
                    .fill(eventColor)
                    .frame(width: 4, height: 50)
                    .cornerRadius(2)

                // 时间显示
                VStack(spacing: 2) {
                    Text(timeFormatter.string(from: event.startTime))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(eventColor)

                    Text(timeFormatter.string(from: event.endTime))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 55)

            // 右侧内容区域
            VStack(alignment: .leading, spacing: 8) {
                // 课程名称
                Text(event.module.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                // 课程类型和地点
                HStack(alignment: .bottom) {
                    // 课程类型标签
                    Text(event.sessionTypeStr)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(eventColor.opacity(0.1))
                        )
                        .foregroundColor(eventColor)

                    Spacer()

                    // 地点图标和文本
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(event.location.name)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 12)

            // 右侧箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.5))
                .font(.system(size: 14, weight: .semibold))
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.regularMaterial)
                .opacity(colorScheme == .dark ? 0.3 : 0.8)  // 增加不透明度
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.25) : .black.opacity(0.05),
                    radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(eventColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 简化课程卡片
struct SimplifiedEventCard: View {
    let event: TimetableEvent
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var motionManager: MotionManager

    private var eventColor: Color {
        let sessionTypeLower = event.sessionType.lowercased()
        let sessionTypeStrLower = event.sessionTypeStr.lowercased()

        // 检查sessionType和sessionTypeStr中是否包含特定关键词
        if sessionTypeLower.contains("workshop") || sessionTypeStrLower.contains("workshop")
            || sessionTypeLower == "w" || sessionTypeStrLower == "w"
        {
            return .teal
        } else if sessionTypeLower.contains("lecture") || sessionTypeStrLower.contains("lecture")
            || sessionTypeLower == "l" || sessionTypeStrLower == "l"
        {
            return .blue
        } else if sessionTypeLower.contains("practical")
            || sessionTypeStrLower.contains("practical") || sessionTypeLower.contains("lab")
            || sessionTypeStrLower.contains("lab") || sessionTypeLower == "p"
            || sessionTypeStrLower == "p"
        {
            return .green
        } else if sessionTypeLower.contains("tutorial") || sessionTypeStrLower.contains("tutorial")
            || sessionTypeLower == "t" || sessionTypeStrLower == "t"
        {
            return .orange
        } else if sessionTypeLower.contains("seminar") || sessionTypeStrLower.contains("seminar")
            || sessionTypeLower == "s" || sessionTypeStrLower == "s"
        {
            return .purple
        } else if sessionTypeLower.contains("field") || sessionTypeStrLower.contains("field")
            || sessionTypeLower.contains("trip") || sessionTypeStrLower.contains("trip")
            || sessionTypeLower == "f" || sessionTypeStrLower == "f"
        {
            return .pink
        } else if sessionTypeLower.contains("meeting") || sessionTypeStrLower.contains("meeting")
            || sessionTypeLower == "m" || sessionTypeStrLower == "m"
        {
            return .cyan
        } else if sessionTypeLower.contains("exam") || sessionTypeStrLower.contains("exam")
            || sessionTypeLower == "e" || sessionTypeStrLower == "e"
        {
            return .red
        } else {
            return .brown
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            // 左侧时间区域
            VStack(alignment: .center, spacing: 2) {
                Text(timeFormatter.string(from: event.startTime))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(eventColor)

                Text(timeFormatter.string(from: event.endTime))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 12)

            // 垂直分隔线
            Rectangle()
                .fill(eventColor)
                .frame(width: 3)
                .cornerRadius(1.5)

            // 右侧内容区域
            VStack(alignment: .leading, spacing: 6) {
                // 课程名称
                Text(event.module.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // 课程类型标签
                    Text(event.sessionTypeStr)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(eventColor.opacity(0.1))
                        )
                        .foregroundColor(eventColor)

                    // 地点图标和文本
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text(event.location.name)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右侧箭头
            Image(systemName: "chevron.forward")
                .foregroundColor(.secondary.opacity(0.7))
                .font(.system(size: 14, weight: .medium))
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    colorScheme == .dark
                        ? Color(.systemGray6).opacity(0.7)
                        : Color(.systemBackground)
                )
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                    radius: 5, x: 0, y: 2
                )
        )
    }
}

// MARK: - 空课程提示视图
struct EmptyEventView: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var motionManager: MotionManager

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 22))
                .foregroundColor(.secondary.opacity(0.7))

            // 文本
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    colorScheme == .dark
                        ? Color(.systemGray6).opacity(0.7)
                        : Color(.systemBackground)
                )
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.2) : .black.opacity(0.05),
                    radius: 5, x: 0, y: 2
                )
        )
    }
}

// MARK: - 头部按钮组件
struct HeaderButtons: View {
    let scrollOffset: CGFloat
    let topSafeArea: CGFloat
    let onSearchTap: () -> Void
    let onSettingsTap: () -> Void

    @StateObject private var navigationManager = NavigationManager.shared

    var body: some View {
        VStack {
            HStack {
                Spacer()

                // 搜索按钮
                Button(action: onSearchTap) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 15)
                .padding(.top, topSafeArea + 10)

                // 设置按钮
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 30)
                .padding(.top, topSafeArea + 10)
            }

            Spacer()
        }
        // 关键点：只有当scrollOffset小于0（向上滚动）时才应用偏移
        .offset(y: min(0, scrollOffset))
    }
}

#Preview {
    HomeTabView()
        .environmentObject(TestEnvironment.shared)
}
