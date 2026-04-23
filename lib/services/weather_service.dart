import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_model.dart';
import '../data/disaster_data.dart';
class WeatherService {
  // 1. Tìm tọa độ từ tên thành phố
  Future<Map<String, dynamic>> getCoords(String city) async {
    final url =
        "https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=vi&format=json";
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    if (data['results'] == null) throw Exception("Không tìm thấy thành phố");
    return data['results'][0];
  }

  // 2. Dịch tọa độ ra tên địa danh
  Future<String> getCityNameFromCoords(double lat, double lon) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10";
    final res = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'WeatherAppBTL'},
    );
    final data = jsonDecode(res.body);
    return data['address']['city'] ??
        data['address']['state'] ??
        data['address']['town'] ??
        "Vị trí lạ";
  }

  // 3. Lấy dữ liệu tổng hợp (Hiện tại + Quá khứ)
  Future<WeatherData> getFullData(
    double lat,
    double lon,
    String cityName,
  ) async {
    // A. Lấy thời tiết hiện tại
    final currentUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,uv_index,visibility,precipitation,cloud_cover&timezone=auto";
    final resC = await http.get(Uri.parse(currentUrl));
    final dataC = jsonDecode(resC.body)['current'];

    // B. Lấy dữ liệu lịch sử (Ngày này của 3 năm trước: 2023, 2022, 2021)
    List<HistoricalWeather> historyList = [];
    final now = DateTime.now();
    for (int i = 1; i <= 3; i++) {
      String pastDate =
          "${now.year - i}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final histUrl =
          "https://archive-api.open-meteo.com/v1/archive?latitude=$lat&longitude=$lon&start_date=$pastDate&end_date=$pastDate&daily=temperature_2m_max,precipitation_sum&timezone=auto";

      try {
        final resH = await http.get(Uri.parse(histUrl));
        final hData = jsonDecode(resH.body)['daily'];
        historyList.add(
          HistoricalWeather(
            date: pastDate,
            maxTemp: (hData['temperature_2m_max'][0] ?? 0).toDouble(),
            rain: (hData['precipitation_sum'][0] ?? 0).toDouble(),
          ),
        );
      } catch (e) {
        print("Lỗi lấy lịch sử năm ${now.year - i}: $e");
      }
    }

    // C. Trả về đối tượng WeatherData hoàn chỉnh
    return WeatherData(
      cityName: cityName,
      currentTemp: dataC['temperature_2m'].toDouble(),
      currentTempF: (dataC['temperature_2m'] * 9 / 5) + 32,
      conditionCode: dataC['weather_code'],
      windSpeed: dataC['wind_speed_10m'].toDouble(),
      humidity: dataC['relative_humidity_2m'].toDouble(),
      uvIndex: dataC['uv_index'].toDouble(),
      visibility: dataC['visibility'] / 1000,
      lat: lat,
      lon: lon,
      precipitation: dataC['precipitation'].toDouble(),
      cloudCover: dataC['cloud_cover'].toInt(),
      history: historyList, // Đưa danh sách quá khứ vào đây
    );
  }

  // 4. Phân tích cảnh báo thiên tai dựa trên ngưỡng kỷ lục lịch sử (không cần AI)
  String analyzeDisasterRisk(WeatherData data, DisasterHistory? disaster) {
    final double rain = data.precipitation;
    final double wind = data.windSpeed;

    // Dùng ngưỡng kỷ lục của địa phương, hoặc ngưỡng chung nếu không có
    final double rainThreshold = disaster?.maxRain ?? 200.0;
    final double windThreshold = disaster?.maxWind ?? 100.0;
    final String eventName = disaster?.eventName ?? "thiên tai";
    final String province = disaster?.province ?? data.cityName;

    // Tính % so với kỷ lục
    final double rainRatio = rainThreshold > 0 ? rain / rainThreshold : 0;
    final double windRatio = windThreshold > 0 ? wind / windThreshold : 0;

    List<String> warnings = [];
    List<String> tips = [];

    // --- CẢNH BÁO MƯA ---
    if (rainRatio >= 0.8) {
      warnings.add("⚠️ Lượng mưa ${rain}mm đạt ${(rainRatio * 100).round()}% ngưỡng lũ lịch sử ($eventName)!");
      tips.add("• Không ra đường khi mưa lớn, tránh vùng trũng thấp.");
      tips.add("• Chuẩn bị đồ dự phòng, di chuyển lên vùng cao nếu cần.");
    } else if (rainRatio >= 0.5) {
      warnings.add("🔶 Lượng mưa ${rain}mm ở mức trung bình so với kỷ lục lũ tại $province.");
      tips.add("• Theo dõi tin tức thời tiết, hạn chế ra ngoài khi mưa to.");
    }

    // --- CẢNH BÁO GIÓ ---
    if (windRatio >= 0.8) {
      warnings.add("⚠️ Tốc độ gió ${wind}km/h đạt ${(windRatio * 100).round()}% ngưỡng bão lịch sử ($eventName)!");
      tips.add("• Không đứng gần cây lớn, biển quảng cáo, mái tôn.");
      tips.add("• Gia cố cửa sổ, sơ tán nếu có lệnh chính quyền.");
    } else if (windRatio >= 0.5) {
      warnings.add("🔶 Tốc độ gió ${wind}km/h ở mức đáng chú ý, cần đề phòng.");
      tips.add("• Không ra khơi, hạn chế đi lại bằng xe máy.");
    }

    // --- KẾT QUẢ ---
    if (warnings.isEmpty) {
      String histNote = "";
      if (data.history.isNotEmpty) {
        final avgRain = data.history.map((e) => e.rain).reduce((a, b) => a + b) / data.history.length;
        histNote = " Trung bình mưa cùng ngày 3 năm qua: ${avgRain.toStringAsFixed(1)}mm.";
      }
      return "✅ Thời tiết hiện tại an toàn so với kỷ lục thiên tai tại $province.$histNote\n\n📌 Kỷ lục lịch sử: Mưa ${rainThreshold}mm, Gió ${windThreshold}km/h ($eventName).";
    }

    return "🚨 CẢNH BÁO THIÊN TAI\n\n${warnings.join('\n')}\n\n🛡 CÁCH PHÒNG CHỐNG:\n${tips.join('\n')}";
  }
}

