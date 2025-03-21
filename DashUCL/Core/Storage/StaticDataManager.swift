import Combine
import Foundation
import SwiftUI

/// 静态数据管理类，用于管理只需要加载一次的数据，如房间、部门等
@MainActor
class StaticDataManager: ObservableObject {
    // 单例模式
    static let shared = StaticDataManager()

    // 缓存管理器
    private let cacheManager = CacheManager.shared

    // 配置导出工具
    private let configExporter = ConfigDataExporter.shared

    // 数据状态
    @Published private(set) var isLoaded = false
    @Published var errorMessage: String?

    // 数据源标记
    @Published private(set) var departmentsFromConfig = false
    @Published private(set) var roomsFromConfig = false
    @Published private(set) var locationsFromConfig = false

    // 静态数据集合
    @Published private(set) var rooms: [Room] = []
    @Published private(set) var departments: [UCLDepartment] = []
    @Published private(set) var libCalLocations: [UCLLibCalLocation] = []

    // 取消令牌
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // 监听静态数据加载完成的通知
        NotificationCenter.default.publisher(for: .staticDataLoaded)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.loadCachedStaticData()
                }
            }
            .store(in: &cancellables)

        // 初始尝试加载缓存
        Task {
            await loadStaticData()
        }
    }

    /// 加载静态数据 - 优先从配置文件加载，然后尝试缓存，最后从API获取
    private func loadStaticData() async {
        // 先尝试从配置文件加载
        let configLoaded = await loadFromConfig()

        // 如果配置文件加载不完整，再尝试从缓存加载
        if !configLoaded {
            await loadCachedStaticData()
        }

        // 更新加载状态
        isLoaded = !rooms.isEmpty || !departments.isEmpty || !libCalLocations.isEmpty
    }

    /// 从配置文件加载数据
    private func loadFromConfig() async -> Bool {
        var allDataLoaded = true

        // 加载部门数据
        if let configDepartments = configExporter.getExportedDepartments() {
            self.departments = configDepartments
            self.departmentsFromConfig = true
            print("已从配置文件加载 \(configDepartments.count) 个部门信息")
        } else {
            allDataLoaded = false
        }

        // 加载LibCal位置数据
        if let configLocations = configExporter.getExportedLibCalLocations() {
            self.libCalLocations = configLocations
            self.locationsFromConfig = true
            print("已从配置文件加载 \(configLocations.count) 个LibCal位置信息")
        } else {
            allDataLoaded = false
        }

        // 房间类型数据仍然需要从API获取具体房间实例，暂不支持从配置文件完全加载

        return allDataLoaded
    }

    /// 从缓存加载静态数据
    private func loadCachedStaticData() async {
        // 如果部门数据未从配置文件加载，尝试从缓存加载
        if !departmentsFromConfig {
            if let cachedDepartments: [UCLDepartment] = try? await cacheManager.retrieve(
                forKey: "staticDepartments")
            {
                self.departments = cachedDepartments
                print("已从缓存加载 \(cachedDepartments.count) 个部门信息")
            }
        }

        // 如果LibCal位置数据未从配置文件加载，尝试从缓存加载
        if !locationsFromConfig {
            if let cachedLocations: [UCLLibCalLocation] = try? await cacheManager.retrieve(
                forKey: "staticLibCalLocations")
            {
                self.libCalLocations = cachedLocations
                print("已从缓存加载 \(cachedLocations.count) 个LibCal位置信息")
            }
        }

        // 房间数据总是尝试从缓存加载
        if let cachedRooms: [Room] = try? await cacheManager.retrieve(forKey: "staticRooms") {
            self.rooms = cachedRooms
            print("已从缓存加载 \(cachedRooms.count) 个房间信息")
        }

        // 更新加载状态
        isLoaded = !rooms.isEmpty || !departments.isEmpty || !libCalLocations.isEmpty
    }

    /// 将原始部门数据处理并缓存为模型数组
    func processDepartmentsData(_ data: Data) async {
        // 如果已经从配置文件加载了部门数据，就不再处理API数据
        if departmentsFromConfig {
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let departmentsArray = json["departments"] as? [[String: Any]]
            {

                // 转换为Department模型
                let depts = departmentsArray.compactMap { dict -> UCLDepartment? in
                    let id = dict["id"] as? String ?? ""
                    let name = dict["name"] as? String ?? ""
                    let code = dict["department_id"] as? String ?? ""
                    return UCLDepartment(id: id, name: name, code: code)
                }

                // 缓存处理后的模型数组
                try await cacheManager.cache(depts, forKey: "staticDepartments")

                // 只有当尚未从配置文件加载数据时才更新内存中的数据
                if !departmentsFromConfig {
                    self.departments = depts
                    print("已处理并缓存 \(depts.count) 个部门信息")
                }
            }
        } catch {
            print("处理部门数据失败: \(error)")
        }
    }

    /// 将原始LibCal位置数据处理并缓存为模型数组
    func processLibCalLocationsData(_ data: Data) async {
        // 如果已经从配置文件加载了LibCal位置数据，就不再处理API数据
        if locationsFromConfig {
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let locationsArray = json["locations"] as? [[String: Any]]
            {

                // 转换为LibCalLocation模型
                let locations = locationsArray.compactMap { dict -> UCLLibCalLocation? in
                    let idValue = dict["id"]
                    let id: String
                    if let intId = idValue as? Int {
                        id = String(intId)
                    } else if let stringId = idValue as? String {
                        id = stringId
                    } else {
                        id = ""
                    }

                    let name = dict["name"] as? String ?? ""
                    let description = dict["description"] as? String ?? ""
                    return UCLLibCalLocation(id: id, name: name, description: description)
                }

                // 缓存处理后的模型数组
                try await cacheManager.cache(locations, forKey: "staticLibCalLocations")

                // 只有当尚未从配置文件加载数据时才更新内存中的数据
                if !locationsFromConfig {
                    self.libCalLocations = locations
                    print("已处理并缓存 \(locations.count) 个LibCal位置信息")
                }
            }
        } catch {
            print("处理LibCal位置数据失败: \(error)")
        }
    }

    /// 将原始房间数据处理并缓存为模型数组
    func processRoomsData(_ data: Data) async {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            // 尝试解析为RoomResponse格式
            if let response = try? decoder.decode(RoomResponse.self, from: data),
                let rooms = response.rooms
            {
                // 缓存数据
                try await cacheManager.cache(rooms, forKey: "staticRooms")

                // 更新内存中的数据
                self.rooms = rooms
                print("已处理并缓存 \(rooms.count) 个房间信息")
            } else {
                // 尝试直接解析为[Room]
                if let rooms = try? decoder.decode([Room].self, from: data) {
                    try await cacheManager.cache(rooms, forKey: "staticRooms")

                    // 更新内存中的数据
                    self.rooms = rooms
                    print("已处理并缓存 \(rooms.count) 个房间信息")
                } else {
                    print("无法解析房间数据")
                }
            }
        } catch {
            print("处理房间数据失败: \(error)")
        }
    }

    /// 获取房间信息
    func getRooms() -> [Room] {
        return rooms
    }

    /// 获取特定ID的房间
    func getRoom(byId id: String) -> Room? {
        return rooms.first { $0.id == id }
    }

    /// 获取部门列表
    func getDepartments() -> [UCLDepartment] {
        return departments
    }

    /// 获取部门名称列表
    func getDepartmentNames() -> [String] {
        return departments.map { $0.name }
    }

    /// 获取部门ID列表
    func getDepartmentIds() -> [String] {
        return departments.map { $0.id }
    }

    /// 按ID获取部门
    func getDepartment(byId id: String) -> UCLDepartment? {
        return departments.first { $0.id == id }
    }

    /// 获取LibCal位置列表
    func getLibCalLocations() -> [UCLLibCalLocation] {
        return libCalLocations
    }

    /// 获取LibCal位置名称列表
    func getLibCalLocationNames() -> [String] {
        return libCalLocations.map { $0.name }
    }

    /// 按ID获取LibCal位置
    func getLibCalLocation(byId id: String) -> UCLLibCalLocation? {
        return libCalLocations.first { $0.id == id }
    }

    /// 清除所有静态数据缓存
    func clearCache() async {
        do {
            try await cacheManager.cache([] as [Room], forKey: "staticRooms")
            try await cacheManager.cache([] as [UCLDepartment], forKey: "staticDepartments")
            try await cacheManager.cache([] as [UCLLibCalLocation], forKey: "staticLibCalLocations")

            // 清除内存中的数据
            self.rooms = []

            // 只清除未从配置文件加载的数据
            if !departmentsFromConfig {
                self.departments = []
            }

            if !locationsFromConfig {
                self.libCalLocations = []
            }

            isLoaded = departmentsFromConfig || locationsFromConfig
            print("静态数据缓存已清除")
        } catch {
            errorMessage = "清除缓存失败: \(error.localizedDescription)"
            print("清除静态数据缓存失败: \(error)")
        }
    }

    /// 手动更新配置文件内容
    func updateConfigFiles() async {
        await ConfigDataExporter.shared.exportAllConfigData()
        // 重新加载配置文件内容
        _ = await loadFromConfig()
    }
}

// MARK: - 自定义静态数据模型

/// 部门模型
struct UCLDepartment: Identifiable, Codable {
    let id: String
    let name: String
    let code: String
}

/// LibCal位置模型
struct UCLLibCalLocation: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
}
