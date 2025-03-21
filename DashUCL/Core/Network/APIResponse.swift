/*
 * Standard response format for API requests with type-safe generic data handling.
 * Provides consistent error handling and response parsing across the application.
 * Implements Codable for automatic JSON encoding and decoding.
 * Includes specialized structures for different API response types.
 */

import Foundation

struct APIResponse<T: Codable>: Codable {
    let ok: Bool
    let data: T?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case data
        case error
        // User data fields
        case email
        case full_name
        case department
        case cn
        case given_name
        case upi
        case scope_number
        case is_student
        case ucl_groups
        case sn
        case mail
        case userTypes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ok = try container.decode(Bool.self, forKey: .ok)
        error = try container.decodeIfPresent(String.self, forKey: .error)

        if T.self == UserData.self {
            let email = try container.decode(String.self, forKey: .email)
            let fullName = try container.decode(String.self, forKey: .full_name)
            let department = try container.decode(String.self, forKey: .department)
            let cn = try container.decode(String.self, forKey: .cn)
            let givenName = try container.decode(String.self, forKey: .given_name)
            let upi = try container.decode(String.self, forKey: .upi)
            let scopeNumber = try container.decode(Int.self, forKey: .scope_number)
            let isStudent = try container.decode(Bool.self, forKey: .is_student)
            let uclGroups = try container.decode([String].self, forKey: .ucl_groups)
            let sn = try container.decode(String.self, forKey: .sn)
            let mail = try container.decode(String.self, forKey: .mail)
            let userTypes = try container.decode([String].self, forKey: .userTypes)

            data =
                UserData(
                    ok: ok,
                    cn: cn,
                    department: department,
                    email: email,
                    fullName: fullName,
                    givenName: givenName,
                    upi: upi,
                    scopeNumber: scopeNumber,
                    isStudent: isStudent,
                    uclGroups: uclGroups,
                    sn: sn,
                    mail: mail,
                    userTypes: userTypes
                ) as? T
        } else {
            data = try container.decodeIfPresent(T.self, forKey: .data)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ok, forKey: .ok)
        try container.encodeIfPresent(error, forKey: .error)

        if let userData = data as? UserData {
            try container.encode(userData.email, forKey: .email)
            try container.encode(userData.fullName, forKey: .full_name)
            try container.encode(userData.department, forKey: .department)
            try container.encode(userData.cn, forKey: .cn)
            try container.encode(userData.givenName, forKey: .given_name)
            try container.encode(userData.upi, forKey: .upi)
            try container.encode(userData.scopeNumber, forKey: .scope_number)
            try container.encode(userData.isStudent, forKey: .is_student)
            try container.encode(userData.uclGroups, forKey: .ucl_groups)
            try container.encode(userData.sn, forKey: .sn)
            try container.encode(userData.mail, forKey: .mail)
            try container.encode(userData.userTypes, forKey: .userTypes)
        } else {
            try container.encodeIfPresent(data, forKey: .data)
        }
    }
}
