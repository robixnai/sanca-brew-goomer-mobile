import Foundation
import XCTest

enum Fixture {
    static func data(_ name: String) throws -> Data {
        let bundle = Bundle(for: MenuDecodingTests.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw XCTSkip("Fixture \(name).json not found")
        }
        return try Data(contentsOf: url)
    }
}
