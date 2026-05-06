// Lớp chứa dữ liệu của một ngày trong quá khứ
class HistoricalWeather {
  final String date;
  final double maxTemp;
  final double rain;

  HistoricalWeather({
    required this.date,
    required this.maxTemp,
    required this.rain,
  });
}

class ForecastDay {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double precipitation;
  final int weatherCode;

  ForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitation,
    required this.weatherCode,
  });
}

class HourlyForecast {
  final DateTime dateTime;
  final double temperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;

  HourlyForecast({
    required this.dateTime,
    required this.temperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
  });
}

// Lớp chứa toàn bộ dữ liệu thời tiết
class WeatherData {
  final String cityName;
  final double currentTemp;
  final double currentTempF;
  final int conditionCode;
  final double windSpeed;
  final double humidity;
  final double uvIndex;
  final double visibility;
  final double lat;
  final double lon;
  final double precipitation;
  final int cloudCover;
  final List<HistoricalWeather> history; // Danh sách dữ liệu quá khứ
  final List<ForecastDay> forecast; // Dự báo vài ngày tới
  final List<HourlyForecast> hourly; // Dự báo theo giờ

  WeatherData({
    required this.cityName,
    required this.currentTemp,
    required this.currentTempF,
    required this.conditionCode,
    required this.windSpeed,
    required this.humidity,
    required this.uvIndex,
    required this.visibility,
    required this.lat,
    required this.lon,
    required this.precipitation,
    required this.cloudCover,
    required this.history,
    required this.forecast,
    required this.hourly,
  });
}
