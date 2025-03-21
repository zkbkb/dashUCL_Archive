/*
 * Development utility for exporting API configuration data to local static files.
 * Captures standardized data like departments and room types for offline access.
 * Provides export status monitoring and success/failure notifications.
 * Supports development workflow for maintaining up-to-date reference data.
 */

import Foundation
import SwiftUI

/// Configuration data export tool, used to export static data such as departments and room types obtained from API to configuration files
@MainActor
class ConfigDataExporter: ObservableObject {
    // 单例模式
    static let shared = ConfigDataExporter()

    // 网络服务
    private let networkService = NetworkService()

    // 导出状态
    @Published private(set) var isExporting = false
    @Published private(set) var lastExportDate: Date?
    @Published var exportMessage: String?

    // 数据存储路径
    private let configDirectoryName = "Config"
    private let departmentsFileName = "departments.json"
    private let roomTypesFileName = "roomTypes.json"
    private let libCalLocationsFileName = "libCalLocations.json"

    private init() {}

    /// Get configuration file directory URL
    private func getConfigDirectoryURL() -> URL? {
        guard
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            exportMessage = "Cannot access documents directory"
            return nil
        }

        let configDirectory = documentsDirectory.appendingPathComponent(configDirectoryName)

        // 确保目录存在
        if !FileManager.default.fileExists(atPath: configDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: configDirectory, withIntermediateDirectories: true)
            } catch {
                exportMessage = "Failed to create config directory: \(error.localizedDescription)"
                return nil
            }
        }

        return configDirectory
    }

    /// Export department data to configuration file
    func exportDepartmentsToConfig() async -> Bool {
        isExporting = true
        exportMessage = "Exporting department data..."

        do {
            // 获取部门数据
            let deptsData = try await networkService.fetchRawData(endpoint: .timetableDepartments)

            // 解析JSON
            guard let json = try JSONSerialization.jsonObject(with: deptsData) as? [String: Any],
                let departmentsArray = json["departments"] as? [[String: Any]]
            else {
                exportMessage = "Invalid department data format"
                isExporting = false
                return false
            }

            // 转换为模型数组
            let departments = departmentsArray.compactMap { dict -> UCLDepartment? in
                let id = dict["id"] as? String ?? ""
                let name = dict["name"] as? String ?? ""
                let code = dict["department_id"] as? String ?? ""
                return UCLDepartment(id: id, name: name, code: code)
            }

            // 获取配置目录
            guard let configDirectory = getConfigDirectoryURL() else {
                isExporting = false
                return false
            }

            // 创建JSON数据
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(departments)

            // 保存到文件
            let fileURL = configDirectory.appendingPathComponent(departmentsFileName)
            try jsonData.write(to: fileURL)

            exportMessage =
                "Successfully exported \(departments.count) departments to configuration file"
            print("Departments data exported to: \(fileURL.path)")

            // 记录导出时间
            lastExportDate = Date()
            return true
        } catch {
            exportMessage = "Failed to export departments data: \(error.localizedDescription)"
            print("Failed to export departments data: \(error)")
            isExporting = false
            return false
        }
    }

    /// Export room type data to configuration file
    func exportRoomTypesToConfig() async -> Bool {
        isExporting = true
        exportMessage = "正在导出房间类型数据..."

        do {
            // 使用RoomType枚举中的所有案例
            let roomTypes = RoomType.allCases.map { type -> [String: String] in
                return [
                    "id": type.rawValue,
                    "name": type.displayName,
                ]
            }

            // 获取配置目录
            guard let configDirectory = getConfigDirectoryURL() else {
                isExporting = false
                return false
            }

            // 创建JSON数据
            let jsonData = try JSONSerialization.data(
                withJSONObject: roomTypes, options: [.prettyPrinted, .sortedKeys])

            // 保存到文件
            let fileURL = configDirectory.appendingPathComponent(roomTypesFileName)
            try jsonData.write(to: fileURL)

            exportMessage = "成功导出 \(roomTypes.count) 个房间类型到配置文件"
            print("已导出房间类型数据到: \(fileURL.path)")

            // 记录导出时间
            lastExportDate = Date()
            return true
        } catch {
            exportMessage = "导出房间类型数据失败: \(error.localizedDescription)"
            print("导出房间类型数据失败: \(error)")
            isExporting = false
            return false
        }
    }

    /// Export LibCal location data to configuration file
    func exportLibCalLocationsToConfig() async -> Bool {
        isExporting = true
        exportMessage = "正在导出LibCal位置数据..."

        do {
            // 获取LibCal位置数据
            let locationsData = try await networkService.fetchRawData(endpoint: .libCalLocations)

            // 解析JSON
            guard
                let json = try JSONSerialization.jsonObject(with: locationsData) as? [String: Any],
                let locationsArray = json["locations"] as? [[String: Any]]
            else {
                exportMessage = "LibCal位置数据格式不正确"
                isExporting = false
                return false
            }

            // 转换为模型数组
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

            // 获取配置目录
            guard let configDirectory = getConfigDirectoryURL() else {
                isExporting = false
                return false
            }

            // 创建JSON数据
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(locations)

            // 保存到文件
            let fileURL = configDirectory.appendingPathComponent(libCalLocationsFileName)
            try jsonData.write(to: fileURL)

            exportMessage = "成功导出 \(locations.count) 个LibCal位置到配置文件"
            print("已导出LibCal位置数据到: \(fileURL.path)")

            // 记录导出时间
            lastExportDate = Date()
            return true
        } catch {
            exportMessage = "导出LibCal位置数据失败: \(error.localizedDescription)"
            print("导出LibCal位置数据失败: \(error)")
            isExporting = false
            return false
        }
    }

    /// Export all configuration data
    func exportAllConfigData() async {
        isExporting = true
        exportMessage = "正在导出所有静态配置数据..."

        let deptSuccess = await exportDepartmentsToConfig()
        let roomTypesSuccess = await exportRoomTypesToConfig()
        let locationsSuccess = await exportLibCalLocationsToConfig()

        if deptSuccess && roomTypesSuccess && locationsSuccess {
            exportMessage = "所有配置数据导出成功"
        } else {
            exportMessage = "部分配置数据导出失败"
        }

        isExporting = false
    }

    /// Get exported department data
    func getExportedDepartments() -> [UCLDepartment]? {
        guard let configDirectory = getConfigDirectoryURL() else {
            return nil
        }

        let fileURL = configDirectory.appendingPathComponent(departmentsFileName)

        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONDecoder().decode([UCLDepartment].self, from: data)
    }

    /// Get exported room type data
    func getExportedRoomTypes() -> [[String: String]]? {
        guard let configDirectory = getConfigDirectoryURL() else {
            return nil
        }

        let fileURL = configDirectory.appendingPathComponent(roomTypesFileName)

        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
    }

    /// Get exported LibCal location data
    func getExportedLibCalLocations() -> [UCLLibCalLocation]? {
        guard let configDirectory = getConfigDirectoryURL() else {
            return nil
        }

        let fileURL = configDirectory.appendingPathComponent(libCalLocationsFileName)

        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONDecoder().decode([UCLLibCalLocation].self, from: data)
    }
}
