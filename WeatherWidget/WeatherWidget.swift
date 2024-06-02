import WidgetKit
import SwiftUI
import CoreLocation
import WeatherKit

struct Provider: AppIntentTimelineProvider {
    let weatherService = WeatherService()
    let locationManager = CLLocationManager()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), weatherDescription: "N/A", configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), weatherDescription: "Loading...", configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        if let location = locationManager.location {
            do {
                let result = try await weatherService.weather(for: location)
                let currentWeather = result.currentWeather
                
                let weatherDescription = getJapaneseWeatherDescription(from: currentWeather.condition)
                
                let currentDate = Date()
                let entry = SimpleEntry(date: currentDate, weatherDescription: weatherDescription, configuration: configuration)
                entries.append(entry)
                
                let timeline = Timeline(entries: entries, policy: .atEnd)
                return timeline
            } catch {
                print("Failed to get weather data: \(error)")
                let entry = SimpleEntry(date: Date(), weatherDescription: "Error", configuration: configuration)
                entries.append(entry)
                let timeline = Timeline(entries: entries, policy: .atEnd)
                return timeline
            }
        } else {
            let entry = SimpleEntry(date: Date(), weatherDescription: "Location not available", configuration: configuration)
            entries.append(entry)
            let timeline = Timeline(entries: entries, policy: .atEnd)
            return timeline
        }
    }
    
    func getJapaneseWeatherDescription(from condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "晴れ"
        case .cloudy:
            return "曇り"
        case .rain:
            return "雨"
        case .snow:
            return "雪"
        case .thunderstorms:
            return "雷雨"
        case .haze:
            return "靄"
        default:
            return "不明な天気"
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let weatherDescription: String
    let configuration: ConfigurationAppIntent
}

struct WeatherWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.weatherDescription)
                .font(.title)
                .padding()
            Text(entry.date, style: .time)
        }
    }
}

@main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WeatherWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    WeatherWidget()
} timeline: {
    SimpleEntry(date: .now, weatherDescription: "晴れ", configuration: .smiley)
    SimpleEntry(date: .now, weatherDescription: "曇り", configuration: .starEyes)
}

struct LockedScreenWidgetEntryView : View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryRectangular:
            Text("accessoryRectangular")
        case .accessoryCircular:
            Text("accessoryCircular")
        case .accessoryInline:
            Text("accessoryInline")
        default:
            EmptyView()
        }
    }
}

struct LockedScreenWidget: Widget {
    let kind: String = "LockedScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockedScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
