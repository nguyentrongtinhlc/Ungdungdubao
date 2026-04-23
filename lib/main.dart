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
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
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
      // 3. Gọi AI phân tích
      final aiRes = await _service.analyzeWithGroq(data, disasterInfo);

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

  @override
  void initState() {
    super.initState();
    _initGPS();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBox(),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.blue),
            onPressed: _initGPS,
          ),
        ],
      ),
      body: _weather == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                    ),
                  ),
                  Text(
                    "${_weather!.currentTemp.round()}°",
                    style: const TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.w100,
                      color: Colors.blueAccent,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. BẢNG DỮ LIỆU QUÁ KHỨ (Bằng chứng cho thầy cô xem)
                  if (_localDisasterInfo != null) _buildDisasterRecord(),
                  const SizedBox(height: 10),
                  _buildHistorySection(),

                  const SizedBox(height: 20),

                  // 4. BẢN ĐỒ VỆ TINH TRẮNG
                  _buildMap(),

                  // 5. GRID 6 THÔNG SỐ
                  _buildStatGrid(),
                  const SizedBox(height: 50),
                ],
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
}
