//
//  AppDelegate.swift
//  KBMenu
//
//  Created by Kevin Bradley on 6/23/14.
//  Copyright (c) 2014 Kevin Bradley. All rights reserved.
//

/**

This is my first stab at porting a basic project from objective-c to swift, there may be things that could be done more
efficiently or that i just didn't do "properly" but programming is always wrought with compromises, so if
it gets the job done, who cares? :)


*/


import Cocoa
import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, SCEventListenerProtocol {
    
    //no header files, all our class propertys/ivars are here
    
    @IBOutlet var window: NSWindow!
    @IBOutlet var nameField: NSTextField!
    @IBOutlet var locationField: NSTextField!
    var statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(30)
    var events: SCEvents = SCEvents()
    //just add @IBAction prefix to get IB to recognize and make connections
    @IBAction func cancel(sender : AnyObject){
        
        window.close()
    }
    
    @IBAction func ok(sender : AnyObject){
        
        addBookmark()
        window.close()
    }
    
    //don't forget to override superclass functions!
    override func awakeFromNib()
    {
        statusItem.highlightMode = true
        // installMenuItems()
        createMenuItems()
        NSApp.activateIgnoringOtherApps(true)
        setupEventListener()
    }
    
    func setupEventListener() {
        
        events._delegate = self
        var paths = [applicationSupportFolder()]
        events.startWatchingPaths(paths)
    }
    
    //the bridging between obj-c and swift is brilliant, autocomplete will change the
    //function name to be the swift variant based on subscribing to the protocol
    
    func pathWatcher(pathWatcher: SCEvents!, eventOccurred event: SCEvent!)
    {
        println("event occured!!")
        createMenuItems()
    }
    
    func openLocation(sender : AnyObject) {
        
        var tag: Int = sender.tag()
        var menuItem = self.menuBackingStore()[tag] as String
        var fileItem = applicationSupportFolder().stringByAppendingPathComponent(menuItem)
        NSWorkspace.sharedWorkspace().openFile(fileItem)
        
    }
    
    
    func imageForFile(file: String) -> NSImage
    {
        
        /*
        
        not a fan of this, the old obj-c version would do this [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kComputerIcon)]
        but i couldnt find anything equivalent, or how to create OSTypes properly in swift natively
        so just using the four char values as strings, essentially thats all the obj-c version of this does
        take those 'root' values and make them into strings.
        
        */
        var ws = NSWorkspace.sharedWorkspace()
        var fileImage: NSImage// = ws.iconForFileType(NSFileTypeForHFSTypeCode(kComputerIcon))
        var pathExtension: String = file.pathExtension
        if pathExtension == "inetloc" {
            fileImage = ws.iconForFileType("\'root\'")
        } else if pathExtension == "afploc" {
            fileImage = ws.iconForFileType("\'srvr\'")
        } else {
            fileImage = ws.iconForFileType("\'srvr\'")
        }
        return fileImage
    }
    
    func createMenuItems()
    {
        var menuArray = menuBackingStore()
        var menu = NSMenu()
        var tag = 0
        for menuItem : AnyObject in menuArray
        {
            if menuItem as String != ".DS_Store"
            {
                var newMenuItem = NSMenuItem(title:  menuItem.stringByDeletingPathExtension, action: Selector("openLocation:"), keyEquivalent:"")
                newMenuItem.target = self
                newMenuItem.tag = tag
                var fileItem = applicationSupportFolder().stringByAppendingPathComponent(menuItem as String)
                var newImage = imageForFile(fileItem)
                newMenuItem.image = newImage;
                menu.addItem(newMenuItem)
            }
            tag++
            
        }
        menu.addItem(NSMenuItem.separatorItem())
        var addBm = NSMenuItem(title: "Add Bookmark", action: Selector("showBookmarkWindow"), keyEquivalent: "")
        var appSupport = NSMenuItem(title: "Show Bookmark Folder", action: Selector("showAppSupport"), keyEquivalent: "")
        var quit = NSMenuItem(title: "Quit", action: Selector("quitApp"), keyEquivalent: "")
        menu.addItem(addBm)
        menu.addItem(appSupport)
        menu.addItem(quit)
        var networkImage = NSImage(named:"network.png")
        statusItem.image = networkImage;
        statusItem.menu = menu
    }
    
    func quitApp()
    {
        exit(0)
    }
    
    func showBookmarkWindow()
    {
        window.makeKeyAndOrderFront(nil)
        //couldnt find equivalent to [window setLevel:NSStatusWindowLevel];
        window.level = 25
    }
    
    
    func showAppSupport()
    {
        NSWorkspace.sharedWorkspace().openFile(applicationSupportFolder())
    }
    
    func menuBackingStore() -> [AnyObject]
    {
        var items = NSFileManager.defaultManager().contentsOfDirectoryAtPath(applicationSupportFolder(), error: nil)
        return items!
        
    }
    
    
    func addBookmark()
    {
        var urlValue: String = locationField.stringValue
        var newDict: NSDictionary = ["URL": locationField.stringValue]
        var newFile = applicationSupportFolder().stringByAppendingPathComponent(nameField.stringValue)
        if (urlValue.rangeOfString("afp") != nil) {
            newFile = newFile.stringByAppendingPathExtension("afploc")!
        } else if( urlValue.rangeOfString("vnc") != nil) {
            newFile = newFile.stringByAppendingPathExtension("inetloc")!
        } else if (urlValue.rangeOfString("smb") != nil) {
            newFile = newFile.stringByAppendingPathExtension("inetloc")!
        } else if (urlValue.rangeOfString("ftp") != nil) {
            newFile = newFile.stringByAppendingPathExtension("ftploc")!
        } else {
            println("invalid bookmark!!")
        }
        newDict.writeToFile(newFile, atomically: true)
        createMenuItems()
    }
    
    func applicationSupportFolder() -> String
    {
        var documentsPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0] as String
        documentsPaths = documentsPaths + "/KBMenu" //just playing around with diff string concat paradigm. this could obviously still be done with stringByAppendingPathComponent
        var man = NSFileManager.defaultManager()
        if man.fileExistsAtPath(documentsPaths) == false
        {
            man.createDirectoryAtPath(documentsPaths, withIntermediateDirectories: true, attributes: nil, error: nil);
            //man.createDirectoryAtPath(documentsPaths, attributes: nil)
        }
        return documentsPaths
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        
        // Insert code here to initialize your application
        
        //  return
        /*
        
        my first foray into ANY swift, just wanted to do a basic open panel
        
        var openPanel: NSOpenPanel = NSOpenPanel()
        var filePath: NSURL = NSURL.URLWithString(NSHomeDirectory() + "/Desktop")
        openPanel.directoryURL = filePath
        openPanel.runModal()
        var lastFile: NSString = openPanel.URLs[0].path as NSString
        println(lastFile)
        */
    }
    
    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
    
    
}

