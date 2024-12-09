import 'package:geolocator/geolocator.dart';
//import 'package:permission_handler/permission_handler.dart';

const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 1,
);

final positionStream =
    Geolocator.getPositionStream(locationSettings: locationSettings);

Future<bool> checkAndRequestPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  } else if (permission == LocationPermission.denied) {
    // Request permissions if they are simply denied
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      // Telling the user no, you're going to give us location permissions, but implicitly.
      // Ofcourse, they could say no, but they wouldn't.... because of the implciation...
      await Geolocator.openAppSettings();
      // DOES NOT APPEAR TO WORK AT THIS TIME
    }
  }

  // At this point, you can check again if permission is granted
  if (permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always) {
    return true;
    // Permissions granted, either in app or always, later (cache hunting) we may need to specify but this works for now.
  } else {
    return false;
    // Permissions aren't granted, just default to geographic center and users can cry in the forums about it.
  }
}
