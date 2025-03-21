import SwiftUI

/// 导航工具类，允许从任何地方推送新视图
struct NavigationUtil {
    /// 将视图推送到导航栈上
    static func push<V: View>(_ view: V) {
        let manager = NavigationManager.shared

        // 如果是SpaceView，使用特定的导航目标
        if view is SpaceView {
            manager.navigateTo(.studySpaces)
        } else {
            // 为其他视图使用一般方法
            let hostingController = UIHostingController(rootView: view)
            let windowScene =
                UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene

            guard let window = windowScene?.windows.first(where: { $0.isKeyWindow }),
                let rootViewController = window.rootViewController,
                let navigationController = findNavigationController(from: rootViewController)
            else { return }

            navigationController.pushViewController(hostingController, animated: true)
        }
    }

    /// 从根视图控制器中查找导航控制器
    private static func findNavigationController(from rootViewController: UIViewController)
        -> UINavigationController?
    {
        if let navigationController = rootViewController as? UINavigationController {
            return navigationController
        }

        for child in rootViewController.children {
            if let navigationController = child as? UINavigationController {
                return navigationController
            }

            if let navigationController = findNavigationController(from: child) {
                return navigationController
            }
        }

        return nil
    }
}
