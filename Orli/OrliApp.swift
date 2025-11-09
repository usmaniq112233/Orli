//
//  OrliApp.swift
//  Orli
//
//  Created by mohammad ali panhwar on 18/06/2025.
//

import SwiftUI
import FirebaseCore
import StoreKit
import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }

        return true
    }
    
    func userNotificationCenter(
         _ center: UNUserNotificationCenter,
         willPresent notification: UNNotification,
         withCompletionHandler completionHandler:
         @escaping (UNNotificationPresentationOptions) -> Void
     ) {
         completionHandler([.banner, .sound, .list])
     }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM token: \(fcmToken ?? "")")
        // Save this token to Firestore under the user
        saveFCMTokenToFirestore(fcmToken)
    }
    
    func saveFCMTokenToFirestore(_ token: String?) {
        guard let token = token else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                print("❌ Failed to save FCM token: \(error.localizedDescription)")
            } else {
                print("✅ FCM token saved to Firestore")
            }
        }
    }

}



@main
struct OrliApp: App {
    @AppStorage("isDarkModeOn") private var isDarkModeOn = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(isDarkModeOn ? .dark : .light)
        }
    }
}
