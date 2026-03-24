import SwiftUI

// 天气数据模型
struct WeatherData: Codable {
    var location: String
    var temperature: Double
    var feelsLike: Double
    var humidity: Int
    var windSpeed: Double
    var condition: WeatherCondition
    var uvIndex: Int
    var aqi: Int
    var hourlyForecast: [HourlyWeather]
    var dailyForecast: [DailyWeather]
    var updatedAt: Date

    enum WeatherCondition: String, Codable {
        case sunny = "sunny"
        case cloudy = "cloudy"
        case partlyCloudy = "partly_cloudy"
        case rain = "rain"
        case thunderstorm = "thunderstorm"
        case snow = "snow"
        case fog = "fog"

        var icon: String {
            switch self {
            case .sunny: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .partlyCloudy: return "cloud.sun.fill"
            case .rain: return "cloud.rain.fill"
            case .thunderstorm: return "cloud.bolt.rain.fill"
            case .snow: return "cloud.snow.fill"
            case .fog: return "cloud.fog.fill"
            }
        }

        var description: String {
            switch self {
            case .sunny: return "晴天"
            case .cloudy: return "多云"
            case .partlyCloudy: return "晴转多云"
            case .rain: return "雨天"
            case .thunderstorm: return "雷暴"
            case .snow: return "雪天"
            case .fog: return "雾天"
            }
        }
    }
}

struct HourlyWeather: Codable, Identifiable {
    var id: UUID = UUID()
    var time: Date
    var temperature: Double
    var condition: WeatherData.WeatherCondition
}

struct DailyWeather: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var highTemp: Double
    var lowTemp: Double
    var condition: WeatherData.WeatherCondition
    var windSpeed: Double
    var humidity: Int
}

// 天气管理器
class WeatherManager: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var savedLocations: [String] = ["北京", "上海", "广州"]

    init() {
        loadSavedLocation()
    }

    func loadSavedLocation() {
        if let location = UserDefaults.standard.string(forKey: "last_weather_location") {
            fetchWeather(for: location)
        } else {
            fetchWeather(for: "北京")
        }
    }

    func fetchWeather(for location: String) {
        isLoading = true
        error = nil

        // 模拟 API 调用
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentWeather = self.generateMockWeather(for: location)
            self.isLoading = false
            UserDefaults.standard.set(location, forKey: "last_weather_location")
        }
    }

    func refresh() {
        if let location = currentWeather?.location {
            fetchWeather(for: location)
        }
    }

    func generateMockWeather(for location: String) -> WeatherData {
        let conditions: [WeatherData.WeatherCondition] = [.sunny, .partlyCloudy, .cloudy, .rain]
        let condition = conditions.randomElement()!

        return WeatherData(
            location: location,
            temperature: Double.random(in: 15...30),
            feelsLike: Double.random(in: 14...32),
            humidity: Int.random(in: 30...80),
            windSpeed: Double.random(in: 0...20),
            condition: condition,
            uvIndex: Int.random(in: 0...11),
            aqi: Int.random(in: 20...150),
            hourlyForecast: generateHourlyForecast(),
            dailyForecast: generateDailyForecast(),
            updatedAt: Date()
        )
    }

    func generateHourlyForecast() -> [HourlyWeather] {
        var forecasts: [HourlyWeather] = []
        let conditions: [WeatherData.WeatherCondition] = [.sunny, .partlyCloudy, .cloudy]

        for i in 0..<24 {
            let date = Calendar.current.date(byAdding: .hour, value: i, to: Date())!
            forecasts.append(HourlyWeather(
                time: date,
                temperature: Double.random(in: 18...28),
                condition: conditions.randomElement()!
            ))
        }

        return forecasts
    }

    func generateDailyForecast() -> [DailyWeather] {
        var forecasts: [DailyWeather] = []

        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
            forecasts.append(DailyWeather(
                date: date,
                highTemp: Double.random(in: 25...35),
                lowTemp: Double.random(in: 15...22),
                condition: [.sunny, .partlyCloudy, .cloudy, .rain].randomElement()!,
                windSpeed: Double.random(in: 5...15),
                humidity: Int.random(in: 40...70)
            ))
        }

        return forecasts
    }
}

// 天气视图
struct WeatherView: View {
    @StateObject private var weatherManager = WeatherManager()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if weatherManager.isLoading {
                        ProgressView()
                            .padding(.top, 100)
                    } else if let weather = weatherManager.currentWeather {
                        // 当前天气
                        CurrentWeatherCard(weather: weather)

                        // 详细信息
                        WeatherDetailGrid(weather: weather)

                        // 小时预报
                        HourlyForecastSection(forecast: weather.hourlyForecast)

                        // 7天预报
                        DailyForecastSection(forecast: weather.dailyForecast)
                    }
                }
                .padding()
            }
            .navigationTitle("🌤️ 天气")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { weatherManager.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                weatherManager.refresh()
            }
        }
    }
}

// 当前天气卡片
struct CurrentWeatherCard: View {
    let weather: WeatherData

    var body: some View {
        VStack(spacing: 16) {
            // 位置
            HStack {
                Image(systemName: "location.fill")
                Text(weather.location)
                    .font(.headline)
            }
            .foregroundColor(.white)

            // 天气图标
            Image(systemName: weather.condition.icon)
                .font(.system(size: 80))
                .foregroundColor(.white)

            // 温度
            Text("\(Int(weather.temperature))°")
                .font(.system(size: 72, weight: .thin))
                .foregroundColor(.white)

            // 体感温度
            Text("体感 \(Int(weather.feelsLike))°")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            // 天气描述
            Text(weather.condition.description)
                .font(.title3)
                .foregroundColor(.white)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
    }
}

// 天气详情网格
struct WeatherDetailGrid: View {
    let weather: WeatherData

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            WeatherDetailCard(icon: "humidity.fill", title: "湿度", value: "\(weather.humidity)%")
            WeatherDetailCard(icon: "wind", title: "风速", value: "\(Int(weather.windSpeed)) km/h")
            WeatherDetailCard(icon: "sun.max.fill", title: "紫外线", value: uvLevel(weather.uvIndex))
            WeatherDetailCard(icon: "aqi.medium", title: "AQI", value: aqiLevel(weather.aqi), color: aqiColor(weather.aqi))
        }
    }

    func uvLevel(_ index: Int) -> String {
        switch index {
        case 0...2: return "低"
        case 3...5: return "中等"
        case 6...7: return "高"
        case 8...10: return "很高"
        default: return "极高"
        }
    }

    func aqiLevel(_ aqi: Int) -> String {
        switch aqi {
        case 0...50: return "优"
        case 51...100: return "良"
        case 101...150: return "轻度"
        case 151...200: return "中度"
        case 201...300: return "重度"
        default: return "严重"
        }
    }

    func aqiColor(_ aqi: Int) -> Color {
        switch aqi {
        case 0...50: return .green
        case 51...100: return .yellow
        case 101...150: return .orange
        case 151...200: return .red
        case 201...300: return .purple
        default: return .brown
        }
    }
}

struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .blue

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 小时预报
struct HourlyForecastSection: View {
    let forecast: [HourlyWeather]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("小时预报")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(forecast.prefix(24)) { hour in
                        HourlyWeatherCard(weather: hour)
                    }
                }
            }
        }
    }
}

struct HourlyWeatherCard: View {
    let weather: HourlyWeather

    var body: some View {
        VStack(spacing: 8) {
            Text(weather.time, style: .hour)
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: weather.condition.icon)
                .font(.title3)

            Text("\(Int(weather.temperature))°")
                .font(.headline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 7天预报
struct DailyForecastSection: View {
    let forecast: [DailyWeather]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7天预报")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(forecast) { day in
                    DailyWeatherRow(weather: day)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct DailyWeatherRow: View {
    let weather: DailyWeather

    var body: some View {
        HStack {
            // 日期
            Text(weather.date, style: .date)
                .frame(width: 80, alignment: .leading)

            // 天气图标
            Image(systemName: weather.condition.icon)
                .foregroundColor(.blue)

            // 天气描述
            Text(weather.condition.description)
                .foregroundColor(.secondary)

            Spacer()

            // 温度
            HStack(spacing: 8) {
                Text("\(Int(weather.highTemp))°")
                    .fontWeight(.semibold)
                Text("\(Int(weather.lowTemp))°")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// 预览
struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}
