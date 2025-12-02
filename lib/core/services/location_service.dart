import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Returns current location as [LatLng].
  ///
  /// If permissions are denied or an error occurs, returns LatLng(0, 0).
  Future<LatLng> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return LatLng(0, 0);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LatLng(0, 0);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied
        return LatLng(0, 0);
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return LatLng(0, 0);
    }
  }
}
