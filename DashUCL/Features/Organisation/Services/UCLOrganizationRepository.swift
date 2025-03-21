import Foundation
import SwiftUI

/// UCL Organization Structure Data Repository
/// Singleton
class UCLOrganizationRepository: ObservableObject {
    /// Singleton instance
    static let shared = UCLOrganizationRepository()

    /// Mapping from organization unit ID to unit
    @Published private(set) var organizationMap: [String: UCLOrganizationUnit] = [:]

    /// Organization structure tree
    @Published private(set) var organizationTree: UCLOrganizationUnit!

    /// Faculty list (first-level units)
    @Published private(set) var faculties: [UCLOrganizationUnit] = []

    private init() {
        buildOrganizationTree()
    }

    /// Build organization structure tree - based on latest UCL structure
    private func buildOrganizationTree() {
        // Create UCL top-level unit
        let university = UCLOrganizationUnit(
            id: "UCL",
            name: "University College London",
            type: .university,
            parentID: nil,
            children: []
        )

        // Store university unit
        organizationMap["UCL"] = university

        // Create faculties
        var allFaculties: [UCLOrganizationUnit] = []

        // 1. Faculty of Arts and Humanities
        var artsFaculty = UCLOrganizationUnit(
            id: "ARTS_HUM",
            name: "Arts and Humanities",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let artsDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "ENGLS_ART", name: "English Language and Literature", type: .department,
                parentID: "ARTS_HUM", children: nil),
            UCLOrganizationUnit(
                id: "GRKLT_ART", name: "Greek and Latin", type: .department, parentID: "ARTS_HUM",
                children: nil),
            UCLOrganizationUnit(
                id: "HEBRW_ART", name: "Hebrew and Jewish Studies", type: .department,
                parentID: "ARTS_HUM", children: nil),
            UCLOrganizationUnit(
                id: "INFST_ART", name: "Information Studies", type: .department,
                parentID: "ARTS_HUM", children: nil),
            UCLOrganizationUnit(
                id: "PHILO_ART", name: "Philosophy", type: .department, parentID: "ARTS_HUM",
                children: nil),
            UCLOrganizationUnit(
                id: "SLADE_ART", name: "Slade School of Fine Art", type: .school,
                parentID: "ARTS_HUM", children: nil),
            UCLOrganizationUnit(
                id: "SELCS_ART", name: "School of European Languages, Culture and Society",
                type: .school,
                parentID: "ARTS_HUM", children: nil),
            UCLOrganizationUnit(
                id: "SSEES_ART", name: "School of Slavonic and East European Studies",
                type: .school,
                parentID: "ARTS_HUM", children: nil),
            UCLOrganizationUnit(
                id: "UAASC_ART", name: "UCL Arts and Sciences", type: .department,
                parentID: "ARTS_HUM", children: nil),
        ]

        artsFaculty.children = artsDepartments
        allFaculties.append(artsFaculty)

        // Store departments
        for department in artsDepartments {
            organizationMap[department.id] = department
        }

        // 2. Faculty of Brain Sciences
        var brainFaculty = UCLOrganizationUnit(
            id: "BRAIN_SCI",
            name: "Brain Sciences",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let brainDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "PSYAT_BRN", name: "Division of Psychiatry", type: .division,
                parentID: "BRAIN_SCI", children: nil),
            UCLOrganizationUnit(
                id: "PSYLA_BRN", name: "Division of Psychology and Language Sciences",
                type: .division,
                parentID: "BRAIN_SCI", children: nil),
            UCLOrganizationUnit(
                id: "EARIN_BRN", name: "Ear Institute", type: .institute, parentID: "BRAIN_SCI",
                children: nil),
            UCLOrganizationUnit(
                id: "OPHTH_BRN", name: "Institute of Ophthalmology", type: .institute,
                parentID: "BRAIN_SCI", children: nil),
            UCLOrganizationUnit(
                id: "PRION_BRN", name: "Institute of Prion Diseases", type: .institute,
                parentID: "BRAIN_SCI", children: nil),
            UCLOrganizationUnit(
                id: "QSION_BRN", name: "UCL Queen Square Institute of Neurology", type: .institute,
                parentID: "BRAIN_SCI", children: nil),
        ]

        brainFaculty.children = brainDepartments
        allFaculties.append(brainFaculty)

        // Store departments
        for department in brainDepartments {
            organizationMap[department.id] = department
        }

        // 3. Faculty of the Built Environment - The Bartlett
        var builtEnvFaculty = UCLOrganizationUnit(
            id: "BUILT_ENV",
            name: "Built Environment (The Bartlett)",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let builtEnvDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "CASAN_BEN", name: "Centre for Advanced Spatial Analysis", type: .center,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "BSARC_BEN", name: "Bartlett School of Architecture", type: .school,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "BSCPM_BEN", name: "Bartlett School of Sustainable Construction", type: .school,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "BSEER_BEN", name: "Bartlett School of Environment, Energy and Resources",
                type: .school,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "DEVPU_BEN", name: "Development Planning Unit", type: .department,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "BSPLN_BEN", name: "Bartlett School of Planning", type: .school,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "BSIGP_BEN", name: "UCL Institute for Global Prosperity", type: .institute,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "BSIPP_BEN", name: "UCL Institute for Innovation and Public Purpose",
                type: .institute,
                parentID: "BUILT_ENV", children: nil),
            UCLOrganizationUnit(
                id: "URBLB_BEN", name: "UCL Urban Laboratory", type: .department,
                parentID: "BUILT_ENV", children: nil),
        ]

        builtEnvFaculty.children = builtEnvDepartments
        allFaculties.append(builtEnvFaculty)

        // Store departments
        for department in builtEnvDepartments {
            organizationMap[department.id] = department
        }

        // 4. Faculty of Engineering Sciences
        var engFaculty = UCLOrganizationUnit(
            id: "ENG_SCI",
            name: "Engineering Sciences",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let engDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "BENGN_ENG", name: "Biochemical Engineering", type: .department,
                parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "CENGN_ENG", name: "Chemical Engineering", type: .department,
                parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "CIVLG_ENG", name: "Civil, Environmental and Geomatic Engineering",
                type: .department, parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "COMPS_ENG", name: "Computer Science", type: .department, parentID: "ENG_SCI",
                children: nil),
            UCLOrganizationUnit(
                id: "ELECN_ENG", name: "Electronic and Electrical Engineering", type: .department,
                parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "MECHN_ENG", name: "Mechanical Engineering", type: .department,
                parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "MPHBE_ENG", name: "Medical Physics and Biomedical Engineering",
                type: .department,
                parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "STEPP_ENG", name: "Science, Technology, Engineering and Public Policy",
                type: .department,
                parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "SECUR_ENG", name: "Security and Crime Science", type: .department,
                parentID: "ENG_SCI", children: nil),
            UCLOrganizationUnit(
                id: "MANAG_ENG", name: "UCL School of Management", type: .school,
                parentID: "ENG_SCI", children: nil),
        ]

        engFaculty.children = engDepartments
        allFaculties.append(engFaculty)

        // Store departments
        for department in engDepartments {
            organizationMap[department.id] = department
        }

        // 5. Faculty of Laws
        var lawFaculty = UCLOrganizationUnit(
            id: "LAWS",
            name: "Laws",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let lawDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "LAWSD_LAW", name: "Laws", type: .department,
                parentID: "LAWS", children: nil)
        ]

        lawFaculty.children = lawDepartments
        allFaculties.append(lawFaculty)

        // Store departments
        for department in lawDepartments {
            organizationMap[department.id] = department
        }

        // 6. Faculty of Life Sciences
        var lifeFaculty = UCLOrganizationUnit(
            id: "LIFE_SCI",
            name: "Life Sciences",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let lifeDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "BIOSC_LIF", name: "Division of Biosciences", type: .division,
                parentID: "LIFE_SCI", children: nil),
            UCLOrganizationUnit(
                id: "LMCBL_LIF", name: "MRC Laboratory for Molecular Cell Biology",
                type: .department,
                parentID: "LIFE_SCI", children: nil),
            UCLOrganizationUnit(
                id: "PHMCY_LIF", name: "UCL School of Pharmacy", type: .school,
                parentID: "LIFE_SCI", children: nil),
            UCLOrganizationUnit(
                id: "GATSB_LIF", name: "Gatsby Computational Neuroscience Unit", type: .department,
                parentID: "LIFE_SCI", children: nil),
            UCLOrganizationUnit(
                id: "SWNCB_LIF",
                name: "Sainsbury Wellcome Centre for Neural Circuits and Behaviour", type: .center,
                parentID: "LIFE_SCI", children: nil),
        ]

        lifeFaculty.children = lifeDepartments
        allFaculties.append(lifeFaculty)

        // Store departments
        for department in lifeDepartments {
            organizationMap[department.id] = department
        }

        // 7. Faculty of Mathematical and Physical Sciences
        var mapsFaculty = UCLOrganizationUnit(
            id: "MATHS_PHYS",
            name: "Mathematical and Physical Sciences",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let mapsDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "CHEMS_MAP", name: "Chemistry", type: .department,
                parentID: "MATHS_PHYS", children: nil),
            UCLOrganizationUnit(
                id: "EARTH_MAP", name: "Earth Sciences", type: .department,
                parentID: "MATHS_PHYS", children: nil),
            UCLOrganizationUnit(
                id: "MATHS_MAP", name: "Mathematics", type: .department,
                parentID: "MATHS_PHYS", children: nil),
            UCLOrganizationUnit(
                id: "PHYSA_MAP", name: "Physics and Astronomy", type: .department,
                parentID: "MATHS_PHYS", children: nil),
            UCLOrganizationUnit(
                id: "RADRE_MAP", name: "Institute for Risk and Disaster Reduction",
                type: .institute,
                parentID: "MATHS_PHYS", children: nil),
            UCLOrganizationUnit(
                id: "SCITS_MAP", name: "Science and Technology Studies", type: .department,
                parentID: "MATHS_PHYS", children: nil),
            UCLOrganizationUnit(
                id: "SPACE_MAP", name: "Space and Climate Physics", type: .department,
                parentID: "MATHS_PHYS", children: nil),
            UCLOrganizationUnit(
                id: "STATS_MAP", name: "Statistical Science", type: .department,
                parentID: "MATHS_PHYS", children: nil),
        ]

        mapsFaculty.children = mapsDepartments
        allFaculties.append(mapsFaculty)

        // Store departments
        for department in mapsDepartments {
            organizationMap[department.id] = department
        }

        // 8. Faculty of Medical Sciences
        var medFaculty = UCLOrganizationUnit(
            id: "MED_SCI",
            name: "Medical Sciences",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let medDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "CANCR_MDS", name: "Cancer Institute", type: .institute,
                parentID: "MED_SCI", children: nil),
            UCLOrganizationUnit(
                id: "EASTD_MDS", name: "Eastman Dental Institute", type: .institute,
                parentID: "MED_SCI", children: nil),
            UCLOrganizationUnit(
                id: "INFEC_MDS", name: "Division of Infection and Immunity", type: .division,
                parentID: "MED_SCI", children: nil),
            UCLOrganizationUnit(
                id: "MEDCN_MDS", name: "Division of Medicine", type: .division,
                parentID: "MED_SCI", children: nil),
            UCLOrganizationUnit(
                id: "SURGS_MDS", name: "Division of Surgery and Interventional Science",
                type: .division,
                parentID: "MED_SCI", children: nil),
            UCLOrganizationUnit(
                id: "UCLMS_MDS", name: "UCL Medical School", type: .school,
                parentID: "MED_SCI", children: nil),
        ]

        medFaculty.children = medDepartments
        allFaculties.append(medFaculty)

        // Store departments
        for department in medDepartments {
            organizationMap[department.id] = department
        }

        // 9. Faculty of Population Health Sciences
        var popHealthFaculty = UCLOrganizationUnit(
            id: "POP_HEALTH",
            name: "Population Health Sciences",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let popHealthDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "GBSFH_PHS", name: "Global Business School for Health", type: .school,
                parentID: "POP_HEALTH", children: nil),
            UCLOrganizationUnit(
                id: "CARDI_PHS", name: "Institute of Cardiovascular Science", type: .institute,
                parentID: "POP_HEALTH", children: nil),
            UCLOrganizationUnit(
                id: "IOCTM_PHS", name: "Institute of Clinical Trials and Methodology",
                type: .institute,
                parentID: "POP_HEALTH", children: nil),
            UCLOrganizationUnit(
                id: "EPIHC_PHS", name: "Institute of Epidemiology and Health Care",
                type: .institute,
                parentID: "POP_HEALTH", children: nil),
            UCLOrganizationUnit(
                id: "GLOBH_PHS", name: "Institute for Global Health", type: .institute,
                parentID: "POP_HEALTH", children: nil),
            UCLOrganizationUnit(
                id: "HEINF_PHS", name: "Institute of Health Informatics", type: .institute,
                parentID: "POP_HEALTH", children: nil),
            UCLOrganizationUnit(
                id: "GOSCH_PHS", name: "UCL Great Ormond Street Institute of Child Health",
                type: .institute,
                parentID: "POP_HEALTH", children: nil),
            UCLOrganizationUnit(
                id: "EGAWH_PHS",
                name: "UCL Elizabeth Garrett Anderson Institute for Women's Health",
                type: .institute,
                parentID: "POP_HEALTH", children: nil),
        ]

        popHealthFaculty.children = popHealthDepartments
        allFaculties.append(popHealthFaculty)

        // Store departments
        for department in popHealthDepartments {
            organizationMap[department.id] = department
        }

        // 10. Faculty of Social and Historical Sciences
        var socHistFaculty = UCLOrganizationUnit(
            id: "SOC_HIST_SCI",
            name: "Social and Historical Sciences",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let socHistDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "ANTHR_SHS", name: "Anthropology", type: .department,
                parentID: "SOC_HIST_SCI", children: nil),
            UCLOrganizationUnit(
                id: "ARCLG_SHS", name: "Institute of Archaeology", type: .institute,
                parentID: "SOC_HIST_SCI", children: nil),
            UCLOrganizationUnit(
                id: "ECONS_SHS", name: "Economics", type: .department,
                parentID: "SOC_HIST_SCI", children: nil),
            UCLOrganizationUnit(
                id: "GEOGR_SHS", name: "Geography", type: .department,
                parentID: "SOC_HIST_SCI", children: nil),
            UCLOrganizationUnit(
                id: "HISTR_SHS", name: "History", type: .department,
                parentID: "SOC_HIST_SCI", children: nil),
            UCLOrganizationUnit(
                id: "HARTD_SHS", name: "History of Art", type: .department,
                parentID: "SOC_HIST_SCI", children: nil),
            UCLOrganizationUnit(
                id: "POLSC_SHS", name: "Political Science", type: .department,
                parentID: "SOC_HIST_SCI", children: nil),
            UCLOrganizationUnit(
                id: "AMERC_SHS", name: "Institute of the Americas", type: .institute,
                parentID: "SOC_HIST_SCI", children: nil),
        ]

        socHistFaculty.children = socHistDepartments
        allFaculties.append(socHistFaculty)

        // Store departments
        for department in socHistDepartments {
            organizationMap[department.id] = department
        }

        // 11. UCL Institute of Education
        var ioeFaculty = UCLOrganizationUnit(
            id: "IOE",
            name: "UCL Institute of Education",
            type: .faculty,
            parentID: "UCL",
            children: []
        )

        let ioeDepartments: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "CULCM_IOE", name: "Culture, Communication and Media", type: .department,
                parentID: "IOE", children: nil),
            UCLOrganizationUnit(
                id: "CURPA_IOE", name: "Curriculum, Pedagogy and Assessment", type: .department,
                parentID: "IOE", children: nil),
            UCLOrganizationUnit(
                id: "EDPAS_IOE", name: "Education, Practice and Society", type: .department,
                parentID: "IOE", children: nil),
            UCLOrganizationUnit(
                id: "LEARN_IOE", name: "Learning and Leadership", type: .department,
                parentID: "IOE", children: nil),
            UCLOrganizationUnit(
                id: "PSYHD_IOE", name: "Psychology and Human Development", type: .department,
                parentID: "IOE", children: nil),
            UCLOrganizationUnit(
                id: "SOCRI_IOE", name: "Social Research Institute", type: .department,
                parentID: "IOE", children: nil),
            UCLOrganizationUnit(
                id: "LANIE_IOE", name: "Centre for Languages and International Education",
                type: .center,
                parentID: "IOE", children: nil),
        ]

        ioeFaculty.children = ioeDepartments
        allFaculties.append(ioeFaculty)

        // Store departments
        for department in ioeDepartments {
            organizationMap[department.id] = department
        }

        // Add administrative and support departments
        var adminDivision = UCLOrganizationUnit(
            id: "ADMIN_DIV",
            name: "Administration and Support Services",
            type: .administrative,
            parentID: "UCL",
            children: []
        )

        // President and Provost's Office
        var presidentsOffice = UCLOrganizationUnit(
            id: "PRES_OFF",
            name: "Office of the President and Provost",
            type: .administrative,
            parentID: "ADMIN_DIV",
            children: []
        )

        let presidentOfficeUnits: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "PROVO_ADM", name: "Provost & President's Office", type: .administrative,
                parentID: "PRES_OFF", children: nil),
            UCLOrganizationUnit(
                id: "VP_FAC", name: "Vice-Provost (Faculties)", type: .administrative,
                parentID: "PRES_OFF", children: nil),
            UCLOrganizationUnit(
                id: "VP_RES", name: "Vice-Provost (Research, Innovation and Global Engagement)",
                type: .administrative, parentID: "PRES_OFF", children: nil),
            UCLOrganizationUnit(
                id: "VP_EDU", name: "Vice-Provost (Education and Student Experience)",
                type: .administrative, parentID: "PRES_OFF", children: nil),
            UCLOrganizationUnit(
                id: "VP_HEAL", name: "Vice-Provost (Health)", type: .administrative,
                parentID: "PRES_OFF", children: nil),
            UCLOrganizationUnit(
                id: "VP_ADV", name: "Vice-President (Advancement)", type: .administrative,
                parentID: "PRES_OFF", children: nil),
        ]

        presidentsOffice.children = presidentOfficeUnits

        // Information Services Division
        var isdDivision = UCLOrganizationUnit(
            id: "ISD_DIV",
            name: "Information Services Division",
            type: .administrative,
            parentID: "ADMIN_DIV",
            children: []
        )

        let isdUnits: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "ISDDV_ADM", name: "Information Services Division", type: .administrative,
                parentID: "ISD_DIV", children: nil),
            UCLOrganizationUnit(
                id: "ISDAS_ADM", name: "Application Services, ISD", type: .administrative,
                parentID: "ISD_DIV", children: nil),
            UCLOrganizationUnit(
                id: "ISDLT_ADM", name: "Learning Teaching & Media Services, ISD",
                type: .administrative,
                parentID: "ISD_DIV", children: nil),
            UCLOrganizationUnit(
                id: "ISDRS_ADM", name: "Research IT Services, ISD", type: .administrative,
                parentID: "ISD_DIV", children: nil),
        ]

        isdDivision.children = isdUnits

        // Estates and Facilities Division
        var estatesDivision = UCLOrganizationUnit(
            id: "ESTATES_DIV",
            name: "Estates and Facilities Division",
            type: .administrative,
            parentID: "ADMIN_DIV",
            children: []
        )

        let estatesUnits: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "ESTDV_ADM", name: "Estates and Facilities Division", type: .administrative,
                parentID: "ESTATES_DIV", children: nil),
            UCLOrganizationUnit(
                id: "ESTAD_ADM", name: "Estates Administration, EFD", type: .administrative,
                parentID: "ESTATES_DIV", children: nil),
            UCLOrganizationUnit(
                id: "ESTPM_ADM", name: "Property Maintenance and FM, EFD", type: .administrative,
                parentID: "ESTATES_DIV", children: nil),
            UCLOrganizationUnit(
                id: "ESTSA_ADM", name: "Security and Access Systems, EFD", type: .administrative,
                parentID: "ESTATES_DIV", children: nil),
        ]

        estatesDivision.children = estatesUnits

        // Other Support Services
        var supportServices = UCLOrganizationUnit(
            id: "SUPPORT_SERV",
            name: "Other Support Services",
            type: .administrative,
            parentID: "ADMIN_DIV",
            children: []
        )

        let supportUnits: [UCLOrganizationUnit] = [
            UCLOrganizationUnit(
                id: "LIBRY_ADM", name: "Library Services", type: .administrative,
                parentID: "SUPPORT_SERV", children: nil),
            UCLOrganizationUnit(
                id: "ACADS_ADM", name: "Academic Services", type: .administrative,
                parentID: "SUPPORT_SERV", children: nil),
            UCLOrganizationUnit(
                id: "HRSDV_ADM", name: "Human Resources Division", type: .administrative,
                parentID: "SUPPORT_SERV", children: nil),
            UCLOrganizationUnit(
                id: "FINDV_ADM", name: "Finance Division", type: .administrative,
                parentID: "SUPPORT_SERV", children: nil),
            UCLOrganizationUnit(
                id: "STUNI_ADM", name: "UCL Students' Union", type: .administrative,
                parentID: "SUPPORT_SERV", children: nil),
            UCLOrganizationUnit(
                id: "MUSCO_ADM", name: "Museums and Collections", type: .administrative,
                parentID: "SUPPORT_SERV", children: nil),
        ]

        supportServices.children = supportUnits

        // Combine all administrative departments
        let adminDivisions = [presidentsOffice, isdDivision, estatesDivision, supportServices]
        adminDivision.children = adminDivisions

        // Add all administrative units to organizationMap
        organizationMap["ADMIN_DIV"] = adminDivision

        for division in adminDivisions {
            organizationMap[division.id] = division
            if let children = division.children {
                for unit in children {
                    organizationMap[unit.id] = unit
                }
            }
        }

        // Store all faculties
        for faculty in allFaculties {
            organizationMap[faculty.id] = faculty
        }

        // Add faculties and administrative departments as university's child units
        var updatedUniversity = university
        updatedUniversity.children = allFaculties + [adminDivision]

        // Update attributes
        self.organizationTree = updatedUniversity
        self.organizationMap["UCL"] = updatedUniversity
        self.faculties = allFaculties
    }

    /// Find organization unit by ID
    func getUnit(byID id: String) -> UCLOrganizationUnit? {
        return organizationMap[id]
    }

    /// Find organization unit by name
    func getUnit(byName name: String) -> UCLOrganizationUnit? {
        return organizationMap.values.first { unit in
            unit.name.lowercased() == name.lowercased()
                || unit.name.lowercased().contains(name.lowercased())
        }
    }

    /// Search organization units by keyword
    func searchUnits(query: String) -> [UCLOrganizationUnit] {
        guard !query.isEmpty else { return [] }

        let lowercasedQuery = query.lowercased()
        return organizationMap.values.filter { unit in
            unit.name.lowercased().contains(lowercasedQuery)
                || unit.id.lowercased().contains(lowercasedQuery)
        }
    }

    /// Get unit's parent unit
    func getParent(for unitID: String) -> UCLOrganizationUnit? {
        guard let unit = getUnit(byID: unitID),
            let parentID = unit.parentID
        else {
            return nil
        }

        return getUnit(byID: parentID)
    }

    /// Get unit's child units
    func getChildren(for unitID: String) -> [UCLOrganizationUnit] {
        guard let unit = getUnit(byID: unitID),
            let children = unit.children
        else {
            return []
        }

        return children
    }

    /// Get unit's sibling units (same level units)
    func getSiblings(for unitID: String) -> [UCLOrganizationUnit] {
        guard let unit = getUnit(byID: unitID),
            let parentID = unit.parentID,
            let parent = getUnit(byID: parentID),
            let siblings = parent.children
        else {
            return []
        }

        return siblings.filter { $0.id != unitID }
    }
}
