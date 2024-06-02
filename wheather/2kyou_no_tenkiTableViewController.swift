import UIKit
import UserNotifications
import CoreLocation
import WeatherKit

class kyou_no_tenkiTableViewController: UITableViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    let weatherService = WeatherService()
    var notification: WeatherNotification?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundColor()
        setupLocationManager()
        setupNotification()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
        // 通知の初期設定
        let calendar = Calendar.current
        if let date = calendar.date(byAdding: .day, value: 0, to: Date()) {
            notification = WeatherNotification(date: date, isRainExpected: false, isNotificationEnabled: false)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notification != nil ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let notification = notification {
            cell.textLabel?.text = notification.date.string(format: "YYYY/MM/dd")
            let switchView = UISwitch(frame: .zero)
            switchView.setOn(notification.isNotificationEnabled, animated: true)
            switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        }
        return cell
    }

    @objc func switchChanged(_ sender: UISwitch) {
        if sender.isOn {
            if let notification = notification {
                checkWeatherAndScheduleNotification(for: notification)
            }
        } else {
            cancelNotification()
            notification?.isNotificationEnabled = false
        }
    }

    func checkWeatherAndScheduleNotification(for notification: WeatherNotification) {
        guard let location = userLocation else {
            print("User location not available")
            return
        }

        Task {
            do {
                let result = try await weatherService.weather(for: location)
                let currentWeather = result.currentWeather

                var updatedNotification = notification
                if currentWeather.condition == .rain {
                    updatedNotification.isRainExpected = true
                    updatedNotification.isNotificationEnabled = true
                    scheduleNotification(for: updatedNotification)
                } else {
                    updatedNotification.isRainExpected = false
                    showNoRainAlert(for: updatedNotification)
                }
                self.notification = updatedNotification
                tableView.reloadData()
            } catch {
                print("天気情報の取得に失敗しました: \(error)")
            }
        }
    }

    func scheduleNotification(for notification: WeatherNotification) {
        let content = UNMutableNotificationContent()
        content.title = "雨の通知"
        content.body = "今日は雨が降る予定です。傘を持って行きましょう！"
        content.sound = UNNotificationSound.default

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notification.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("通知のスケジューリングに失敗しました: \(error)")
            } else {
                print("通知がスケジュールされました: \(notification.date)")
            }
        }
    }

    func cancelNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func showNoRainAlert(for notification: WeatherNotification) {
        let alert = UIAlertController(title: "雨の通知", message: "今日は雨が降る予定はありません。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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


// WeatherNotification データモデルの定義
struct WeatherNotification {
    var date: Date
    var isRainExpected: Bool
    var isNotificationEnabled: Bool
}
