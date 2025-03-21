import Foundation
import SwiftUI
import UserNotifications

/// 通知管理器，用于统一管理各类通知
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    // 发布通知状态
    @Published var isNotificationsAuthorized: Bool = false
    @Published var hasPendingClassReminders: Bool = false

    // 引用AppSettings
    private let appSettings = AppSettings.shared

    // 引用ClassReminderService
    private let classReminderService = ClassReminderService.shared

    private init() {
        // 检查通知授权状态
        checkNotificationAuthorizationStatus()

        // 监听授权状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // 检查是否有待处理的课程提醒
        updatePendingRemindersStatus()
    }

    /// 检查通知授权状态
    func checkNotificationAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// 请求通知权限
    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            DispatchQueue.main.async {
                self.isNotificationsAuthorized = granted
                completion(granted)

                // 如果授权成功，同步更新AppSettings中的通知开关
                if granted {
                    self.appSettings.notificationsEnabled = true
                }
            }
        }
    }

    /// 更新待处理课程提醒状态
    func updatePendingRemindersStatus() {
        classReminderService.getPendingReminders { requests in
            DispatchQueue.main.async {
                self.hasPendingClassReminders = !requests.isEmpty
            }
        }
    }

    /// 切换课程提醒的启用状态
    func toggleCourseReminders(enabled: Bool) {
        if enabled {
            // 如果启用，确保有通知权限
            if !isNotificationsAuthorized {
                requestNotificationAuthorization { granted in
                    if granted {
                        // 权限获取成功，重新安排所有课程提醒
                        self.rescheduleCourseReminders()
                    }
                }
            } else {
                // 已有权限，重新安排所有课程提醒
                rescheduleCourseReminders()
            }
        } else {
            // 如果禁用，取消所有课程提醒
            classReminderService.cancelAllReminders()
            updatePendingRemindersStatus()
        }
    }

    /// 更新课程提醒时间
    func updateCourseReminderTime(minutes: Int) {
        // 更新AppSettings中的提醒时间
        appSettings.courseReminderTime = minutes

        // 如果通知已启用，重新安排所有课程提醒
        if appSettings.notificationsEnabled {
            rescheduleCourseReminders()
        }
    }

    /// 重新安排所有课程提醒（基于新的设置）
    private func rescheduleCourseReminders() {
        // 先取消所有现有提醒
        classReminderService.cancelAllReminders()

        // 获取课程数据并重新安排提醒
        // 注意：这里需要根据实际的课程数据获取方式进行调整
        Task {
            await scheduleRemindersForUpcomingClasses()
            updatePendingRemindersStatus()
        }
    }

    /// 为即将到来的课程安排提醒
    /// 需要根据具体的课程数据获取逻辑进行调整
    private func scheduleRemindersForUpcomingClasses() async {
        // 获取TimetableViewModel实例
        let timetableViewModel = await TimetableViewModel(
            networkService: NetworkService(),
            cacheManager: CacheManager.shared
        )

        // 获取最新的课程数据
        do {
            try await timetableViewModel.fetchTimetable()

            // 过滤出未来的课程
            let futureEvents = await timetableViewModel.allEvents.filter { event in
                return event.startTime > Date()
            }

            // 为每个课程安排提醒
            for event in futureEvents {
                let classInfo = ClassInfo(
                    id: event.id.uuidString,
                    title: event.module.name,
                    location: event.location.name,
                    startTime: event.startTime,
                    endTime: event.endTime
                )

                // 使用用户设置的提醒时间
                classReminderService.scheduleReminder(
                    for: classInfo,
                    minutesBefore: appSettings.courseReminderTime
                )
            }

            print("成功为 \(futureEvents.count) 个未来课程安排提醒")
        } catch {
            print("获取课程数据失败: \(error.localizedDescription)")
        }
    }

    /// 应用变为活跃状态时更新通知授权状态
    @objc private func appDidBecomeActive() {
        checkNotificationAuthorizationStatus()
        updatePendingRemindersStatus()
    }
}
