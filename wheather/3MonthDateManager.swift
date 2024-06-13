import Foundation

final class MonthDateManager {
    private var reservations: [Date: Bool] = [:]
    private var reservationTimes: [Date: String] = [:] // 予約時間を管理するプロパティ
    private var weekdayReservations: [String: Bool] = [:] // 曜日の予約状況を管理するプロパティ
    private var weekdayReservationTimes: [String: String] = [:] // 曜日の予約時間を管理するプロパティ
    private let calendar = Calendar.current
    private (set) var days: [Date] = []
    private var firstDate: Date! {
        didSet {
           days = createDaysForMonth()
        }
    }

    // 曜日の配列
    private let weeks = ["日", "月", "火", "水", "木", "金", "土"]

    var monthString: String {
        return firstDate.string(format: "YYYY/MM")
    }

    init() {
        var component = calendar.dateComponents([.year, .month], from: Date())
        component.day = 1
        firstDate = calendar.date(from: component)
        days = createDaysForMonth()
    }

    func createDaysForMonth() -> [Date] {
        // 月の初日の曜日
        let dayOfTheWeek = calendar.component(.weekday, from: firstDate) - 1
        // 月の日数
        let numberOfWeeks = calendar.range(of: .weekOfMonth, in: .month, for: firstDate)!.count
        // その月に表示する日数
        let numberOfItems = numberOfWeeks * 7

        return (0..<numberOfItems).map { i in
            var dateComponents = DateComponents()
            dateComponents.day = i - dayOfTheWeek
            return calendar.date(byAdding: dateComponents, to: firstDate)!
        }
    }

    func nextMonth() {
        firstDate = calendar.date(byAdding: .month, value: 1, to: firstDate)
    }

    func prevMonth() {
        firstDate = calendar.date(byAdding: .month, value: -1, to: firstDate)
    }

    func toggleReservation(for date: Date) {
        reservations[date] = !(reservations[date] ?? false)
    }

    func isReserved(for date: Date) -> Bool {
        return reservations[date] ?? false
    }

    func setReservationTime(for date: Date, time: String) {
        reservationTimes[date] = time
    }

    func getReservationTime(for date: Date) -> String? {
        return reservationTimes[date]
    }

    func setReservationTime(for weekday: String, time: String) {
        weekdayReservationTimes[weekday] = time
    }

    func getReservationTime(for weekday: String) -> String? {
        return weekdayReservationTimes[weekday]
    }

    func setWeekdayReservation(for weekday: String, reserved: Bool) {
        weekdayReservations[weekday] = reserved
    }

    func isWeekdayReserved(for weekday: String) -> Bool {
        return weekdayReservations[weekday] ?? false
    }

    func getDates(for weekday: String) -> [Date] {
        return days.filter { date in
            let components = calendar.dateComponents([.weekday], from: date)
            return weeks[components.weekday! - 1] == weekday
        }
    }

    func indexPath(for date: Date) -> IndexPath? {
        guard let index = days.firstIndex(of: date) else { return nil }
        return IndexPath(item: index, section: 1)
    }

    func setReservation(for date: Date, reserved: Bool) {
        reservations[date] = reserved
    }
}
