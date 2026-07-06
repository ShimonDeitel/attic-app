import Foundation
import SwiftData

/// One scanned/saved object in the user's attic inventory.
@Model
final class CollectionItem {
    var name: String
    var era: String
    var maker: String
    var materials: String
    var valueLow: Double
    var valueHigh: Double
    /// Model confidence in the identification, 0...1.
    var confidence: Double
    /// The eBay-friendly search term produced by the vision model.
    var searchTerm: String
    var notes: String
    /// Room / box grouping, free text for now.
    var room: String
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date
    /// Flag for high-value hits worth a professional second look.
    var worthSecondLook: Bool

    init(
        name: String,
        era: String = "",
        maker: String = "",
        materials: String = "",
        valueLow: Double = 0,
        valueHigh: Double = 0,
        confidence: Double = 0,
        searchTerm: String = "",
        notes: String = "",
        room: String = "",
        photoData: Data? = nil,
        createdAt: Date = .now,
        worthSecondLook: Bool = false
    ) {
        self.name = name
        self.era = era
        self.maker = maker
        self.materials = materials
        self.valueLow = valueLow
        self.valueHigh = valueHigh
        self.confidence = confidence
        self.searchTerm = searchTerm
        self.notes = notes
        self.room = room
        self.photoData = photoData
        self.createdAt = createdAt
        self.worthSecondLook = worthSecondLook
    }

    convenience init(result: ScanResult, photoData: Data?) {
        self.init(
            name: result.name,
            era: result.era,
            maker: result.maker,
            materials: result.materials,
            valueLow: result.valueLow,
            valueHigh: result.valueHigh,
            confidence: result.confidence,
            searchTerm: result.searchTerm,
            photoData: photoData,
            worthSecondLook: result.valueHigh >= 200 && result.confidence >= 0.5
        )
    }

    /// One-tap link to real eBay SOLD listings for the identified term.
    var ebaySoldListingsURL: URL? {
        var components = URLComponents(string: "https://www.ebay.com/sch/i.html")
        components?.queryItems = [
            URLQueryItem(name: "_nkw", value: searchTerm.isEmpty ? name : searchTerm),
            URLQueryItem(name: "LH_Sold", value: "1"),
            URLQueryItem(name: "LH_Complete", value: "1"),
        ]
        return components?.url
    }
}
