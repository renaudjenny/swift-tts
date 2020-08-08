import XCTest
@testable import SwiftTTSCombine

final class SwiftTTSCombineTests: XCTestCase {
    func testExample() {
        let engine = Engine()
        engine.speak(string: "Hello World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
