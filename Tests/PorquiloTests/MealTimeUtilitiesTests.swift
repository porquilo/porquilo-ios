import XCTest
@testable import Porquilo

final class MealTimeUtilitiesTests: XCTestCase {
    private func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 25
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    func testMealSlotInference() {
        XCTAssertEqual(MealSlot.inferred(from: date(hour: 7, minute: 0)), .breakfast)
        XCTAssertEqual(MealSlot.inferred(from: date(hour: 12, minute: 0)), .lunch)
        XCTAssertEqual(MealSlot.inferred(from: date(hour: 18, minute: 0)), .dinner)
        XCTAssertEqual(MealSlot.inferred(from: date(hour: 22, minute: 0)), .snack)
    }

    func testRoundedToNearest15MinutesRoundsDown() {
        let rounded = date(hour: 7, minute: 7).roundedToNearest15Minutes()
        XCTAssertEqual(Calendar.current.component(.minute, from: rounded), 0)
    }

    func testRoundedToNearest15MinutesRoundsUp() {
        let rounded = date(hour: 7, minute: 8).roundedToNearest15Minutes()
        XCTAssertEqual(Calendar.current.component(.minute, from: rounded), 15)
    }

    func testRoundedToNearest15MinutesZeroesSeconds() {
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date(hour: 7, minute: 30))
        components.second = 45
        let withSeconds = Calendar.current.date(from: components)!
        let rounded = withSeconds.roundedToNearest15Minutes()
        XCTAssertEqual(Calendar.current.component(.second, from: rounded), 0)
    }
}
