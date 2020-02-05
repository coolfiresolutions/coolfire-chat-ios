import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UITextField.appearance().keyboardAppearance = .dark
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { Ronin.shared.reconnectIfNeeded() }

    func applicationDidEnterBackground(_ application: UIApplication) { Ronin.shared.disconnetSocket() }

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}
}
