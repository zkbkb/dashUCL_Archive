import Foundation

struct UserProfile: Codable {
    let ok: Bool
    let cn: String
    let department: String
    let email: String
    let fullName: String
    let givenName: String
    let upi: String
    let scopeNumber: Int
    let isStudent: Bool
    let uclGroups: [String]
    let sn: String
    let mail: String
    let userTypes: [String]

    enum CodingKeys: String, CodingKey {
        case ok
        case cn
        case department
        case email
        case fullName = "full_name"
        case givenName = "given_name"
        case upi
        case scopeNumber = "scope_number"
        case isStudent = "is_student"
        case uclGroups = "ucl_groups"
        case sn
        case mail
        case userTypes = "user_types"
    }
}
