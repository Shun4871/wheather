import WidgetKit
import SwiftUI
import CoreLocation
import WeatherKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), isRainExpected: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), isRainExpected: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        let location = CLLocation(latitude: 35.6895, longitude: 139.6917) // 東京の緯度経度を使用

        Task {
            do {
                let weatherService = WeatherService.shared
                let weather = try await weatherService.weather(for: location)
                let isRainExpected = weather.currentWeather.condition == .rain || weather.currentWeather.condition == .heavyRain || weather.currentWeather.condition == .thunderstorms

                var entries: [SimpleEntry] = []

                for hourOffset in 0..<5 {
                    let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                    let entry = SimpleEntry(date: entryDate, isRainExpected: isRainExpected)
                    entries.append(entry)
                }

                let timeline = Timeline(entries: entries, policy: .atEnd)
                DispatchQueue.main.async {
                    completion(timeline)
                }
            } catch {
                print("Error fetching weather data: \(error)")
                let entry = SimpleEntry(date: currentDate, isRainExpected: false)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                DispatchQueue.main.async {
                    completion(timeline)
                }
            }
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let isRainExpected: Bool
}

struct WeatherWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.date, style: .time)
            if entry.isRainExpected {
                Text("雨が降ります。傘を持ってください。")
                    .font(.headline)
                    .foregroundColor(.red)
            } else {
                Text("雨の心配はありません。")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}

@main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather Widget")
        .description("雨の予報を表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidgetEntryView(entry: SimpleEntry(date: Date(), isRainExpected: true))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

