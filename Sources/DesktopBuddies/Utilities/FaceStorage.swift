import Foundation
import AppKit

/// Utility class to handle user photo uploads, circular cropping, local storage, and caching.
@MainActor
public final class FaceStorage {
    public static let shared = FaceStorage()
    
    private var memoryCache: [String: NSImage] = [:]
    
    private var facesDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DesktopBuddies/Faces", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private init() {}
    
    /// Presents an open file dialog to choose a face photo.
    public func promptUserForPhoto() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose a Face Photo for Your Buddy"
        panel.prompt = "Select Photo"
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic, .tiff, .webP]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        
        // Ensure the open panel comes to the foreground
        NSApp.activate(ignoringOtherApps: true)
        
        let response = panel.runModal()
        return response == .OK ? panel.url : nil
    }
    
    /// Imports a chosen image for a given buddy ID, centers/crops it to a square, and saves it as PNG.
    public func saveFaceImage(from sourceURL: URL, for buddyId: UUID) -> String? {
        guard let sourceImage = NSImage(contentsOf: sourceURL) else { return nil }
        
        let targetSize = CGSize(width: 256, height: 256)
        let croppedImage = cropToSquare(image: sourceImage, targetSize: targetSize)
        
        guard let tiffData = croppedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let destinationURL = facesDirectory.appendingPathComponent("\(buddyId.uuidString).png")
        do {
            try pngData.write(to: destinationURL)
            memoryCache[destinationURL.path] = croppedImage
            return destinationURL.path
        } catch {
            print("Failed to save face image: \(error)")
            return nil
        }
    }
    
    /// Loads an image from the given path, utilizing in-memory caching.
    public func loadImage(at path: String) -> NSImage? {
        if let cached = memoryCache[path] {
            return cached
        }
        if let image = NSImage(contentsOfFile: path) {
            memoryCache[path] = image
            return image
        }
        return nil
    }
    
    /// Deletes stored photo for a buddy.
    public func removeFaceImage(for buddyId: UUID) {
        let url = facesDirectory.appendingPathComponent("\(buddyId.uuidString).png")
        try? FileManager.default.removeItem(at: url)
        memoryCache.removeValue(forKey: url.path)
    }
    
    /// Centers and crops an NSImage into a square of targetSize.
    private func cropToSquare(image: NSImage, targetSize: CGSize) -> NSImage {
        let originalSize = image.size
        let minDimension = min(originalSize.width, originalSize.height)
        guard minDimension > 0 else { return image }
        
        let cropRect = CGRect(
            x: (originalSize.width - minDimension) / 2.0,
            y: (originalSize.height - minDimension) / 2.0,
            width: minDimension,
            height: minDimension
        )
        
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        image.draw(
            in: CGRect(origin: .zero, size: targetSize),
            from: cropRect,
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }
}
