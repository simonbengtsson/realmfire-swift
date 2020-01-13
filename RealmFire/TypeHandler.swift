import Foundation
import RealmSwift

class TypeHandler {
    static var syncTypes = [String: SyncObject.Type]()
    static var dataTypes = [String: DataObject.Type]()
    
    static func getSyncType(className: String) -> SyncObject.Type {
        if let type = syncTypes[className] {
            return type
        } else {
            fatalError("The type \(className) is not managed by RealmFire")
        }
    }
    
    static func getType(className: String) -> DataObject.Type? {
        return dataTypes[className]
    }
    
    static func isSyncType(className: String) -> Bool {
        return syncTypes[className] != nil
    }
    
    static func isDataType(className: String) -> Bool {
        return dataTypes[className] != nil
    }
    
    fileprivate static func addSyncType(className: String, type: SyncObject.Type) {
        syncTypes[className] = type
    }
    
    fileprivate static func addDataType(className: String, type: DataObject.Type) {
        dataTypes[className] = type
    }
}

extension Object {
    /*open override class func initialize() {
        super.initialize()
        guard self.className() != SyncObject.className() else { return }
        
        // Add all classes that should be observed and synced
        //TypeHandler.addSyncType(className: self.className(), type: self)
    }*/
}

extension DataObject {
    /*open override class func initialize() {
        super.initialize()
        guard self.className() != DataObject.className() else { return }
        guard self.className() != SyncObject.className() else { return }
        
        // Add all classes that should be observed and synced
        TypeHandler.addDataType(className: self.className(), type: self)
    }*/
}

extension SyncObject {
    /*open override class func initialize() {
        //super.initialize()
        guard self.className() != SyncObject.className() else { return }
        
        // Add all classes that should be observed and synced
        TypeHandler.addSyncType(className: self.className(), type: self)
        
        validateClass()
    }*/
    
    private class func validateClass() {
        if self.primaryKey() == nil {
            fatalError("primaryKey() has to be overriden by SyncObject subclasses")
        }
        if self.collectionName().isEmpty {
            fatalError("collectionName cannot be empty")
        }
        if self.uploadedAtAttribute().isEmpty {
            fatalError("uploadedAtAttribute cannot be empty")
        }
    }
}
