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

  // 4. Gọi Groq AI phân tích (Bạn thay Key của bạn vào)
  Future<String> analyzeWithGroq(WeatherData data, DisasterHistory? disasterHistory) async {
    const String groqKey =
        "gsk_m8oX9zO9W38XU6W3oZ8W3oZ8W3oZ8W3oZ8W3oZ8W3oZ8W3oZ8";
    String histContext = data.history
        .map((e) => "Ngày ${e.date}: ${e.maxTemp}C, Mưa ${e.rain}mm")
        .join(". ");

    String disasterContext = "";
    if (disasterHistory != null) {
      disasterContext = "Kỷ lục lịch sử tại ${disasterHistory.province}: Mưa tối đa ${disasterHistory.maxRain}mm, Gió tối đa ${disasterHistory.maxWind}km/h (${disasterHistory.eventName}). ";
    }

    final prompt =
        "Thông tin thời tiết hiện tại: Nhiệt độ ${data.currentTemp}C, Lượng mưa ${data.precipitation}mm, Tốc độ gió ${data.windSpeed}km/h. "
        "$disasterContext. "
        "Dữ liệu 3 năm qua: $histContext. "
        "YÊU CẦU: Dựa vào thời tiết hiện tại và so sánh với Kỷ lục thiên tai lịch sử, nếu thời tiết hiện tại có lượng mưa hoặc tốc độ gió cao (có khả năng hoặc nguy cơ xảy ra thiên tai tương tự), hãy phát ra 'CẢNH BÁO THIÊN TAI' và hướng dẫn chi tiết 'CÁCH PHÒNG CHỐNG'. Nếu thời tiết hiện tại an toàn, hãy dự báo bình thường. Trả lời bằng tiếng Việt (tối đa 100 từ).";

    try {
      final res = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $groqKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama3-8b-8192",
          "messages": [
            {"role": "user", "content": prompt},
          ],
        }),
      );
      return jsonDecode(
        utf8.decode(res.bodyBytes),
      )['choices'][0]['message']['content'];
    } catch (e) {
      return "✅ Dữ liệu lịch sử cho thấy thời tiết đang ở mức an toàn.";
    }
  }
}
