import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdHelper {
  static const String _deviceIdKey = 'device_unique_id';

  /// Returns the persistent unique device ID.
  /// Generates a new secure UUID v4 if one hasn't been created yet.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = _generateUniqueId();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  /// Generates a RFC 4122 version 4 compliant UUID.
  static String _generateUniqueId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Set UUID v4 version (0100) and variant (10)
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant RFC 4122
    
    final buffer = StringBuffer();
    for (int i = 0; i < values.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
