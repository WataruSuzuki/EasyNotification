//
//  EasyNotification.swift
//  EasyNotification
//
//  Created by Wataru Suzuki on 2016/05/18.
//  Copyright © 2016年 WataruSuzuki. All rights reserved.
//

import UIKit
import UserNotifications

public class EasyNotification: NSObject,
    UNUserNotificationCenterDelegate
{
    static public let shared: EasyNotification = {
        return EasyNotification()
    }()
    
    @available(iOS 10.0, *)
    var options: UNAuthorizationOptions {
        get {
            if #available(iOS 12.0, *) {
                return [.provisional, .badge, .sound, .alert]
            } else {
                return [.badge, .sound, .alert]
            }
        }
    }
    var useRemoteNotification = false
    
    public var alertTitle = "(・A・)!!"
    public var alertMessage = "Cannot authorized using notification..."
    public var actionMessage = "Open setting"
    public var proceedAnywayMessage = "Proceed anyway"
    
    public var willPresent:((_ identifier: String) -> Void)? = nil
    public var didReceive:((_ identifier: String) -> Void)? = nil

    private override init() {
        super.init()
        
        checkAuthorization { (authorized) in
            //print(authorized)
        }
    }
    
    public func register(application: UIApplication, useRemoteNotification: Bool = false)  {
        self.useRemoteNotification = useRemoteNotification
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        } else {
            let notificationSetting = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            application.registerUserNotificationSettings(notificationSetting)
        }
    }
    
    public func checkAuthorization(status: @escaping ((_ authorized: Bool) -> Void)) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                switch settings.authorizationStatus {
                case .provisional:
                    fallthrough
                case .authorized:
                    status(true)
                case .notDetermined:
                    self.requestAuthorization()
                    fallthrough
                case .denied:
                    status(false)
                }
            }
        } else {
            if let types = UIApplication.shared.currentUserNotificationSettings?.types {
                status(types.contains(.alert))
            } else {
                status(false)
            }
        }
    }
    
    public func schedule(date: Date? = nil, title: String, subTitle: String? = nil, body: String, action: String, soundName: String? = nil, requestIdentifier: String) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            if let subTitle = subTitle {
                content.subtitle = subTitle
            }
            content.body = body
            if let soundName = soundName, !soundName.isEmpty {
                content.sound = UNNotificationSound(named: soundName)
            }
            
            let time = date != nil ? date!.timeIntervalSinceNow : Date().timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (time > 0 ? time : 1), repeats: false)
            
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        } else {
            let notification:UILocalNotification = UILocalNotification()
            notification.fireDate = date
            notification.alertTitle = title
            if let subTitle = subTitle {
                notification.alertBody = title + subTitle + body
            } else {
                notification.alertBody = title + body
            }
            notification.alertAction = action
            notification.soundName = soundName
            //notification.userInfo = ["notification_id": notification_id]
            
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
    
    @available(iOS 10.0, *)
    public func requestAuthorization(status: ((_ authorized: Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            status?(granted)
            if granted {
                if self.useRemoteNotification {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }
    
    public func alertAuthorization(title: String, message: String, rootViewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionMessage, style: .default, handler: { (UIAlertAction) in
            let url = URL(string: UIApplicationOpenSettingsURLString)!
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }))
        alert.addAction(UIAlertAction(title: proceedAnywayMessage, style: .cancel, handler: nil))
        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - notify on application
    
    public func notify(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // TODO
    }
    
    // MARK: - notify on application (deprecated...)
    
    public func notify(_ application: UIApplication, didReceive notification: UILocalNotification) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        // TODO
    }
    
    public func notify(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        // TODO
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let trigger = notification.request.trigger, trigger.repeats {
            UNUserNotificationCenter.current().add(notification.request) {
                (error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
        willPresent?(notification.request.identifier)
        completionHandler([.alert, .badge, .sound])
    }
    
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        didReceive?(response.actionIdentifier)
    }
}
