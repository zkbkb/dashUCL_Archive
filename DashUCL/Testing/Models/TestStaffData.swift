import Foundation
import SwiftUI

/// Test Staff Data
/// Provides mock UCL staff data

/// Test Mode Staff Data
enum TestStaffData {
    // MARK: - Staff Model

    /// Staff Model
    struct StaffMember: Identifiable, Codable {
        let id: String
        let name: String
        let email: String
        let department: String
        let position: String
        let officeLocation: String
        let phoneNumber: String
        let researchInterests: [String]
        let profileImageURL: String?

        var departmentAbbreviation: String {
            department.split(separator: " ")
                .map { String($0.prefix(1)) }
                .joined()
        }

        // Convert to PersonResult format
        func toPersonResult() -> Features.Search.PersonResult {
            return Features.Search.PersonResult(
                id: self.id,
                name: self.name,
                email: self.email,
                department: self.department,
                position: self.position
            )
        }
    }

    // MARK: - Department Data

    /// UCL Departments
    static let departments = [
        "Computer Science",
        "Mathematics",
        "Physics and Astronomy",
        "Statistical Science",
        "Chemistry",
        "Biological Sciences",
        "Medical Sciences",
        "Engineering",
        "Architecture",
        "Economics",
        "Geography",
        "History",
        "Law",
        "Psychology",
        "Linguistics",
    ]

    /// Positions
    static let positions = [
        "Professor",
        "Associate Professor",
        "Assistant Professor",
        "Senior Lecturer",
        "Lecturer",
        "Research Fellow",
        "Teaching Fellow",
        "Emeritus Professor",
        "Visiting Professor",
        "Honorary Professor",
    ]

    /// Research Interests
    static let researchInterests = [
        "Artificial Intelligence",
        "Machine Learning",
        "Computer Vision",
        "Natural Language Processing",
        "Robotics",
        "Human-Computer Interaction",
        "Software Engineering",
        "Cybersecurity",
        "Data Science",
        "Quantum Computing",
        "Theoretical Physics",
        "Astrophysics",
        "Particle Physics",
        "Condensed Matter Physics",
        "Organic Chemistry",
        "Inorganic Chemistry",
        "Physical Chemistry",
        "Analytical Chemistry",
        "Molecular Biology",
        "Cell Biology",
        "Genetics",
        "Neuroscience",
        "Immunology",
        "Ecology",
        "Evolution",
        "Pure Mathematics",
        "Applied Mathematics",
        "Statistics",
        "Probability Theory",
        "Econometrics",
        "Microeconomics",
        "Macroeconomics",
        "International Economics",
        "Development Economics",
        "Constitutional Law",
        "Criminal Law",
        "International Law",
        "Human Rights Law",
        "Commercial Law",
        "Cognitive Psychology",
        "Clinical Psychology",
        "Developmental Psychology",
        "Social Psychology",
        "Phonetics",
        "Syntax",
        "Semantics",
        "Sociolinguistics",
        "Historical Linguistics",
    ]

    // MARK: - Staff Data

    /// 40 randomly generated UCL staff members
    static let staffMembers: [StaffMember] = [
        StaffMember(
            id: "staff-001",
            name: "Dr. James Wilson",
            email: "james.wilson@ucl.ac.uk",
            department: "Computer Science",
            position: "Professor",
            officeLocation: "Malet Place Engineering Building 6.12",
            phoneNumber: "+44 20 7679 1234",
            researchInterests: ["Artificial Intelligence", "Machine Learning", "Computer Vision"],
            profileImageURL: "https://randomuser.me/api/portraits/men/1.jpg"
        ),
        StaffMember(
            id: "staff-002",
            name: "Dr. Sarah Johnson",
            email: "sarah.johnson@ucl.ac.uk",
            department: "Mathematics",
            position: "Associate Professor",
            officeLocation: "25 Gordon Street, Room 505",
            phoneNumber: "+44 20 7679 2345",
            researchInterests: ["Pure Mathematics", "Applied Mathematics", "Probability Theory"],
            profileImageURL: "https://randomuser.me/api/portraits/women/2.jpg"
        ),
        StaffMember(
            id: "staff-003",
            name: "Prof. Michael Brown",
            email: "michael.brown@ucl.ac.uk",
            department: "Physics and Astronomy",
            position: "Professor",
            officeLocation: "Physics Building A12",
            phoneNumber: "+44 20 7679 3456",
            researchInterests: ["Theoretical Physics", "Astrophysics", "Quantum Computing"],
            profileImageURL: "https://randomuser.me/api/portraits/men/3.jpg"
        ),
        StaffMember(
            id: "staff-004",
            name: "Dr. Emily Davis",
            email: "emily.davis@ucl.ac.uk",
            department: "Statistical Science",
            position: "Senior Lecturer",
            officeLocation: "1-19 Torrington Place, Room 102",
            phoneNumber: "+44 20 7679 4567",
            researchInterests: ["Statistics", "Data Science", "Machine Learning"],
            profileImageURL: "https://randomuser.me/api/portraits/women/4.jpg"
        ),
        StaffMember(
            id: "staff-005",
            name: "Prof. Robert Taylor",
            email: "robert.taylor@ucl.ac.uk",
            department: "Chemistry",
            position: "Professor",
            officeLocation: "Christopher Ingold Building 231",
            phoneNumber: "+44 20 7679 5678",
            researchInterests: ["Organic Chemistry", "Physical Chemistry", "Analytical Chemistry"],
            profileImageURL: "https://randomuser.me/api/portraits/men/5.jpg"
        ),
        StaffMember(
            id: "staff-006",
            name: "Dr. Jennifer White",
            email: "jennifer.white@ucl.ac.uk",
            department: "Biological Sciences",
            position: "Lecturer",
            officeLocation: "Darwin Building 301",
            phoneNumber: "+44 20 7679 6789",
            researchInterests: ["Molecular Biology", "Genetics", "Cell Biology"],
            profileImageURL: "https://randomuser.me/api/portraits/women/6.jpg"
        ),
        StaffMember(
            id: "staff-007",
            name: "Prof. David Miller",
            email: "david.miller@ucl.ac.uk",
            department: "Medical Sciences",
            position: "Professor",
            officeLocation: "Rockefeller Building 201",
            phoneNumber: "+44 20 7679 7890",
            researchInterests: ["Neuroscience", "Immunology", "Cell Biology"],
            profileImageURL: "https://randomuser.me/api/portraits/men/7.jpg"
        ),
        StaffMember(
            id: "staff-008",
            name: "Dr. Lisa Anderson",
            email: "lisa.anderson@ucl.ac.uk",
            department: "Engineering",
            position: "Associate Professor",
            officeLocation: "Roberts Building 412",
            phoneNumber: "+44 20 7679 8901",
            researchInterests: ["Robotics", "Software Engineering", "Human-Computer Interaction"],
            profileImageURL: "https://randomuser.me/api/portraits/women/8.jpg"
        ),
        StaffMember(
            id: "staff-009",
            name: "Prof. Thomas Clark",
            email: "thomas.clark@ucl.ac.uk",
            department: "Architecture",
            position: "Professor",
            officeLocation: "22 Gordon Street, Room 301",
            phoneNumber: "+44 20 7679 9012",
            researchInterests: [
                "Architectural Design", "Urban Planning", "Sustainable Architecture",
            ],
            profileImageURL: "https://randomuser.me/api/portraits/men/9.jpg"
        ),
        StaffMember(
            id: "staff-010",
            name: "Dr. Emma Lewis",
            email: "emma.lewis@ucl.ac.uk",
            department: "Economics",
            position: "Senior Lecturer",
            officeLocation: "Drayton House 321",
            phoneNumber: "+44 20 7679 0123",
            researchInterests: ["Microeconomics", "Macroeconomics", "Development Economics"],
            profileImageURL: "https://randomuser.me/api/portraits/women/10.jpg"
        ),
        StaffMember(
            id: "staff-011",
            name: "Prof. Richard Harris",
            email: "richard.harris@ucl.ac.uk",
            department: "Geography",
            position: "Professor",
            officeLocation: "North-West Wing, Room 115",
            phoneNumber: "+44 20 7679 1234",
            researchInterests: ["Climate Change", "Urban Geography", "GIS"],
            profileImageURL: "https://randomuser.me/api/portraits/men/11.jpg"
        ),
        StaffMember(
            id: "staff-012",
            name: "Dr. Catherine Martin",
            email: "catherine.martin@ucl.ac.uk",
            department: "History",
            position: "Lecturer",
            officeLocation: "Foster Court 101",
            phoneNumber: "+44 20 7679 2345",
            researchInterests: ["Medieval History", "European History", "Social History"],
            profileImageURL: "https://randomuser.me/api/portraits/women/12.jpg"
        ),
        StaffMember(
            id: "staff-013",
            name: "Prof. William Thompson",
            email: "william.thompson@ucl.ac.uk",
            department: "Law",
            position: "Professor",
            officeLocation: "Bentham House 201",
            phoneNumber: "+44 20 7679 3456",
            researchInterests: ["Constitutional Law", "International Law", "Human Rights Law"],
            profileImageURL: "https://randomuser.me/api/portraits/men/13.jpg"
        ),
        StaffMember(
            id: "staff-014",
            name: "Dr. Olivia Walker",
            email: "olivia.walker@ucl.ac.uk",
            department: "Psychology",
            position: "Associate Professor",
            officeLocation: "26 Bedford Way, Room 301",
            phoneNumber: "+44 20 7679 4567",
            researchInterests: [
                "Cognitive Psychology", "Developmental Psychology", "Social Psychology",
            ],
            profileImageURL: "https://randomuser.me/api/portraits/women/14.jpg"
        ),
        StaffMember(
            id: "staff-015",
            name: "Prof. Daniel Scott",
            email: "daniel.scott@ucl.ac.uk",
            department: "Linguistics",
            position: "Professor",
            officeLocation: "Chandler House 115",
            phoneNumber: "+44 20 7679 5678",
            researchInterests: ["Phonetics", "Syntax", "Sociolinguistics"],
            profileImageURL: "https://randomuser.me/api/portraits/men/15.jpg"
        ),
        StaffMember(
            id: "staff-016",
            name: "Dr. Sophie Green",
            email: "sophie.green@ucl.ac.uk",
            department: "Computer Science",
            position: "Research Fellow",
            officeLocation: "Malet Place Engineering Building 5.10",
            phoneNumber: "+44 20 7679 6789",
            researchInterests: [
                "Natural Language Processing", "Machine Learning", "Artificial Intelligence",
            ],
            profileImageURL: "https://randomuser.me/api/portraits/women/16.jpg"
        ),
        StaffMember(
            id: "staff-017",
            name: "Prof. Andrew Baker",
            email: "andrew.baker@ucl.ac.uk",
            department: "Mathematics",
            position: "Professor",
            officeLocation: "25 Gordon Street, Room 605",
            phoneNumber: "+44 20 7679 7890",
            researchInterests: ["Number Theory", "Algebra", "Mathematical Logic"],
            profileImageURL: "https://randomuser.me/api/portraits/men/17.jpg"
        ),
        StaffMember(
            id: "staff-018",
            name: "Dr. Rachel Adams",
            email: "rachel.adams@ucl.ac.uk",
            department: "Physics and Astronomy",
            position: "Lecturer",
            officeLocation: "Physics Building B15",
            phoneNumber: "+44 20 7679 8901",
            researchInterests: ["Particle Physics", "Condensed Matter Physics", "Quantum Physics"],
            profileImageURL: "https://randomuser.me/api/portraits/women/18.jpg"
        ),
        StaffMember(
            id: "staff-019",
            name: "Prof. Christopher Evans",
            email: "christopher.evans@ucl.ac.uk",
            department: "Statistical Science",
            position: "Professor",
            officeLocation: "1-19 Torrington Place, Room 202",
            phoneNumber: "+44 20 7679 9012",
            researchInterests: ["Bayesian Statistics", "Statistical Computing", "Biostatistics"],
            profileImageURL: "https://randomuser.me/api/portraits/men/19.jpg"
        ),
        StaffMember(
            id: "staff-020",
            name: "Dr. Natalie Roberts",
            email: "natalie.roberts@ucl.ac.uk",
            department: "Chemistry",
            position: "Senior Lecturer",
            officeLocation: "Christopher Ingold Building 331",
            phoneNumber: "+44 20 7679 0123",
            researchInterests: ["Inorganic Chemistry", "Materials Chemistry", "Catalysis"],
            profileImageURL: "https://randomuser.me/api/portraits/women/20.jpg"
        ),
        StaffMember(
            id: "staff-021",
            name: "Prof. Jonathan Phillips",
            email: "jonathan.phillips@ucl.ac.uk",
            department: "Biological Sciences",
            position: "Professor",
            officeLocation: "Darwin Building 401",
            phoneNumber: "+44 20 7679 1234",
            researchInterests: ["Ecology", "Evolution", "Conservation Biology"],
            profileImageURL: "https://randomuser.me/api/portraits/men/21.jpg"
        ),
        StaffMember(
            id: "staff-022",
            name: "Dr. Victoria Campbell",
            email: "victoria.campbell@ucl.ac.uk",
            department: "Medical Sciences",
            position: "Associate Professor",
            officeLocation: "Rockefeller Building 301",
            phoneNumber: "+44 20 7679 2345",
            researchInterests: ["Cancer Biology", "Molecular Medicine", "Genetics"],
            profileImageURL: "https://randomuser.me/api/portraits/women/22.jpg"
        ),
        StaffMember(
            id: "staff-023",
            name: "Prof. Matthew Turner",
            email: "matthew.turner@ucl.ac.uk",
            department: "Engineering",
            position: "Professor",
            officeLocation: "Roberts Building 512",
            phoneNumber: "+44 20 7679 3456",
            researchInterests: ["Mechanical Engineering", "Fluid Dynamics", "Energy Systems"],
            profileImageURL: "https://randomuser.me/api/portraits/men/23.jpg"
        ),
        StaffMember(
            id: "staff-024",
            name: "Dr. Hannah Mitchell",
            email: "hannah.mitchell@ucl.ac.uk",
            department: "Architecture",
            position: "Lecturer",
            officeLocation: "22 Gordon Street, Room 401",
            phoneNumber: "+44 20 7679 4567",
            researchInterests: ["Architectural History", "Building Technology", "Design Theory"],
            profileImageURL: "https://randomuser.me/api/portraits/women/24.jpg"
        ),
        StaffMember(
            id: "staff-025",
            name: "Prof. Benjamin Cooper",
            email: "benjamin.cooper@ucl.ac.uk",
            department: "Economics",
            position: "Professor",
            officeLocation: "Drayton House 421",
            phoneNumber: "+44 20 7679 5678",
            researchInterests: ["International Economics", "Econometrics", "Financial Economics"],
            profileImageURL: "https://randomuser.me/api/portraits/men/25.jpg"
        ),
        StaffMember(
            id: "staff-026",
            name: "Dr. Alexandra Ward",
            email: "alexandra.ward@ucl.ac.uk",
            department: "Geography",
            position: "Research Fellow",
            officeLocation: "North-West Wing, Room 215",
            phoneNumber: "+44 20 7679 6789",
            researchInterests: ["Environmental Geography", "Remote Sensing", "Hydrology"],
            profileImageURL: "https://randomuser.me/api/portraits/women/26.jpg"
        ),
        StaffMember(
            id: "staff-027",
            name: "Prof. Samuel Morgan",
            email: "samuel.morgan@ucl.ac.uk",
            department: "History",
            position: "Professor",
            officeLocation: "Foster Court 201",
            phoneNumber: "+44 20 7679 7890",
            researchInterests: ["Modern History", "Political History", "Cultural History"],
            profileImageURL: "https://randomuser.me/api/portraits/men/27.jpg"
        ),
        StaffMember(
            id: "staff-028",
            name: "Dr. Elizabeth Parker",
            email: "elizabeth.parker@ucl.ac.uk",
            department: "Law",
            position: "Senior Lecturer",
            officeLocation: "Bentham House 301",
            phoneNumber: "+44 20 7679 8901",
            researchInterests: ["Criminal Law", "Commercial Law", "Legal Theory"],
            profileImageURL: "https://randomuser.me/api/portraits/women/28.jpg"
        ),
        StaffMember(
            id: "staff-029",
            name: "Prof. George Allen",
            email: "george.allen@ucl.ac.uk",
            department: "Psychology",
            position: "Professor",
            officeLocation: "26 Bedford Way, Room 401",
            phoneNumber: "+44 20 7679 9012",
            researchInterests: ["Clinical Psychology", "Neuropsychology", "Health Psychology"],
            profileImageURL: "https://randomuser.me/api/portraits/men/29.jpg"
        ),
        StaffMember(
            id: "staff-030",
            name: "Dr. Charlotte Young",
            email: "charlotte.young@ucl.ac.uk",
            department: "Linguistics",
            position: "Associate Professor",
            officeLocation: "Chandler House 215",
            phoneNumber: "+44 20 7679 0123",
            researchInterests: ["Semantics", "Historical Linguistics", "Language Acquisition"],
            profileImageURL: "https://randomuser.me/api/portraits/women/30.jpg"
        ),
        StaffMember(
            id: "staff-031",
            name: "Prof. John Smith",
            email: "john.smith@ucl.ac.uk",
            department: "Computer Science",
            position: "Professor",
            officeLocation: "Malet Place Engineering Building 7.15",
            phoneNumber: "+44 20 7679 1111",
            researchInterests: [
                "Artificial Intelligence", "Machine Learning", "Software Engineering",
            ],
            profileImageURL: "https://randomuser.me/api/portraits/men/31.jpg"
        ),
        StaffMember(
            id: "staff-032",
            name: "Dr. Emily Smith",
            email: "emily.smith@ucl.ac.uk",
            department: "Mathematics",
            position: "Associate Professor",
            officeLocation: "25 Gordon Street, Room 510",
            phoneNumber: "+44 20 7679 2222",
            researchInterests: ["Pure Mathematics", "Number Theory", "Algebra"],
            profileImageURL: "https://randomuser.me/api/portraits/women/32.jpg"
        ),
        StaffMember(
            id: "staff-033",
            name: "Prof. Robert Smith",
            email: "robert.smith@ucl.ac.uk",
            department: "Physics and Astronomy",
            position: "Professor",
            officeLocation: "Physics Building A15",
            phoneNumber: "+44 20 7679 3333",
            researchInterests: ["Theoretical Physics", "Quantum Computing", "Astrophysics"],
            profileImageURL: "https://randomuser.me/api/portraits/men/33.jpg"
        ),
        StaffMember(
            id: "staff-034",
            name: "Dr. John Williams",
            email: "john.williams@ucl.ac.uk",
            department: "Statistical Science",
            position: "Senior Lecturer",
            officeLocation: "1-19 Torrington Place, Room 110",
            phoneNumber: "+44 20 7679 4444",
            researchInterests: ["Statistics", "Data Science", "Machine Learning"],
            profileImageURL: "https://randomuser.me/api/portraits/men/34.jpg"
        ),
        StaffMember(
            id: "staff-035",
            name: "Dr. Sarah John",
            email: "sarah.john@ucl.ac.uk",
            department: "Chemistry",
            position: "Lecturer",
            officeLocation: "Christopher Ingold Building 240",
            phoneNumber: "+44 20 7679 5555",
            researchInterests: ["Organic Chemistry", "Physical Chemistry", "Materials Chemistry"],
            profileImageURL: "https://randomuser.me/api/portraits/women/35.jpg"
        ),
        StaffMember(
            id: "staff-036",
            name: "Prof. Michael Smith-Johnson",
            email: "michael.smith-johnson@ucl.ac.uk",
            department: "Medical Sciences",
            position: "Professor",
            officeLocation: "Rockefeller Building 210",
            phoneNumber: "+44 20 7679 6666",
            researchInterests: ["Neuroscience", "Immunology", "Cell Biology"],
            profileImageURL: "https://randomuser.me/api/portraits/men/36.jpg"
        ),
        StaffMember(
            id: "staff-037",
            name: "Dr. John Anderson",
            email: "john.anderson@ucl.ac.uk",
            department: "Engineering",
            position: "Associate Professor",
            officeLocation: "Roberts Building 420",
            phoneNumber: "+44 20 7679 7777",
            researchInterests: ["Software Engineering", "Robotics", "Human-Computer Interaction"],
            profileImageURL: "https://randomuser.me/api/portraits/men/37.jpg"
        ),
        StaffMember(
            id: "staff-038",
            name: "Prof. Elizabeth Smith",
            email: "elizabeth.smith@ucl.ac.uk",
            department: "Law",
            position: "Professor",
            officeLocation: "Bentham House 210",
            phoneNumber: "+44 20 7679 8888",
            researchInterests: ["Constitutional Law", "International Law", "Human Rights Law"],
            profileImageURL: "https://randomuser.me/api/portraits/women/38.jpg"
        ),
        StaffMember(
            id: "staff-039",
            name: "Dr. Jennifer Smith",
            email: "jennifer.smith@ucl.ac.uk",
            department: "Psychology",
            position: "Senior Lecturer",
            officeLocation: "26 Bedford Way, Room 310",
            phoneNumber: "+44 20 7679 9999",
            researchInterests: [
                "Cognitive Psychology", "Developmental Psychology", "Social Psychology",
            ],
            profileImageURL: "https://randomuser.me/api/portraits/women/39.jpg"
        ),
        StaffMember(
            id: "staff-040",
            name: "Prof. Johnathan Davies",
            email: "johnathan.davies@ucl.ac.uk",
            department: "Linguistics",
            position: "Professor",
            officeLocation: "Chandler House 120",
            phoneNumber: "+44 20 7679 0000",
            researchInterests: ["Phonetics", "Syntax", "Sociolinguistics"],
            profileImageURL: "https://randomuser.me/api/portraits/men/40.jpg"
        ),
    ]

    // MARK: - Helper Methods

    /// Get staff by department
    static func staffByDepartment(_ department: String) -> [StaffMember] {
        return staffMembers.filter { $0.department == department }
    }

    /// Get staff by research interest
    static func staffByResearchInterest(_ interest: String) -> [StaffMember] {
        return staffMembers.filter { $0.researchInterests.contains(interest) }
    }

    /// Get staff by position
    static func staffByPosition(_ position: String) -> [StaffMember] {
        return staffMembers.filter { $0.position == position }
    }

    /// Search staff
    static func searchStaff(query: String) -> [StaffMember] {
        let lowercasedQuery = query.lowercased()

        return staffMembers.filter {
            $0.name.lowercased().contains(lowercasedQuery)
                || $0.email.lowercased().contains(lowercasedQuery)
                || $0.department.lowercased().contains(lowercasedQuery)
                || $0.position.lowercased().contains(lowercasedQuery)
                || $0.researchInterests.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }

    /// Convert StaffMember to PersonResult
    static func staffMembersToPersonResults(staffMembers: [StaffMember]) -> [Features.Search
        .PersonResult]
    {
        return staffMembers.map { staff in
            Features.Search.PersonResult(
                id: staff.id,
                name: staff.name,
                email: staff.email,
                department: staff.department,
                position: staff.position
            )
        }
    }
}
