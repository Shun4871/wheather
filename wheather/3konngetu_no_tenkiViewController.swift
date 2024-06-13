import UIKit
import UserNotifications
import CoreLocation
import WeatherKit

final class konngetu_no_tenkiViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CLLocationManagerDelegate {

    private let dateManager = MonthDateManager()
    private let weeks = ["日","月", "火", "水", "木", "金", "土"]
    private let itemSize: CGFloat = (UIScreen.main.bounds.width - 40) / 7 // 間隔を考慮して調整
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    private let weatherService = WeatherService()

    private lazy var calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0 // 水平方向の間隔を0に設定
        layout.itemSize = CGSize(width: itemSize, height: 50)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.layer.cornerRadius = 12 // 角を丸くする
        collectionView.layer.masksToBounds = true // サブビューに角の設定を適用
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24)
        label.textAlignment = .center
        label.text = dateManager.monthString
        label.backgroundColor = .white
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.borderWidth = 1
        return label
    }()

    private lazy var monthLabelContainer: UIView = {
        let paddingView = UIView()
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        paddingView.backgroundColor = .white
        paddingView.layer.cornerRadius = 10
        paddingView.layer.masksToBounds = true
        paddingView.layer.borderColor = UIColor.lightGray.cgColor
        paddingView.layer.borderWidth = 1
        paddingView.addSubview(monthLabel)

        NSLayoutConstraint.activate([
            monthLabel.leadingAnchor.constraint(equalTo: paddingView.leadingAnchor, constant: 100),
            monthLabel.trailingAnchor.constraint(equalTo: paddingView.trailingAnchor, constant: -100),
            monthLabel.topAnchor.constraint(equalTo: paddingView.topAnchor, constant: 40),
            monthLabel.bottomAnchor.constraint(equalTo: paddingView.bottomAnchor, constant: -40)
        ])

        return paddingView
    }()




    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBackgroundColor()
        setupLocationManager()
        setupViews()
        adjustCalendarPosition()
    }

    func setupBackgroundColor() {
        let backgroundColor = UIColor(red: 115/255.0, green: 203/255.0, blue: 249/255.0, alpha: 1.0)
        view.backgroundColor = backgroundColor
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func setupViews() {
        view.addSubview(monthLabelContainer)
        view.addSubview(calendarCollectionView)

        monthLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        calendarCollectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            monthLabelContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            monthLabelContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            calendarCollectionView.topAnchor.constraint(equalTo: monthLabelContainer.bottomAnchor, constant: 16),
            calendarCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            calendarCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            calendarCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150)
        ])
    }


    func adjustCalendarPosition() {
        calendarCollectionView.frame.size.width = view.bounds.width
        calendarCollectionView.frame.size.height = 500
    }

    @objc private func actionNext() {
        dateManager.nextMonth()
        calendarCollectionView.reloadData()
        monthLabel.text = dateManager.monthString
    }

    @objc private func actionBack() {
        dateManager.prevMonth()
        calendarCollectionView.reloadData()
        monthLabel.text = dateManager.monthString
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? weeks.count : dateManager.days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarCell
        if indexPath.section == 0 {
            let day = weeks[indexPath.row]
            cell.configure(model: CalendarCell.Model(text: day, textColor: .black))
        } else {
            let date = dateManager.days[indexPath.row]
            let isReserved = dateManager.isReserved(for: date)
            let reservationTime = dateManager.getReservationTime(for: date)
            cell.updateAppearanceForReservation(isReserved: isReserved)
            cell.configure(model: CalendarCell.Model(date: date, time: reservationTime))
            cell.setSelectionIndicatorSize(size: 32)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        }
        let date = dateManager.days[indexPath.row]
        let originalReservationStatus = dateManager.isReserved(for: date)
        dateManager.toggleReservation(for: date)
        collectionView.reloadItems(at: [indexPath])
        presentTimeSelectionDialog(for: date, originalReservationStatus: originalReservationStatus)
    }

    func presentTimeSelectionDialog(for date: Date, originalReservationStatus: Bool) {
        let alertController = UIAlertController(title: "時間を選択", message: nil, preferredStyle: .alert)
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.locale = Locale(identifier: "ja_JP") // 日本語設定
        datePicker.preferredDatePickerStyle = .wheels

        alertController.view.addSubview(datePicker)

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 50),
            datePicker.centerXAnchor.constraint(equalTo: alertController.view.centerXAnchor),
            datePicker.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 10),
            datePicker.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: -10)
        ])

        alertController.addAction(UIAlertAction(title: "選択", style: .default, handler: { _ in
            let selectedTime = datePicker.date
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: selectedTime)
            self.dateManager.setReservationTime(for: date, time: timeString)
            Task {
                await self.scheduleNotification(for: date, time: timeString)
                if let indexPath = self.dateManager.indexPath(for: date) {
                    self.calendarCollectionView.reloadItems(at: [indexPath])
                }
            }
        }))

        alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { _ in
            // キャンセルを選択した場合、予約状況を元に戻す
            self.dateManager.setReservation(for: date, reserved: originalReservationStatus)
            if let indexPath = self.dateManager.indexPath(for: date) {
                self.calendarCollectionView.reloadItems(at: [indexPath])
            }
        }))

        // 高さを調整
        let height: NSLayoutConstraint = NSLayoutConstraint(item: alertController.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        alertController.view.addConstraint(height)

        present(alertController, animated: true)
    }

    func scheduleNotification(for date: Date, time: String) async {
        guard let location = userLocation else {
            print("User location not available")
            return
        }

        do {
            let result = try await weatherService.weather(for: location)
            let currentWeather = result.currentWeather

            let content = UNMutableNotificationContent()
            content.sound = UNNotificationSound.default

            if currentWeather.condition == .rain {
                content.title = "予約通知"
                content.body = "傘持ちましたか？雨ってるよ"
            } else if currentWeather.condition == .heavyRain {
                content.title = "予約通知"
                content.body = "傘持ちましたか？大雨降ってるよ"
            } else if currentWeather.condition == .thunderstorms {
                content.title = "予約通知"
                content.body = "傘持ちましたか？今雷だよ"
            } else {
                content.title = "お知らせ"
                content.body = "雨降らなかったよ"
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            guard let triggerDate = formatter.date(from: time) else { return }

            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: triggerDate)
            let minute = calendar.component(.minute, from: triggerDate)

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            do {
                try await UNUserNotificationCenter.current().add(request)
                print("通知がスケジュールされました: \(date) \(time)")
            } catch {
                print("通知のスケジューリングに失敗しました: \(error)")
            }
        } catch {
            print("天気情報の取得に失敗しました: \(error)")
        }
    }

    // CLLocationManagerDelegate メソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        userLocation = location
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error)")
    }
}
