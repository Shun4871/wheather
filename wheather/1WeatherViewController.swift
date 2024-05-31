//
//  tenkiyouhou.swift
//  weather
//
//  Created by 柘植俊之介 on 2024/05/30.
//



import CoreLocation
import WeatherKit
import UIKit

final class WeatherViewController: UIViewController, CLLocationManagerDelegate{
    
    @IBOutlet weak var weatherButton: UIButton!
    @IBAction func showWeatherView(_ sender: UIButton) {
            let weatherVC = WeatherViewController()
            weatherVC.modalPresentationStyle = .fullScreen
            present(weatherVC, animated: true, completion: nil)
        }
    
    
    let locationManager = CLLocationManager()
    let service = WeatherService()
    
    let weatherView = WeatherView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        getUserlocation()
        // Do any additional setup after loading the view.
    }
    
    func getUserlocation(){
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func getWeather(location: CLLocation){
        Task{
            do{
                 let result = try await service.weather(for: location)
                print("Current: "+String(describing: result.currentWeather))
                print("Daily: "+String(describing: result.dailyForecast))
                print("Minutely: "+String(describing: result.minuteForecast))
            } catch{
                print(String(describing: error))
            }
        }
    }
    
    func setUpView(){
        view.addSubview(weatherView)
        NSLayoutConstraint.activate([
            weatherView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            weatherView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            weatherView.topAnchor.constraint(equalTo: view.topAnchor),
            weatherView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func locationManager( _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        guard let location = locations.first else{
            return
        }
        locationManager.stopUpdatingLocation()
        getWeather(location: location)
    }
}

