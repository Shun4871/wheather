//
//  tenkiyouhou.swift
//  weather
//
//  Created by 柘植俊之介 on 2024/05/30.
//

import CoreLocation
import WeatherKit
import UIKit

final class WeatherViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var characterImageView: UIImageView!
    @IBOutlet var temperature: UILabel!
    @IBOutlet var place: UILabel!
    @IBOutlet var weather: UILabel!
    
    @IBAction func reload() {
        getUserlocation()
    }
    
    let locationManager = CLLocationManager()
    let service = WeatherService()
    let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUserlocation()
        setupBackgroundColor()
    }
    
    func setupBackgroundColor() {
        let backgroundColor = UIColor(red: 115/255.0, green: 203/255.0, blue: 249/255.0, alpha: 1.0)
        view.backgroundColor = backgroundColor
    }
    
    func getUserlocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func getWeather(location: CLLocation) {
        Task {
            do {
                let result = try await service.weather(for: location)
                let currentWeather = result.currentWeather
                
                DispatchQueue.main.async {
                    // 温度を整数に変換して表示
                    let temperatureInt = Int(currentWeather.temperature.value.rounded())
                    self.temperature.text = "\(temperatureInt)°"
                    self.weather.text = self.getJapaneseWeatherDescription(from: currentWeather.condition)
                }
                
                geocodeLocation(location)
                
            } catch {
                DispatchQueue.main.async {
                    self.temperature.text = "エラー"
                    self.place.text = "エラー"
                    self.weather.text = "エラー"
                }
                print(String(describing: error))
            }
        }
    }
    
    
    func geocodeLocation(_ location: CLLocation) {
        let locale = Locale(identifier: "ja_JP")
        geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, error in
            if let error = error {
                print("逆ジオコーディングに失敗しました: \(error.localizedDescription)")
                self.place.text = "場所不明"
                return
            }
            
            if let placemark = placemarks?.first {
                let locality = placemark.locality ?? "不明な場所"
                let administrativeArea = placemark.administrativeArea ?? "不明な地域"
                self.place.text = "\(administrativeArea) \(locality)"
            } else {
                self.place.text = "場所不明"
            }
        }
    }
    
    func getJapaneseWeatherDescription(from condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            characterImageView.image = UIImage (named: "sunny")
            return "晴れ"
        case .mostlyClear:
            characterImageView.image = UIImage (named: "sunny")
            return "快晴"
        case .cloudy:
            characterImageView.image = UIImage (named: "cloudy")
            return "曇り"
        case .rain:
            characterImageView.image = UIImage (named: "rainy")
            return "雨"
        case .snow:
            characterImageView.image = UIImage (named: "snow")
            return "雪"
        case .haze:
            characterImageView.image = UIImage (named: "wind")
            return "靄"
        case .partlyCloudy:
            characterImageView.image = UIImage (named: "cloudy")
            return "部分的に曇り"
        case .mostlyCloudy:
            characterImageView.image = UIImage (named: "cloudy")
            return "ほぼ曇り"
        case .windy:
            characterImageView.image = UIImage (named: "wind")
            return "風"
        case .heavyRain:
            characterImageView.image = UIImage (named: "rainy")
            return "大雨"
        case .thunderstorms:
            characterImageView.image = UIImage (named: "thunder")
            return "雷"
            // 他の天気状態もここに追加できます
        default:
            characterImageView.image = UIImage (named: "unknown")
            return "不明"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        locationManager.stopUpdatingLocation()
        getWeather(location: location)
    }
}
