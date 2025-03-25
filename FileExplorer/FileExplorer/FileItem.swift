//
//  FileItem.swift
//  FileExplorer
//
//  Created by Mihaela MJ on 25.03.2025..
//

import Foundation

// MARK: - FileItem Model
class FileItem: NSObject {
    let url: URL
    let name: String
    let isDirectory: Bool
    let isAppBundle: Bool
    let size: Int64
    let modificationDate: Date?
    
    var children: [FileItem] = []
    var childrenLoaded: Bool = false
    
    var sizeString: String {
        if isDirectory {
            return "--"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var dateString: String {
        guard let date = modificationDate else { return "--" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    init(url: URL, isDirectory: Bool, isAppBundle: Bool) {
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.isAppBundle = isAppBundle
        
        // Get file size and modification date
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            self.size = attributes[.size] as? Int64 ?? 0
            self.modificationDate = attributes[.modificationDate] as? Date
        } catch {
            self.size = 0
            self.modificationDate = nil
        }
        
        super.init()
    }
}
