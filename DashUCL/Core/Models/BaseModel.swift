/*
 * Base protocol that defines common requirements for all model objects.
 * Ensures consistent implementation of Codable and Identifiable protocols.
 * Establishes standardized identifier and update timestamp properties.
 * Provides foundation for type-safe data handling throughout the app.
 */

import Foundation

protocol BaseModel: Codable, Identifiable {
    var id: String { get }
    var lastUpdated: Date { get }
}
