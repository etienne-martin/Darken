//
//  AppDelegate.swift
//  Darken
//
//  Created by Emartin on 2015-09-10.
//  Copyright (c) 2015 etiennemartin.ca. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        Darken()
        
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}
