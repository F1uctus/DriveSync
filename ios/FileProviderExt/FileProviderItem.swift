import FileProvider
import UniformTypeIdentifiers

class FileProviderItem: NSObject, NSFileProviderItem {
    
    var itemIdentifier: NSFileProviderItemIdentifier
    var filename: String
    var typeIdentifier: String
    var capabilities: NSFileProviderItemCapabilities
    
    init(identifier: NSFileProviderItemIdentifier, filename: String) {
        self.itemIdentifier = identifier
        self.filename = filename
        self.typeIdentifier = UTType.data.identifier
        self.capabilities = [.allowsReading, .allowsWriting, .allowsRenaming, .allowsDeleting]
        super.init()
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        return .rootContainer
    }
    
    var documentSize: NSNumber? {
        return nil
    }
    
    var childItemCount: NSNumber? {
        return nil
    }
    
    var contentModificationDate: Date? {
        return Date()
    }
    
    var creationDate: Date? {
        return Date()
    }
}

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    private let enumeratedItemIdentifier: NSFileProviderItemIdentifier
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }
    
    func invalidate() {
        // Invalidate enumerator
    }
    
    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        // Return items from shared app group storage
        // Minimal implementation: return empty list
        observer.finishEnumerating(upTo: nil)
    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from syncAnchor: NSFileProviderSyncAnchor) {
        // Return changes since last sync
        observer.finishEnumeratingChanges(upTo: NSFileProviderSyncAnchor("current".data(using: .utf8)!), moreComing: false)
    }
    
    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(NSFileProviderSyncAnchor("current".data(using: .utf8)!))
    }
}

