import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../data/disaster_data.dart';

class DisasterService {
  // Đường dẫn mẫu tới file JSON trên web (Ví dụ GitHub Gist)
  // URL này dùng để mô phỏng việc tải dữ liệu từ web.
  static const String webDataUrl =
      'https://raw.githubusercontent.com/tinhq/ungdungdubao/main/assets/data/vietnam_disasters.json';

  List<DisasterHistory> _disasterData = [];

  // Khởi tạo dữ liệu
  Future<void> initData() async {
    try {
      // 1. Thử tải dữ liệu từ Web trước
      print("Đang thử tải dữ liệu thiên tai từ Web...");
      final response = await http.get(Uri.parse(webDataUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _parseData(data);
        print("Tải dữ liệu từ Web thành công!");
        return;
      }
    } catch (e) {
      print("Lỗi tải từ Web: $e");
    }

    // 2. Nếu tải Web thất bại, dùng Fallback (dữ liệu local)
    print("Dùng dữ liệu dự phòng từ Local...");
    final String response = await rootBundle.loadString('assets/data/vietnam_disasters.json');
    final data = jsonDecode(response);
    _parseData(data);
    print("Tải dữ liệu Local thành công!");
  }

  void _parseData(Map<String, dynamic> data) {
    if (data['disasters'] != null) {
      _disasterData = (data['disasters'] as List).map((item) {
        return DisasterHistory(
          item['province'],
          (item['maxRain'] as num).toDouble(),
          (item['maxWind'] as num).toDouble(),
          item['eventName'],
        );
      }).toList();
    }
  }

  // Lấy dữ liệu lịch sử của một tỉnh thành
  DisasterHistory? getHistoryForProvince(String provinceName) {
    for (var history in _disasterData) {
      if (provinceName.toLowerCase().contains(history.province.toLowerCase()) || 
          history.province.toLowerCase().contains(provinceName.toLowerCase())) {
        return history;
      }
    }
    return null;
  }
}
