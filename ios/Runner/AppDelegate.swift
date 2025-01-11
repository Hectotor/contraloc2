import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Supprimer ou commenter le code lié aux notifications push
    // if #available(iOS 10.0, *) {
    //   UNUserNotificationCenter.current().delegate = self
    //   let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    //   UNUserNotificationCenter.current().requestAuthorization(
    //     options: authOptions,
    //     completionHandler: {_, _ in })
    // }
    // application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
