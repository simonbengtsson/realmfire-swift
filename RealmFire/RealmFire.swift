import Foundation
import RealmSwift
import Firebase

enum RealmFireError {
    case realmError(realmError: Error)
    case firebaseSyncError(firebaseError: Error)
    case firebaseMalformedResult
    case objectDependenciesMissing(deps: [(primaryKey: String, type: SyncObject.Type)])
    case realmUnsupportedValue(object: Object, property: String, description: String)
}

public class RealmFire {
    private init() {}
    
    static var metaHandler = MetaHandler()
    
    // Closure that will be called when errors happens
    internal static var errorHandler: ((_ error: RealmFireError) -> Void)! = { error in
        print(error)
    }
    
    internal static func reportError(_ err: RealmFireError) {
        errorHandler(err)
    }
    
    static var error: RealmFireError!
    
    static public func sync(realm: Realm? = nil, database: Database? = nil) {
        let syncer = Syncer(realm: realm, database: database)
        syncer.fetchUpdatedObjects()
        syncer.uploadModifiedObjects()
    }
    
    static public func markForSync<S: Sequence>(_ objects: S)  where S.Iterator.Element: SyncObject {
        for obj in objects {
            markForSync(obj)
        }
    }
    
    // Adds object to deletion queue. It will be deleted during the next sync cycle.
    static public func markForDeletion(_ object: SyncObject) {
        guard let realm = object.realm else {
            fatalError("RealmFire.markForDeletion() has to be called on a managed SyncObject")
        }
        guard realm.isInWriteTransaction else {
            fatalError("RealmFire.markForDeletion has to be called in a write transaction")
        }
        if object.isInvalidated {
            fatalError("RealmFire.markForDeletion() has to be called before object is deleted")
        }
        metaHandler.addDeletedObject(key: object.key(), className: type(of: object).className(), realm: realm)
    }
    
    /// Adds object to sync queue. It will be updated during the next sync cycle.
    static public func markForSync(_ object: SyncObject) {
        guard let realm = object.realm else {
            fatalError("RealmFire.markForSync has to be called on a managed SyncObject")
        }
        guard realm.isInWriteTransaction else {
            fatalError("RealmFire.markForSync has to be called in a write transaction")
        }
        metaHandler.addUpdatedObject(object, realm: realm)
    }
    
    static func mapDate(encode: @escaping (_ date: Date) -> Any?, decode: @escaping (_ value: Any) -> Date?) {
        Mapper.customDateDecoder = decode
        Mapper.customDateEncoder = encode
    }
    
    static func setErrorHandler(_ handler: @escaping ((_ error: RealmFireError) -> Void)) {
        self.errorHandler = handler
    }
    
    public static func uid() -> String {
        // This should only happen one time and only if realm is initialized before firebase.
        // if false { return "" } todo
        // Should not matter which firebase database or path that is used
        let ref = Database.database().reference(withPath: "realmfire")
        return ref.childByAutoId().key ?? ""
    }
}
