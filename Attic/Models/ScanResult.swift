import Foundation

/// DTO decoded from the vision model's structured JSON response.
/// Wire format uses snake_case for the value keys (see AtticAPI system prompt).
struct ScanResult: Codable, Equatable {
    var name: String
    var era: String
    var maker: String
    var materials: String
    var valueLow: Double
    var valueHigh: Double
    /// 0...1
    var confidence: Double
    var searchTerm: String

    enum CodingKeys: String, CodingKey {
        case name
        case era
        case maker
        case materials
        case valueLow = "value_low"
        case valueHigh = "value_high"
        case confidence
        case searchTerm = "search_term"
    }
}
