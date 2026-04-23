import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'models/weather_model.dart';
import 'services/weather_service.dart';
import 'services/disaster_service.dart';
import 'data/disaster_data.dart';
void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _service = WeatherService();
  final _disasterService = DisasterService();
  WeatherData? _weather;
  DisasterHistory? _localDisasterInfo;
  String aiAnalysis = "Đang truy xuất dữ liệu lịch sử...";
  bool isAiLoading = false;
  final MapController _mapController = MapController();
  final TextEditingController _cityController = TextEditingController();

  // --- HÀM LẤY DỮ LIỆU TỔNG HỢP ---
  _fetchData(double lat, double lon) async {
    setState(() => isAiLoading = true);
    try {
      // 1. Lấy tên thành phố từ tọa độ
      String name = await _service.getCityNameFromCoords(lat, lon);
      
      // Lấy thông tin thảm họa lịch sử từ Web/Local
      final disasterInfo = _disasterService.getHistoryForProvince(name);

      // 2. Lấy Full dữ liệu (Hiện tại + 3 năm quá khứ)
      final data = await _service.getFullData(lat, lon, name);
      // 3. Phân tích cảnh báo thiên tai dựa trên kỷ lục lịch sử (không cần AI)
      final aiRes = _service.analyzeDisasterRisk(data, disasterInfo);

      setState(() {
        _weather = data;
        _localDisasterInfo = disasterInfo;
        aiAnalysis = aiRes;
        isAiLoading = false;
      });
      _mapController.move(LatLng(lat, lon), 9);
    } catch (e) {
      setState(() => isAiLoading = false);
      print("Lỗi: $e");
    }
  }

  Future<void> _initGPS() async {
    await _disasterService.initData(); // Nạp dữ liệu từ web
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    _fetchData(pos.latitude, pos.longitude);
  }

  void _showWeatherGuide() {
    final w = _weather!;
    final List<Map<String, dynamic>> currentTips = [];
    if (w.currentTemp >= 37) {
      currentTips.add({'icon': Icons.thermostat, 'color': Colors.red, 'text': 'Nắng nóng gay gắt (\${w.currentTemp.round()}°C). Uống đủ nước, hạn chế ra ngoài 10h-16h.'});
    } else if (w.currentTemp >= 33) {
      currentTips.add({'icon': Icons.wb_sunny, 'color': Colors.orange, 'text': 'Trời nóng (\${w.currentTemp.round()}°C). Mặc áo chống nắng, đội nón khi ra đường.'});
    } else if (w.currentTemp <= 15) {
      currentTips.add({'icon': Icons.ac_unit, 'color': Colors.blue, 'text': 'Trời lạnh (\${w.currentTemp.round()}°C). Mặc áo ấm, giữ ấm cơ thể.'});
    } else {
      currentTips.add({'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Nhiệt độ dễ chịu (\${w.currentTemp.round()}°C). Thích hợp ra ngoài trời.'});
    }
    if (w.precipitation > 20) {
      currentTips.add({'icon': Icons.umbrella, 'color': Colors.indigo, 'text': 'Mưa rất to (\${w.precipitation}mm). Mang áo mưa, tránh vùng trũng thấp.'});
    } else if (w.precipitation > 5) {
      currentTips.add({'icon': Icons.umbrella, 'color': Colors.blueAccent, 'text': 'Có mưa (\${w.precipitation}mm). Nên mang theo áo mưa hoặc ô.'});
    }
    if (w.windSpeed > 60) {
      currentTips.add({'icon': Icons.air, 'color': Colors.red, 'text': 'Gió rất mạnh (\${w.windSpeed}km/h). Không đi xe máy, tránh vùng trống trải.'});
    } else if (w.windSpeed > 30) {
      currentTips.add({'icon': Icons.air, 'color': Colors.orange, 'text': 'Gió khá mạnh (\${w.windSpeed}km/h). Cẩn thận khi đi xe máy.'});
    }
    if (w.uvIndex >= 8) {
      currentTips.add({'icon': Icons.wb_sunny, 'color': Colors.deepOrange, 'text': 'Tia UV rất cao (\${w.uvIndex.round()}). Bôi kem SPF50+, mặc áo dài.'});
    } else if (w.uvIndex >= 5) {
      currentTips.add({'icon': Icons.wb_sunny, 'color': Colors.amber, 'text': 'Tia UV cao (\${w.uvIndex.round()}). Nên bôi kem chống nắng khi ra ngoài.'});
    }
    if (w.humidity > 85) {
      currentTips.add({'icon': Icons.water_drop, 'color': Colors.teal, 'text': 'Độ ẩm rất cao (\${w.humidity.round()}%). Thông thoáng nhà cửa tránh nấm mốc.'});
    }
    if (w.visibility < 1) {
      currentTips.add({'icon': Icons.visibility_off, 'color': Colors.grey, 'text': 'Tầm nhìn kém (<1km). Bật đèn xe, đi chậm và cẩn thận.'});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.deepPurple, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Hướng dẫn thời tiết hôm nay',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    Text(w.cityName, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('📍 DỰA TRÊN THỜI TIẾT HIỆN TẠI',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    ),
                    ...currentTips.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(t['icon'] as IconData, size: 22, color: t['color'] as Color),
                          const SizedBox(width: 12),
                          Expanded(child: Text(t['text'] as String,
                            style: const TextStyle(fontSize: 14, height: 1.5))),
                        ],
                      ),
                    )),
                    const Divider(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('📋 BẢNG NGƯỠNG THAM CHIẾU',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ),
                    _guideRow('🌡 Nhiệt độ ≥ 37°C', 'Tránh nắng 10h-16h, uống nhiều nước', Colors.red[50]!),
                    _guideRow('🌡 Nhiệt độ ≥ 33°C', 'Áo chống nắng, đội nón', Colors.orange[50]!),
                    _guideRow('🌡 Nhiệt độ ≤ 15°C', 'Mặc áo ấm, giữ ấm cơ thể', Colors.blue[50]!),
                    _guideRow('🌧 Mưa > 20mm', 'Áo mưa, tránh vùng ngập lụt', Colors.indigo[50]!),
                    _guideRow('🌧 Mưa > 5mm', 'Mang ô hoặc áo mưa', Colors.lightBlue[50]!),
                    _guideRow('💨 Gió > 60 km/h', 'Không đi xe máy, vào trong nhà', Colors.red[50]!),
                    _guideRow('💨 Gió > 30 km/h', 'Cẩn thận khi đi xe máy', Colors.orange[50]!),
                    _guideRow('☀️ UV ≥ 8', 'Kem SPF50+, áo dài tay, khẩu trang', Colors.deepOrange[50]!),
                    _guideRow('☀️ UV ≥ 5', 'Bôi kem chống nắng khi ra ngoài', Colors.amber[50]!),
                    _guideRow('💧 Độ ẩm > 85%', 'Thông thoáng nhà cửa, chống nấm mốc', Colors.teal[50]!),
                    _guideRow('👁 Tầm nhìn < 1km', 'Bật đèn xe, giảm tốc độ', Colors.grey[200]!),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideRow(String condition, String advice, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(condition, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(advice, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _initGPS();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _buildSearchBox(),
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        actions: [
          if (_weather != null)
            IconButton(
              icon: const Icon(Icons.menu_book_rounded, color: Colors.deepPurple),
              tooltip: 'Hướng dẫn thời tiết',
              onPressed: _showWeatherGuide,
            ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.blue),
            onPressed: _initGPS,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: _weather == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
              child: Column(
                children: [
                  // 1. KHỐI AI DỰ BÁO DỰA TRÊN LỊCH SỬ
                  _buildAICard(),
                  const SizedBox(height: 20),

                  // 2. THÔNG TIN CHÍNH
                  Text(
                    _weather!.cityName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                    ),
                  ),
                  Text(
                    "${_weather!.currentTemp.round()}°",
                    style: const TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. BẢNG DỮ LIỆU QUÁ KHỨ
                  if (_localDisasterInfo != null) _buildDisasterRecord(),
                  const SizedBox(height: 10),
                  _buildHistorySection(),

                  const SizedBox(height: 20),

                  // 4. BẢN ĐỒ VỆ TINH
                  _buildMap(),

                  // 5. GRID 6 THÔNG SỐ
                  _buildStatGrid(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _cityController,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          hintText: " Tìm thành phố...",
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (val) async {
          final c = await _service.getCoords(val);
          _fetchData(c['latitude'], c['longitude']);
        },
      ),
    );
  }

  Widget _buildAICard() {
    bool isWarning = aiAnalysis.contains("CẢNH BÁO") || aiAnalysis.contains("PHÒNG CHỐNG");
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isWarning ? Colors.orange[200]! : Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isWarning ? Icons.warning_rounded : Icons.auto_awesome, 
                color: isWarning ? Colors.deepOrange : Colors.blue, 
                size: 20
              ),
              const SizedBox(width: 10),
              Text(
                isWarning ? "CẢNH BÁO THIÊN TAI & PHÒNG CHỐNG" : "DỰ BÁO DỰA TRÊN LỊCH SỬ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isWarning ? Colors.deepOrange : Colors.blue,
                ),
              ),
              const Spacer(),
              if (isAiLoading)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            aiAnalysis,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: isWarning ? FontWeight.w500 : FontWeight.normal,
              color: isWarning ? Colors.red[900] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterRecord() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                "KỶ LỤC THIÊN TAI ĐỊA PHƯƠNG",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Sự kiện: ${_localDisasterInfo!.eventName}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            "🌧 Mưa kỷ lục: ${_localDisasterInfo!.maxRain} mm\n💨 Gió giật cực đại: ${_localDisasterInfo!.maxWind} km/h",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "DỮ LIỆU CÙNG NGÀY TRONG QUÁ KHỨ",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          ..._weather!.history
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        h.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        "${h.maxTemp.round()}°C",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${h.rain}mm mưa",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_weather!.lat, _weather!.lon),
            initialZoom: 8,
            onTap: (t, p) => _fetchData(p.latitude, p.longitude),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
            ),
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(_weather!.lat, _weather!.lon),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String l, String v, IconData i) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(i, size: 18, color: Colors.blue),
        Text(
          v,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    ),
  );

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _stat("Gió", "${_weather!.windSpeed}k/h", Icons.air),
        _stat("Mưa", "${_weather!.precipitation}mm", Icons.umbrella),
        _stat("Mây", "${_weather!.cloudCover}%", Icons.cloud),
        _stat("UV", "${_weather!.uvIndex}", Icons.wb_sunny),
        _stat("Tầm nhìn", "${_weather!.visibility}km", Icons.visibility),
        _stat("Độ ẩm", "${_weather!.humidity}%", Icons.water_drop),
      ],
    );
  }

  Widget _buildWeatherTips() {
    final w = _weather!;
    final List<Map<String, dynamic>> tips = [];

    // Nhiệt độ
    if (w.currentTemp >= 37) {
      tips.add({'icon': Icons.thermostat, 'color': Colors.red, 'text': 'Nắng nóng gay gắt (${w.currentTemp.round()}°C). Uống đủ nước, hạn chế ra ngoài lúc 10h-16h.'});
    } else if (w.currentTemp >= 33) {
      tips.add({'icon': Icons.wb_sunny, 'color': Colors.orange, 'text': 'Trời nóng (${w.currentTemp.round()}°C). Nên mặc áo chống nắng, đội nón khi ra đường.'});
    } else if (w.currentTemp <= 15) {
      tips.add({'icon': Icons.ac_unit, 'color': Colors.blue, 'text': 'Trời lạnh (${w.currentTemp.round()}°C). Mặc áo ấm, giữ ấm cơ thể khi ra ngoài.'});
    } else if (w.currentTemp <= 22) {
      tips.add({'icon': Icons.air, 'color': Colors.lightBlue, 'text': 'Thời tiết mát mẻ (${w.currentTemp.round()}°C). Thích hợp đi dạo ngoài trời.'});
    }

    // Lượng mưa
    if (w.precipitation > 20) {
      tips.add({'icon': Icons.umbrella, 'color': Colors.indigo, 'text': 'Mưa rất to (${w.precipitation}mm). Mang áo mưa, tránh vùng trũng thấp có thể ngập nước.'});
    } else if (w.precipitation > 5) {
      tips.add({'icon': Icons.umbrella, 'color': Colors.blueAccent, 'text': 'Có mưa (${w.precipitation}mm). Nên mang theo áo mưa hoặc ô.'});
    }

    // Tốc độ gió
    if (w.windSpeed > 60) {
      tips.add({'icon': Icons.air, 'color': Colors.red, 'text': 'Gió rất mạnh (${w.windSpeed}km/h). Không nên đi xe máy, tránh vùng trống trải.'});
    } else if (w.windSpeed > 30) {
      tips.add({'icon': Icons.air, 'color': Colors.orange, 'text': 'Gió khá mạnh (${w.windSpeed}km/h). Cẩn thận khi đi xe máy.'});
    }

    // Chỉ số UV
    if (w.uvIndex >= 8) {
      tips.add({'icon': Icons.wb_sunny, 'color': Colors.deepOrange, 'text': 'Tìa UV rất cao (${w.uvIndex.round()}). Bôi kem chống nắng SPF50+, mặc áo dài, đi khẩu trang.'});
    } else if (w.uvIndex >= 5) {
      tips.add({'icon': Icons.wb_sunny, 'color': Colors.amber, 'text': 'Tìa UV cao (${w.uvIndex.round()}). Nên bôi kem chống nắng khi ra ngoài.'});
    }

    // Độ ẩm
    if (w.humidity > 85) {
      tips.add({'icon': Icons.water_drop, 'color': Colors.teal, 'text': 'Độ ẩm rất cao (${w.humidity.round()}%). Dễ nấm mốc, cần thông thoáng nhà cửa.'});
    }

    // Tầm nhìn
    if (w.visibility < 1) {
      tips.add({'icon': Icons.visibility_off, 'color': Colors.grey, 'text': 'Tầm nhìn rất kém (<1km). Bật đèn xe, đi chậm và cẩn thận.'});
    }

    // Nếu không có lưu ý đặc biệt nào
    if (tips.isEmpty) {
      tips.add({'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Thời tiết ận, thích hợp đi lại và hoạt động ngoài trời hôm nay!'});
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'HƯỚNG DẪN THỜI TIẾT HÔM NAY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(t['icon'] as IconData, size: 20, color: t['color'] as Color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t['text'] as String,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
