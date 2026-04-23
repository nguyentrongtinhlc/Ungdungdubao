import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


class WeatherMap extends StatefulWidget {
  final double lat;
  final double lon;

  const WeatherMap({super.key, required this.lat, required this.lon});

  @override
  State<WeatherMap> createState() => _WeatherMapState();
}

class _WeatherMapState extends State<WeatherMap> {
  // Loại lớp phủ mặc định: clouds (mây), temp (nhiệt độ), precipitation (mưa), wind (gió)
  String activeLayer = "temp_new";
  final String apiKey = "a54dae2fc28a855d873db42dd7c82ec9";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. THANH ĐIỀU KHIỂN LỚP PHỦ (Buttons)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _layerButton("Nhiệt độ", "temp_new", Icons.thermostat),
                _layerButton("Mây", "clouds_new", Icons.cloud),
                _layerButton("Mưa", "precipitation_new", Icons.umbrella),
                _layerButton("Gió", "wind_new", Icons.air),
              ],
            ),
          ),
        ),

        // 2. BẢN ĐỒ
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                FlutterMap(
                  key: ValueKey(activeLayer), // Quan trọng để map load lại khi đổi layer
                  options: MapOptions(
                    initialCenter: LatLng(widget.lat, widget.lon),
                    initialZoom: 8.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    ),
                    Opacity(
                      opacity: 0.7,
                      child: TileLayer(
                        urlTemplate: 'https://tile.openweathermap.org/map/$activeLayer/{z}/{x}/{y}.png?appid=$apiKey',
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.lat, widget.lon),
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),

                // Hiển thị tên lớp đang xem trên bản đồ
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    color: Colors.black54,
                    child: Text("Đang xem: ${activeLayer.replaceAll('_new', '').toUpperCase()}",
                        style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _layerButton(String label, String layer, IconData icon) {
    bool isActive = activeLayer == layer;
    return GestureDetector(
      onTap: () => setState(() => activeLayer = layer),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isActive ? Colors.blue : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.white70),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}