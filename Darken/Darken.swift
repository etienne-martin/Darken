//
//  Darken.swift
//  Darken
//
//  Created by Emartin on 2015-09-14.
//  Copyright (c) 2015 etiennemartin.ca. All rights reserved.
//

import Cocoa
import SwiftShell

public class Darken: NSObject{
    
    /* MenubarApp*/
    var statusMenu = NSStatusBar.systemStatusBar()
    var statusItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    
    var gammaArray = [AnyObject]()
    
    var interval:NSTimer?
    var toggleButton = NSMenuItem()
    var toggleState = "0"
    var indicatorButton = NSMenuItem()
    var brigtnessSlider = NSSlider()
    
    var brightnessToken:String = "0"
    var globalBrightness: Float = 1.0
    var lastAppliedBrightness: Float = 1.0
    var steps:Int = 1
    
    let TXT_looking_for_light_sensor = "Looking for light sensor..."
    let TXT_turn_darken_on = "Turn Darken On"
    let TXT_turn_darken_off = "Turn Darken Off"
    
    override init() {
        super.init()
        
        /* MenubarApp*/
        statusItem = statusMenu.statusItemWithLength(-1)
        let icon = NSImage(named: "statusIconOFF")
        icon?.template = true
        statusItem.image = icon
        statusItem.menu = menu
        
        // Required to manually enable and disable menu items
        menu.autoenablesItems = false
        
        let quitButton = NSMenuItem()
        quitButton.title = "Quit"
        quitButton.action = Selector("quit:")
        quitButton.target = self
        quitButton.enabled = true
        
        toggleButton.title = TXT_turn_darken_on
        toggleButton.action = Selector("toggleState:")
        toggleButton.target = self
        toggleButton.enabled = true
        
        indicatorButton.title = TXT_looking_for_light_sensor
        indicatorButton.target = self
        indicatorButton.enabled = false
        
        brigtnessSlider = NSSlider(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
        
        brigtnessSlider.continuous = false; // false makes it call only once you let go
        brigtnessSlider.target = self
        brigtnessSlider.action = Selector("brigtnessAdjustChanged:")
        
        if let brigtnessAdjustState: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("brigtnessAdjustState") {
            brigtnessSlider.floatValue = Float(brigtnessAdjustState as! NSNumber)
        }else{
            // Default brightness adjustement: 0.5
            brigtnessSlider.floatValue = 0.5
        }
        
        let brigtnessAdjust = NSMenuItem()
        brigtnessAdjust.title = "Adjust brightness"
        brigtnessAdjust.view = brigtnessSlider
        
        menu.insertItem(quitButton, atIndex: 0)
        menu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        menu.insertItem(toggleButton, atIndex: 0)
        menu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        menu.insertItem(brigtnessAdjust, atIndex: 0)
        menu.insertItem(NSMenuItem.separatorItem(), atIndex: 0)
        menu.insertItem(indicatorButton, atIndex: 0)
        
        // Start app when login in
        if (!StartupLaunch.isAppLoginItem()) {
            StartupLaunch.setLaunchOnLogin(true)
        }
        
        let brightnessInterval = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "getBrightness", userInfo: nil, repeats: true)
        // Register timer to refresh while menu is open
        NSRunLoop.currentRunLoop().addTimer(brightnessInterval, forMode: NSRunLoopCommonModes)
        
        if let storedToggleState: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("state") {
            
            toggleState = storedToggleState as! String
            
            // Darken was active the last time the app was open
            if( "\(storedToggleState)" == "1" ){
                startInterval()
            }
            
        }else{
            // First time opening the app.
            startInterval()
        }
    }
    
    func brigtnessAdjustChanged(sender: NSSlider) {
        // Store the current state of the application (on/off) into the user prefs
        NSUserDefaults.standardUserDefaults().setObject(brigtnessSlider.floatValue, forKey: "brigtnessAdjustState")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func setBrightness(){
        
        let percent:Float = 1.0-(globalBrightness) // Invert value
        
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        if( result != CGError.Success ){
            print("error: \(result)")
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.alloc(allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        if( result != CGError.Success ){
            print("error: \(result)")
        }
        for i in 0..<displayCount {
            
            let displayID = activeDisplays[Int(i)]
            
            if( CGDisplayIsBuiltin(displayID) == 0 ){ // If the display is not builtin
                
                var inArray = false
                
                var gammaValues = []
                
                for display in gammaArray {
                    
                    if( "\(display[0])" == "\(displayID)" ){ // If the gamma values of the display have already been listed
                        
                        inArray = true
                        
                        gammaValues = ["\(displayID)" as String,
                            display[1],             // redMin
                            display[2] as! Float,   // redMax
                            display[3],             // redGamma
                            display[4],             // greenMin
                            display[5] as! Float,   // greenMax
                            display[6],             // greenGamma
                            display[7],             // blueMin
                            display[8] as! Float,   // blueMax
                            display[9]]
                        
                        break
                    }
                }
                
                // Allocate memory for gamma values
                let redMin = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let redMax = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let redGamma = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let greenMin = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let greenMax = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let greenGamma = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let blueMin = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let blueMax = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                let blueGamma = UnsafeMutablePointer<CGGammaValue>.alloc(1)
                
                redMin.initialize(0);
                redMax.initialize(0);
                redGamma.initialize(0);
                greenMin.initialize(0);
                greenMax.initialize(0);
                greenGamma.initialize(0);
                blueMin.initialize(0);
                blueMax.initialize(0);
                blueGamma.initialize(0);
                
                CGGetDisplayTransferByFormula(displayID,
                    redMin,     // redMin
                    redMax,     // redMax
                    redGamma,   // redGamma
                    greenMin,   // greenMin
                    greenMax,   // greenMax
                    greenGamma, // greenGamma
                    blueMin,    // blueMin
                    blueMax,    // blueMax
                    blueGamma)  // blueGamma
                
                if inArray == false {
                    
                    gammaValues = ["\(displayID)" as String,
                        redMin.memory as Float,     // redMin
                        redMax.memory as Float,     // redMax
                        redGamma.memory as Float,   // redGamma
                        greenMin.memory as Float,   // greenMin
                        greenMax.memory as Float,   // greenMax
                        greenGamma.memory as Float, // greenGamma
                        blueMin.memory as Float,    // blueMin
                        blueMax.memory as Float,    // blueMax
                        blueGamma.memory as Float]
                    
                    gammaArray.insert(gammaValues,atIndex:0)
                }
                
                let difference:Float = ((gammaValues[2] as! Float)-percent) - redMax.memory as Float
                
                print("\(lastAppliedBrightness) \(globalBrightness) \(steps)")
                
                if( lastAppliedBrightness != globalBrightness ){ // Animate only when the brigtness change
                    steps = 8 // Frames per 250 milliseconds
                }else{
                    steps = 1
                }
                lastAppliedBrightness = globalBrightness
                
                var step:Int = 0
                let sleep:useconds_t = useconds_t((250*1000)/steps);
                
                if( difference != 0.0 ){
                    
                    let currentBrightnessToken = "\(NSDate().timeIntervalSince1970 * 1000)"
                    brightnessToken = currentBrightnessToken
                    
                    for (step = 0; step <= steps; step++){
                        
                        if( currentBrightnessToken != brightnessToken ){
                            break
                        }
                        
                        let fade:Float = (difference/Float(steps))*Float(step)
                        
                        CGSetDisplayTransferByFormula( displayID,
                            gammaValues[1] as! CGGammaValue,        // redMin
                            (redMax.memory+fade) as CGGammaValue,   // redMax
                            gammaValues[3] as! CGGammaValue,        // redGamma
                            gammaValues[4] as! CGGammaValue,        // greenMin
                            (greenMax.memory+fade) as CGGammaValue, // greenMax
                            gammaValues[6] as! CGGammaValue,        // greenGamma
                            gammaValues[7] as! CGGammaValue,        // blueMin
                            (blueMax.memory+fade) as CGGammaValue,  // blueMax
                            gammaValues[9] as! CGGammaValue)        // blueGamma
                        
                        usleep(sleep)
                    }
                }
                
                // Deallocate memory for gamma values
                
                redMin.destroy()
                redMax.destroy()
                redGamma.destroy()
                greenMin.destroy()
                greenMax.destroy()
                greenGamma.destroy()
                blueMin.destroy()
                blueMax.destroy()
                blueGamma.destroy()
                
                redMin.dealloc(1)
                redMax.dealloc(1)
                redGamma.dealloc(1)
                greenMin.dealloc(1)
                greenMax.dealloc(1)
                greenGamma.dealloc(1)
                blueMin.dealloc(1)
                blueMax.dealloc(1)
                blueGamma.dealloc(1)
                
            }
        }
        activeDisplays.dealloc(allocated)
        
    }
    
    func getBrightness(){
        
        // Lets detect that brightness level
        let systemBrightness = run("ioreg -c AppleBacklightDisplay | grep brightness").read()
        
        let chunkStart = systemBrightness.rangeOfString("brightness\"={\"max\"=")
        let chunkEnd = systemBrightness.endIndex
        
        if( chunkStart != nil ){
            
            let firstChunkRange = Range(
                start: (chunkStart!.endIndex.advancedBy(0)),
                end: chunkEnd)
            let firstChunk = systemBrightness.substringWithRange(firstChunkRange)
            
            //println(firstChunk)
            
            let maxChunkRange = Range(
                start: firstChunk.startIndex,
                end: firstChunk.rangeOfString(",")!.startIndex)
            let maxBrightness = Int(firstChunk.substringWithRange(maxChunkRange))!
            
            let chunkStart = firstChunk.rangeOfString(",\"value\"=")
            let chunkEnd = firstChunk.rangeOfString("}")
            
            if( chunkStart != nil ){
                
                let secondChunkRange = Range(
                    start: (chunkStart!.endIndex.advancedBy(0)),
                    end: chunkEnd!.startIndex)
                let secondChunk = Int(firstChunk.substringWithRange(secondChunkRange))!
                
                var result:Float = Float(secondChunk)/Float(maxBrightness)
                
                var gap = 1.0-result
                    gap = gap*brigtnessSlider.floatValue
                
                    result = 1.0-gap;
                
                indicatorButton.title = "Brightness: \(Int(round(result*100)))%"
                
                globalBrightness = result
                
            }else{
                indicatorButton.title = TXT_looking_for_light_sensor
                globalBrightness = 1.0
            }
            
            
        }else{
            indicatorButton.title = TXT_looking_for_light_sensor
            globalBrightness = 1.0
        }
    }
    
    func quit(sender: NSMenuItem) {
        
        // Remove from login items
        StartupLaunch.setLaunchOnLogin(false)
        
        interval!.invalidate()
        interval = nil
        
        if( globalBrightness != 1.0 ){
            // Reset  brightness
            globalBrightness = 1.0
            // Set brightness instantly
            setBrightness()
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                // Terminate the application
                CGDisplayRestoreColorSyncSettings()
                NSApplication.sharedApplication().terminate(self)
            }
        }else{
            // Terminate the application
            NSApplication.sharedApplication().terminate(self)
        }
        
    }
    
    func startInterval(){
        
        interval = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "setBrightness", userInfo: nil, repeats: true)
        toggleButton.title = TXT_turn_darken_off
        
        let icon = NSImage(named: "statusIcon")
        icon?.template = true
        statusItem.image = icon
        
        // Set brightness instantly
        setBrightness()
    }
    
    func applicationDidChangeScreenParameters(notification: NSNotification) {
        
        // Screen config changed
        print("Screen config changed")
        
        // Set brightness instantly
        setBrightness()
    }
    
    func toggleState(sender: NSMenuItem) {
        
        toggleState = "0"
        
        if( interval != nil ){
            toggleButton.title = TXT_turn_darken_on
            //CGDisplayRestoreColorSyncSettings()
            
            interval!.invalidate()
            interval = nil
            
            globalBrightness = 1.0
            // Set brightness instantly
            setBrightness()
            
            let icon = NSImage(named: "statusIconOFF")
            icon?.template = true
            statusItem.image = icon
        }else{
            toggleState = "1"
            startInterval()
        }
        
        // Store the current state of the application (on/off) into the user prefs
        NSUserDefaults.standardUserDefaults().setObject(toggleState, forKey: "state")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}