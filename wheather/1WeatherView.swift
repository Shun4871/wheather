//
//  WeatherResponse.swift
//  weather
//
//  Created by 柘植俊之介 on 2024/05/30.
//

import UIKit

class WeatherView: UIView {
    let currentWeatherLabel = UILabel()
    let dailyForecastLabel = UILabel()
    let minuteForecastLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(currentWeatherLabel)
        addSubview(dailyForecastLabel)
        addSubview(minuteForecastLabel)
        
        currentWeatherLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyForecastLabel.translatesAutoresizingMaskIntoConstraints = false
        minuteForecastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentWeatherLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            currentWeatherLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            currentWeatherLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            dailyForecastLabel.topAnchor.constraint(equalTo: currentWeatherLabel.bottomAnchor, constant: 20),
            dailyForecastLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            dailyForecastLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            minuteForecastLabel.topAnchor.constraint(equalTo: dailyForecastLabel.bottomAnchor, constant: 20),
            minuteForecastLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            minuteForecastLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    func updateWeather(current: String, daily: String, minutely: String) {
        currentWeatherLabel.text = current
        dailyForecastLabel.text = daily
        minuteForecastLabel.text = minutely
    }
}
