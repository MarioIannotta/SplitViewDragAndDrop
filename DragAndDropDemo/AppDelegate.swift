//
//  AppDelegate.swift
//  DragAndDropDemo
//
//  Created by Mario on 26/05/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        SplitViewDragAndDrop.configure(groupIdentifier: "group.com.marioiannotta.draganddropdemo")
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if AppConfig.isDragApp {
            window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DragViewController")
        } else {
            window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DropViewController")
        }
        
        window?.makeKeyAndVisible()
        
        return true
        
    }

}

