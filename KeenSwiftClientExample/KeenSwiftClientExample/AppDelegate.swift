//
//  AppDelegate.swift
//  KeenSwiftClientExample
//
//  Created by Claire Young on 5/4/15.
//  Copyright (c) 2015 Keen.IO. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        KeenClient.enableLogging();
        
        var client : KeenClient;
        client = KeenClient.sharedClientWithProjectId("4f4ed092163d663d3a000000", andWriteKey: "9a9d92907c3e43c3a4742535fc2f78ec", andReadKey: nil);

        client.globalPropertiesBlock = {(eventCollection : String!) -> [NSObject : AnyObject]! in
            return [ "GLOBALS": "YEAH WHAT SWIFT"]
        };
        
        NSLog("KeenClient-iOS %@ [from class method]", KeenClient.sdkVersion());
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        var taskId : UIBackgroundTaskIdentifier = application.beginBackgroundTaskWithExpirationHandler({() -> Void in
            NSLog("Background task is being expired.")
        });
        KeenClient.sharedClient().uploadWithFinishedBlock({() -> Void in
            application.endBackgroundTask(taskId)});
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

