class DisasterHistory {
  final String province;
  final double maxRain; // Lượng mưa gây lụt kỷ lục
  final double maxWind; // Tốc độ gió bão lớn nhất
  final String eventName;

  DisasterHistory(this.province, this.maxRain, this.maxWind, this.eventName);
}

// Dữ liệu mẫu các trận thiên tai lớn tại VN
List<DisasterHistory> vietnamHistory = [
  DisasterHistory("Hà Nội", 350.0, 100.0, "Trận lụt lịch sử 2008"),
  DisasterHistory("Quảng Bình", 500.0, 150.0, "Lũ lụt miền Trung 2020"),
  DisasterHistory("Nam Định", 200.0, 120.0, "Bão số 7 năm 2005"),
  DisasterHistory("Lào Cai", 250.0, 80.0, "Sạt lở đất do bão Yagi 2024"),
  DisasterHistory("Hải Phòng", 180.0, 160.0, "Siêu bão Yagi 2024"),
];
