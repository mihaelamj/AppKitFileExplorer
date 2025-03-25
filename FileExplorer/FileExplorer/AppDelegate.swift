//
//  AppDelegate.swift
//  FileExplorer
//
//  Created by Mihaela MJ on 25.03.2025..
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: FileExplorerWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create window controller
        windowController = FileExplorerWindowController()
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up if needed
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// How to use the File Explorer

// How to build and run the macOS File Explorer

// 1. Create a new Xcode project
// Choose macOS -> App template
// Name it "FileExplorer"
// Choose Swift as the language

// 2. Replace the contents of your AppDelegate.swift file with the code from the artifact

// 3. Create a new Swift file called "FileExplorerWindowController.swift"
// and paste the FileExplorerWindowController class from the artifact

// 4. Create a new Swift file called "FileItem.swift"
// and paste the FileItem class from the artifact

// 5. Build and run your application

// Key Features:
// - Navigate through directories using back/forward/up buttons
// - Browse app bundles (shows app contents)
// - Double-click to open files or navigate into directories
// - Displays file size and modification date
// - Shows appropriate icons for files and folders

// Notes:
// - The UI is built entirely in code (no Interface Builder/XIB files)
// - The app uses a Model-View-Controller architecture
// - The FileItem class handles file system metadata
// - The FileExplorerWindowController manages the UI and navigation
