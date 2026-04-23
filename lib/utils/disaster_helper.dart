class DisasterHelper {
  static String getAlertMessage(int code, double speed, double temp) {
    if (code >= 200 && code <= 232) return "⚠️ CẢNH BÁO: Đang có dông sét. Hãy ở trong nhà!";
    if (code >= 502 && code <= 504) return "⚠️ CẢNH BÁO: Mưa rất lớn, nguy cơ ngập lụt cao!";
    if (speed > 17.0) return "🚩 CẢNH BÁO: Gió mạnh cực độ. Nguy cơ đổ gãy cây cối!";
    if (temp > 40) return "🔥 CẢNH BÁO: Nắng nóng gay gắt. Hạn chế ra ngoài!";
    return "✅ Hiện tại thời tiết bình thường, không có thiên tai.";
  }

  static bool isDangerous(int code, double speed, double temp) {
    return code < 700 || speed > 15 || temp > 38;
  }
}