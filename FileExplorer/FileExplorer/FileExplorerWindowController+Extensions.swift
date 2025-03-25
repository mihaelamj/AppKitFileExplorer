//
//  Extensions.swift
//  FileExplorer
//
//  Created by Mihaela MJ on 25.03.2025..
//

import Foundation
import Cocoa
import UniformTypeIdentifiers

// MARK: - NSOutlineViewDataSource
extension FileExplorerWindowController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return rootItems.count
        }
        
        if let fileItem = item as? FileItem {
            // Lazy loading of directory contents
            if fileItem.isDirectory && !fileItem.childrenLoaded {
                loadChildItems(fileItem)
            }
            return fileItem.children.count
        }
        
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return rootItems[index]
        }
        
        if let fileItem = item as? FileItem {
            return fileItem.children[index]
        }
        
        return NSNull()
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let fileItem = item as? FileItem {
            return fileItem.isDirectory || fileItem.isAppBundle
        }
        return false
    }
}

// MARK: - NSOutlineViewDelegate
extension FileExplorerWindowController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        
        let identifier = tableColumn.identifier
        let cellIdentifier: NSUserInterfaceItemIdentifier
        
        if identifier.rawValue == "NameColumn" {
            cellIdentifier = NSUserInterfaceItemIdentifier("NameCell")
        } else if identifier.rawValue == "SizeColumn" {
            cellIdentifier = NSUserInterfaceItemIdentifier("SizeCell")
        } else {
            cellIdentifier = NSUserInterfaceItemIdentifier("DateCell")
        }
        
        // Create or reuse cell view
        var cellView = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
        
        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.isEditable = false
            textField.isSelectable = true
            textField.isBordered = false
            textField.drawsBackground = false
            
            cellView?.addSubview(textField)
            cellView?.textField = textField
            
            // Add constraints
            if identifier.rawValue == "NameColumn" {
                let imageView = NSImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                cellView?.addSubview(imageView)
                cellView?.imageView = imageView
                
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 2),
                    imageView.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 16),
                    imageView.heightAnchor.constraint(equalToConstant: 16),
                    
                    textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
                ])
            }
        }
        
        

        if let fileItem = item as? FileItem {
            switch identifier.rawValue {
            case "NameColumn":
                cellView?.textField?.stringValue = fileItem.name

                if fileItem.isAppBundle {
                    // App icon from bundle path
                    cellView?.imageView?.image = NSWorkspace.shared.icon(forFile: fileItem.url.path)

                } else if fileItem.isDirectory {
                    // Generic folder icon using UTType
                    let folderType = UTType.folder
                    let folderIcon = NSWorkspace.shared.icon(for: folderType)
                    cellView?.imageView?.image = folderIcon

                } else {
                    // Default file icon
                    cellView?.imageView?.image = NSWorkspace.shared.icon(forFile: fileItem.url.path)
                }

            case "SizeColumn":
                cellView?.textField?.stringValue = fileItem.sizeString

            case "DateColumn":
                cellView?.textField?.stringValue = fileItem.dateString

            default:
                break
            }
        }

        return cellView
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        // We handle navigation in double-click handler instead
    }
}
