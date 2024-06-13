import Foundation

final class MonthDateManager {
    private var reservations: [Date: Bool] = [:]
    private var reservationTimes: [Date: String] = [:] // 予約時間を管理するプロパティ
    private var weekdayReservationTimes: [Int: String] = [:] // 曜日ごとの予約時間を管理するプロパティ
    private let calendar = Calendar.current
    private (set) var days: [Date] = []
    private var firstDate: Date! {
        didSet {
           days = createDaysForMonth()
        }
    }

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

    func setReservationTimeForWeekday(_ weekday: Int, time: String) {
        weekdayReservationTimes[weekday] = time
        for date in days where Calendar.current.component(.weekday, from: date) == weekday + 1 {
            setReservationTime(for: date, time: time)
        }
    }

    func getReservationTimeForWeekday(_ weekday: Int) -> String? {
        return weekdayReservationTimes[weekday]
    }

    func indexPath(for date: Date) -> IndexPath? {
        guard let index = days.firstIndex(of: date) else { return nil }
        return IndexPath(item: index, section: 1)
    }

    func setReservation(for date: Date, reserved: Bool) {
        reservations[date] = reserved
    }
}
