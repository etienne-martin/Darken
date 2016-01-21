//
//  startupLaunch.swift
//  Darken
//
//  Created by Emartin on 2015-09-11.
//  Copyright (c) 2015 etiennemartin.ca. All rights reserved.
//

import Foundation

final class StartupLaunch: NSObject {
    
    class func isAppLoginItem() -> Bool {
        return (itemReferencesInLoginItems().existingReference != nil)
    }
    
    class func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        let itemUrl : UnsafeMutablePointer<Unmanaged<CFURL>?> = UnsafeMutablePointer<Unmanaged<CFURL>?>.alloc(1)
        if let appUrl : NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
            if let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileListRef? {
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                if loginItems.count > 0 {
                    let lastItemRef: LSSharedFileListItemRef = loginItems.lastObject as! LSSharedFileListItemRef
                    for var i = 0; i < loginItems.count; ++i {
                        let currentItemRef: LSSharedFileListItemRef = loginItems.objectAtIndex(i) as! LSSharedFileListItemRef
                        if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
                            if let urlRef: NSURL =  itemUrl.memory?.takeRetainedValue() where urlRef.isEqual(appUrl) {
                                return (currentItemRef, lastItemRef)
                            }
                        }
                    }
                    return (nil, lastItemRef)
                }
                else
                {
                    let addatstart: LSSharedFileListItemRef = kLSSharedFileListItemBeforeFirst.takeRetainedValue()
                    return(nil, addatstart)
                }
            }
        }
        return (nil, nil)
    }
    
    class func setLaunchOnLogin(launch: Bool) {
        let itemReferences = itemReferencesInLoginItems()
        let isSet = (itemReferences.existingReference != nil)
        if let loginItemsRef = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil).takeRetainedValue() as LSSharedFileListRef? {
            if launch && !isSet {
                if let appUrl : CFURLRef = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
                    LSSharedFileListInsertItemURL(loginItemsRef, itemReferences.lastReference, nil, nil, appUrl, nil, nil)
                    print("Trailer was added to login items")
                }
            } else if !launch && isSet {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef)
                    print("Trailer was removed from login items")
                }
            }
        }
    }
    
}