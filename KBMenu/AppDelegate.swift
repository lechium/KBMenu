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
    var statusItem = NSStatusBar.system.statusItem(withLength: 30)
    var events: SCEvents = SCEvents()
    //just add @IBAction prefix to get IB to recognize and make connections
    @IBAction func cancel(_ sender : AnyObject){
        
        window.close()
    }
    
    @IBAction func ok(_ sender : AnyObject){
        
        addBookmark()
        window.close()
    }
    
    //don't forget to override superclass functions!
    override func awakeFromNib()
    {
        statusItem.highlightMode = true
        // installMenuItems()
        createMenuItems()
        NSApp.activate(ignoringOtherApps: true)
        setupEventListener()
    }
    
    func setupEventListener() {
        
        events._delegate = self
        let paths = [applicationSupportFolder()]
        events.startWatchingPaths(paths)
    }
    
    //the bridging between obj-c and swift is brilliant, autocomplete will change the
    //function name to be the swift variant based on subscribing to the protocol
    
    func pathWatcher(_ pathWatcher: SCEvents!, eventOccurred event: SCEvent!)
    {
        print("event occured!!")
        createMenuItems()
    }
    
    @objc func openLocation(_ sender : AnyObject) {
        
        let tag: Int = sender.tag
        let menuItem = self.menuBackingStore()[tag] as! String
        let fileItem = (applicationSupportFolder() as NSString).appendingPathComponent(menuItem)
        NSWorkspace.shared.openFile(fileItem)
        
    }
    
    
    func imageForFile(_ file: String) -> NSImage
    {
        
        /*
        
        not a fan of this, the old obj-c version would do this [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kComputerIcon)]
        but i couldnt find anything equivalent, or how to create OSTypes properly in swift natively
        so just using the four char values as strings, essentially thats all the obj-c version of this does
        take those 'root' values and make them into strings.
        
        */
        let ws = NSWorkspace.shared
        var fileImage: NSImage// = ws.iconForFileType(NSFileTypeForHFSTypeCode(kComputerIcon))
        let pathExtension: String = (file as NSString).pathExtension
        if pathExtension == "inetloc" {
            fileImage = ws.icon(forFileType: "\'root\'")
        } else if pathExtension == "afploc" {
            fileImage = ws.icon(forFileType: "\'srvr\'")
        } else {
            fileImage = ws.icon(forFileType: "\'srvr\'")
        }
        return fileImage
    }
    
    func createMenuItems()
    {
        let menuArray = menuBackingStore()
        let menu = NSMenu()
        var tag = 0
        for menuItem : AnyObject in menuArray
        {
            if menuItem as! String != ".DS_Store"
            {
                let newMenuItem = NSMenuItem(title:  menuItem.deletingPathExtension, action: #selector(AppDelegate.openLocation(_:)), keyEquivalent:"")
                newMenuItem.target = self
                newMenuItem.tag = tag
                let fileItem = (applicationSupportFolder() as NSString).appendingPathComponent(menuItem as! String)
                let newImage = imageForFile(fileItem)
                newMenuItem.image = newImage;
                menu.addItem(newMenuItem)
            }
            tag += 1
            
        }
        menu.addItem(NSMenuItem.separator())
        let addBm = NSMenuItem(title: "Add Bookmark", action: #selector(AppDelegate.showBookmarkWindow), keyEquivalent: "")
        let appSupport = NSMenuItem(title: "Show Bookmark Folder", action: #selector(AppDelegate.showAppSupport), keyEquivalent: "")
        let quit = NSMenuItem(title: "Quit", action: #selector(AppDelegate.quitApp), keyEquivalent: "")
        menu.addItem(addBm)
        menu.addItem(appSupport)
        menu.addItem(quit)
        let networkImage = NSImage(named:"network.png")
        statusItem.image = networkImage;
        statusItem.menu = menu
    }
    
    @objc func quitApp()
    {
        exit(0)
    }
    
    @objc func showBookmarkWindow()
    {
        window.makeKeyAndOrderFront(nil)
        //couldnt find equivalent to [window setLevel:NSStatusWindowLevel];
        window.level = convertToNSWindowLevel(25)
    }
    
    
    @objc func showAppSupport()
    {
        NSWorkspace.shared.openFile(applicationSupportFolder())
    }
    
    func menuBackingStore() -> [AnyObject]
    {
        let items = try? FileManager.default.contentsOfDirectory(atPath: applicationSupportFolder())
        return items! as [AnyObject]
        
    }
    
    
    func addBookmark()
    {
        let urlValue: String = locationField.stringValue
        let newDict: NSDictionary = ["URL": locationField.stringValue]
        var newFile = (applicationSupportFolder() as NSString).appendingPathComponent(nameField.stringValue)
        if (urlValue.range(of: "afp") != nil) {
            newFile = (newFile as NSString).appendingPathExtension("afploc")!
        } else if( urlValue.range(of: "vnc") != nil) {
            newFile = (newFile as NSString).appendingPathExtension("inetloc")!
        } else if (urlValue.range(of: "smb") != nil) {
            newFile = (newFile as NSString).appendingPathExtension("inetloc")!
        } else if (urlValue.range(of: "ftp") != nil) {
            newFile = (newFile as NSString).appendingPathExtension("ftploc")!
        } else {
            print("invalid bookmark!!")
        }
        newDict.write(toFile: newFile, atomically: true)
        createMenuItems()
    }
    
    func applicationSupportFolder() -> String
    {
        var documentsPaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0] 
        documentsPaths = documentsPaths + "/KBMenu" //just playing around with diff string concat paradigm. this could obviously still be done with stringByAppendingPathComponent
        let man = FileManager.default
        if man.fileExists(atPath: documentsPaths) == false
        {
            do {
                try man.createDirectory(atPath: documentsPaths, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            };
            //man.createDirectoryAtPath(documentsPaths, attributes: nil)
        }
        return documentsPaths
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
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
    
    func applicationWillTerminate(_ notification: Notification) {
        
        
    }
    
    
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSWindowLevel(_ input: Int) -> NSWindow.Level {
	return NSWindow.Level(rawValue: input)
}
