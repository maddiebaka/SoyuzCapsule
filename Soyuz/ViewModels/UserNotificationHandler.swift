//
//  UserNotificationProtocol.swift
//  Soyuz
//
//  Created by Madeline Pace on 5/28/23.
//

import UserNotifications

class UserNotificationHandler {
    static var shared = UserNotificationHandler()
    
    private var center = UNUserNotificationCenter.current()
    
    enum NotificationType {
        case printComplete
    }
    
    private init() {
        center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            if let error = error {
                print("Error requesting authorization: \(error)")
            }
        }
    }
    
    func sendNotification(_ type: NotificationType) {
        print("Sending notification.")
        // Build notification request
        let content = UNMutableNotificationContent()
        // TODO: Replace this with localized strings
        content.title = "Print Complete! 🎉"
        let request = UNNotificationRequest(identifier: "Print Finished", content: content, trigger: nil)
        
        // Dispatch notification to system
        center.add(request) { (error: Error?) in
            if let theError = error {
                print("Error: \(theError)")
            }
        }
    }
}
