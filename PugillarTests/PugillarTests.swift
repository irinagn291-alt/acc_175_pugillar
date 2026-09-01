import XCTest
@testable import Pugillar

final class PugillarTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PugillarApp.self), "PugillarApp")
    }
}
