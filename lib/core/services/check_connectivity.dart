import 'package:connectivity_plus/connectivity_plus.dart';

class CheckConnectivity {

  Future<bool> isInternetAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

}