import Foundation

extension Date {
    func roundedToNearest15Minutes() -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)
        let remainder = minute % 15
        let delta = remainder < 8 ? -remainder : (15 - remainder)
        let shifted = calendar.date(byAdding: .minute, value: delta, to: self) ?? self
        let zeroedSeconds = calendar.date(
            bySettingHour: calendar.component(.hour, from: shifted),
            minute: calendar.component(.minute, from: shifted),
            second: 0,
            of: shifted
        )
        return zeroedSeconds ?? shifted
    }
}
