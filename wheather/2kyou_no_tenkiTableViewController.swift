import UIKit
import UserNotifications
import CoreLocation
import WeatherKit

class KyouNoTenkiTableViewController: UITableViewController, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    let weatherService = WeatherService()
    var notifications: [WeatherNotification] = []
    var selectedTime: Date?

    var timePicker: UIPickerView!
    var confirmButton: UIButton!
    var buttonTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundColor()
        setupLocationManager()
        setupNotification()
        setupTimePickerAndButton()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
    }

    func setupBackgroundColor() {
        let backgroundColor = UIColor(red: 115/255.0, green: 203/255.0, blue: 249/255.0, alpha: 1.0)
        view.backgroundColor = backgroundColor
    }

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func setupNotification() {
        // 初期通知設定（必要に応じて）
    }

    func setupTimePickerAndButton() {
        timePicker = UIPickerView()
        timePicker.delegate = self
        timePicker.dataSource = self
        timePicker.backgroundColor = .white

        confirmButton = UIButton(type: .system)
        confirmButton.setTitle("予約を確定", for: .normal)
        confirmButton.backgroundColor = UIColor(red: 32/255.0, green: 133/255.0, blue: 199/255.0, alpha: 1.0)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 20) // フォントサイズを調整
        confirmButton.layer.cornerRadius = 10
        confirmButton.layer.masksToBounds = true
        confirmButton.addTarget(self, action: #selector(donePickingTime), for: .touchUpInside)

        let buttonStackView = UIStackView(arrangedSubviews: [confirmButton])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 8

        let timePickerStackView = UIStackView(arrangedSubviews: [timePicker])
        timePickerStackView.axis = .vertical
        timePickerStackView.spacing = 8

        let stackView = UIStackView(arrangedSubviews: [buttonStackView, timePickerStackView])
        stackView.axis = .vertical
        stackView.spacing = 16 // timePickerとcellの間の余白を設定

        let headerView = UIView()
        headerView.addSubview(stackView)
        headerView.frame.size.height = 300 // ボタンとピッカーの高さと余白を考慮

        stackView.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        timePicker.translatesAutoresizingMaskIntoConstraints = false

        buttonTopConstraint = confirmButton.topAnchor.constraint(equalTo: stackView.topAnchor, constant: 8)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),

            timePicker.heightAnchor.constraint(equalToConstant: 216),
            buttonTopConstraint
        ])

        tableView.tableHeaderView = headerView
    }

    @objc func donePickingTime() {
        view.endEditing(true)
        if let selectedTime = selectedTime {
            let newNotification = WeatherNotification(date: selectedTime, isRainExpected: true, isNotificationEnabled: true)
            notifications.append(newNotification)
            checkWeatherAndScheduleNotification(for: newNotification, at: selectedTime)
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let notification = notifications[indexPath.row]
        cell.textLabel?.text = notification.date.string(format: "HH:mm")
        cell.textLabel?.font = UIFont.systemFont(ofSize: 28) // フォントサイズを大きく
        cell.textLabel?.textAlignment = .center // 中央揃え

        let switchView = UISwitch(frame: .zero)
        switchView.setOn(notification.isNotificationEnabled, animated: true)
        switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            cancelNotification(for: notifications[indexPath.row])
            notifications.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "削除") { (action, indexPath) in
            self.cancelNotification(for: self.notifications[indexPath.row])
            self.notifications.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        return [deleteAction]
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 // セルの高さを調整
    }

    @objc func switchChanged(_ sender: UISwitch) {
        if let cell = sender.superview as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            let notification = notifications[indexPath.row]
            if sender.isOn {
                checkWeatherAndScheduleNotification(for: notification, at: notification.date)
                notifications[indexPath.row].isNotificationEnabled = true
            } else {
                cancelNotification(for: notification)
                notifications[indexPath.row].isNotificationEnabled = false
            }
        }
    }

    func checkWeatherAndScheduleNotification(for notification: WeatherNotification, at time: Date) {
        guard let location = userLocation else {
            print("User location not available")
            return
        }

        Task {
            do {
                let result = try await weatherService.weather(for: location)
                let hourlyForecast = result.hourlyForecast

                let calendar = Calendar.current
                let fiveHoursAfter = calendar.date(byAdding: .hour, value: 5, to: time)!

                var willRain = false

                for hourWeather in hourlyForecast {
                    let forecastTime = hourWeather.date
                    if forecastTime >= time && forecastTime <= fiveHoursAfter {
                        if hourWeather.condition == .rain || hourWeather.condition == .heavyRain || hourWeather.condition == .thunderstorms {
                            willRain = true
                            break
                        }
                    }
                }

                if willRain {
                    scheduleNotification(for: notification, at: time, message: "雨が降る予定です。傘を持って行きましょう！")
                } else {
                    scheduleNotification(for: notification, at: time, message: "雨が降る予定はありません。傘は不要です！")
                }
            } catch {
                print("天気情報の取得に失敗しました: \(error)")
            }
        }
    }

    func scheduleNotification(for notification: WeatherNotification, at time: Date, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "天気の通知"
        content.body = message
        content.sound = UNNotificationSound.default

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("通知のスケジューリングに失敗しました: \(error)")
            } else {
                print("通知がスケジュールされました: \(time)")
            }
        }
    }

    func cancelNotification(for notification: WeatherNotification) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notification.date.string(format: "YYYY-MM-dd-HH-mm")])
    }

    func cancelNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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

    // UIPickerView Data Source and Delegate Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24 // 時間を表示する列は24行（0〜23）
        } else {
            return 60 // 分を表示する列は60行（0〜59）
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(format: "%02d", row)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hour = pickerView.selectedRow(inComponent: 0)
        let minute = pickerView.selectedRow(inComponent: 1)
        selectedTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
    }
}

// WeatherNotification データモデルの定義
struct WeatherNotification {
    var date: Date
    var isRainExpected: Bool
    var isNotificationEnabled: Bool
}
