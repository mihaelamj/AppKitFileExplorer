//
//  FileExplorerWindowController.swift
//  FileExplorer
//
//  Created by Mihaela MJ on 25.03.2025..
//

import Foundation
import Cocoa

class FileExplorerWindowController: NSWindowController {
    
    // MARK: - UI Elements
    private var outlineView: NSOutlineView!
    private var pathLabel: NSTextField!
    private var backButton: NSButton!
    private var forwardButton: NSButton!
    private var upButton: NSButton!
    private var scrollView: NSScrollView!
    
    // MARK: - Model
    var rootItems: [FileItem] = []
    private var navigationHistory: [URL] = []
    private var navigationIndex: Int = -1
    
    // MARK: - Initialization
    override init(window: NSWindow?) {
        super.init(window: nil)
        
        // Create window
        let contentRect = NSRect(x: 0, y: 0, width: 900, height: 600)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        window.title = "File Explorer"
        window.center()
        
        self.window = window
        setupUI()
        
        // Initial directory (home directory)
        navigateToDirectory(FileManager.default.homeDirectoryForCurrentUser)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        guard let window = self.window else { return }
        
        // Create container view
        let containerView = NSView(frame: window.contentView!.bounds)
        containerView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(containerView)
        
        // Navigation buttons
        let navigationBar = NSView(frame: NSRect(x: 0, y: containerView.frame.height - 40, width: containerView.frame.width, height: 40))
        navigationBar.autoresizingMask = [.width, .minYMargin]
        containerView.addSubview(navigationBar)
        
        // Back button
        backButton = NSButton(frame: NSRect(x: 10, y: 8, width: 24, height: 24))
        backButton.bezelStyle = .texturedRounded
        if let image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back") {
            backButton.image = image
        } else {
            backButton.title = "←"
        }
        backButton.target = self
        backButton.action = #selector(goBack(_:))
        backButton.isEnabled = false
        navigationBar.addSubview(backButton)
        
        // Forward button
        forwardButton = NSButton(frame: NSRect(x: 44, y: 8, width: 24, height: 24))
        forwardButton.bezelStyle = .texturedRounded
        if let image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Forward") {
            forwardButton.image = image
        } else {
            forwardButton.title = "→"
        }
        forwardButton.target = self
        forwardButton.action = #selector(goForward(_:))
        forwardButton.isEnabled = false
        navigationBar.addSubview(forwardButton)
        
        // Up button
        upButton = NSButton(frame: NSRect(x: 78, y: 8, width: 24, height: 24))
        upButton.bezelStyle = .texturedRounded
        if let image = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: "Up") {
            upButton.image = image
        } else {
            upButton.title = "↑"
        }
        upButton.target = self
        upButton.action = #selector(goUp(_:))
        navigationBar.addSubview(upButton)
        
        // Path label
        pathLabel = NSTextField(frame: NSRect(x: 112, y: 8, width: navigationBar.frame.width - 122, height: 24))
        pathLabel.isEditable = false
        pathLabel.isBordered = true
        pathLabel.isSelectable = true
        pathLabel.backgroundColor = NSColor.textBackgroundColor
        pathLabel.autoresizingMask = [.width]
        navigationBar.addSubview(pathLabel)
        
        // Create outline view
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: containerView.frame.width, height: containerView.frame.height - 40))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        containerView.addSubview(scrollView)
        
        outlineView = NSOutlineView()
        outlineView.headerView = NSTableHeaderView()
        outlineView.allowsColumnReordering = true
        outlineView.allowsColumnResizing = true
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.usesAlternatingRowBackgroundColors = true
        outlineView.style = .sourceList
        outlineView.rowHeight = 20
        outlineView.rowSizeStyle = .default
        
        // Column: Name
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "Name"
        nameColumn.minWidth = 200
        nameColumn.width = 300
        nameColumn.maxWidth = 800
        nameColumn.isEditable = false
        outlineView.addTableColumn(nameColumn)
        
        // Column: Size
        let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SizeColumn"))
        sizeColumn.title = "Size"
        sizeColumn.minWidth = 80
        sizeColumn.width = 100
        sizeColumn.maxWidth = 200
        sizeColumn.isEditable = false
        outlineView.addTableColumn(sizeColumn)
        
        // Column: Date Modified
        let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DateColumn"))
        dateColumn.title = "Date Modified"
        dateColumn.minWidth = 120
        dateColumn.width = 180
        dateColumn.maxWidth = 300
        dateColumn.isEditable = false
        outlineView.addTableColumn(dateColumn)
        
        outlineView.outlineTableColumn = nameColumn
        
        // Set data source and delegate
        outlineView.dataSource = self
        outlineView.delegate = self
        
        // Add outline view to scroll view
        scrollView.documentView = outlineView
        
        // Double-click handler
        outlineView.doubleAction = #selector(handleDoubleClick(_:))
    }
    
    // MARK: - Navigation
    func navigateToDirectory(_ url: URL) {
        // Update navigation history
        if navigationIndex < navigationHistory.count - 1 {
            navigationHistory.removeSubrange((navigationIndex + 1)...)
        }
        navigationHistory.append(url)
        navigationIndex = navigationHistory.count - 1
        
        // Update UI state
        backButton.isEnabled = navigationIndex > 0
        forwardButton.isEnabled = false
        pathLabel.stringValue = url.path
        
        // Load directory contents
        loadDirectory(url)
    }
    
    func loadDirectory(_ url: URL) {
        do {
            rootItems.removeAll()
            
            // Get directory contents
            let fileManager = FileManager.default
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey, .fileSizeKey, .contentModificationDateKey]
            let directoryContents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: resourceKeys, options: [])
            
            // Create file items
            for fileURL in directoryContents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let isDirectory = try fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
                let isAppBundle = fileURL.pathExtension == "app"
                
                // Create file item
                let fileItem = FileItem(url: fileURL, isDirectory: isDirectory, isAppBundle: isAppBundle)
                rootItems.append(fileItem)
                
                // Pre-load child items for app bundles
                if isAppBundle {
                    loadAppBundleContents(fileItem)
                }
            }
            
            // Reload data
            outlineView.reloadData()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error loading directory"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    func loadAppBundleContents(_ appItem: FileItem) {
        do {
            let fileManager = FileManager.default
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey, .fileSizeKey, .contentModificationDateKey]
            let bundleContents = try fileManager.contentsOfDirectory(at: appItem.url, includingPropertiesForKeys: resourceKeys, options: [])
            
            for fileURL in bundleContents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let isDirectory = try fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
                let isAppBundle = fileURL.pathExtension == "app"
                
                let fileItem = FileItem(url: fileURL, isDirectory: isDirectory, isAppBundle: isAppBundle)
                appItem.children.append(fileItem)
            }
        } catch {
            print("Error loading app bundle contents: \(error.localizedDescription)")
        }
    }
    
    // Lazy loading of directory contents
    func loadChildItems(_ fileItem: FileItem) {
        do {
            fileItem.children.removeAll()
            
            let fileManager = FileManager.default
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey, .fileSizeKey, .contentModificationDateKey]
            let directoryContents = try fileManager.contentsOfDirectory(at: fileItem.url, includingPropertiesForKeys: resourceKeys, options: [])
            
            for fileURL in directoryContents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let isDirectory = try fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
                let isAppBundle = fileURL.pathExtension == "app"
                
                let childItem = FileItem(url: fileURL, isDirectory: isDirectory, isAppBundle: isAppBundle)
                fileItem.children.append(childItem)
            }
            
            fileItem.childrenLoaded = true
        } catch {
            print("Error loading directory contents: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Actions
    @objc func goBack(_ sender: Any) {
        if navigationIndex > 0 {
            navigationIndex -= 1
            backButton.isEnabled = navigationIndex > 0
            forwardButton.isEnabled = true
            
            pathLabel.stringValue = navigationHistory[navigationIndex].path
            loadDirectory(navigationHistory[navigationIndex])
        }
    }
    
    @objc func goForward(_ sender: Any) {
        if navigationIndex < navigationHistory.count - 1 {
            navigationIndex += 1
            backButton.isEnabled = navigationIndex > 0
            forwardButton.isEnabled = navigationIndex < navigationHistory.count - 1
            
            pathLabel.stringValue = navigationHistory[navigationIndex].path
            loadDirectory(navigationHistory[navigationIndex])
        }
    }
    
    @objc func goUp(_ sender: Any) {
        let currentURL = navigationHistory[navigationIndex]
        let parentURL = currentURL.deletingLastPathComponent().standardized
        if parentURL.path != currentURL.path {
            navigateToDirectory(parentURL)
        }
    }
    
    @objc func handleDoubleClick(_ sender: Any) {
        let clickedRow = outlineView.clickedRow
        if clickedRow != -1, let item = outlineView.item(atRow: clickedRow) as? FileItem {
            if item.isDirectory || item.isAppBundle {
                navigateToDirectory(item.url)
            } else {
                // Open the file with default application
                NSWorkspace.shared.open(item.url)
            }
        }
    }
}
