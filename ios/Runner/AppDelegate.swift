import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Replace YOUR_GOOGLE_MAPS_API_KEY with your actual Google Maps API key
    GMSServices.provideAPIKey("AIzaSyCxkkAm9EmRlDUlK2Us1r1OUki0ZV3ktmc")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
