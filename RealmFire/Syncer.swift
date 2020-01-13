import Foundation
import Firebase
import RealmSwift

class Syncer {
    var metaHandler: MetaHandler
    var config: Realm.Configuration
    var database: Database
    
    init(realm: Realm?, database: Database?) {
        self.metaHandler = MetaHandler()
        self.database = database ?? Database.database()
        self.config = realm?.configuration ?? Realm.Configuration.defaultConfiguration
    }
    
    func fetchUpdatedObjects() {
        var results: [String: (data: [String: Any], type: SyncObject.Type)] = [:]
        let fetchTime = Date()
        
        var requestsLeft = TypeHandler.syncTypes.count
        let complete = {
            guard requestsLeft == 0 else {
                requestsLeft -= 1
                return
            }
            guard let realm = self.realmobj() else { return }
            
            realm.beginWrite()
            let incompleteObjects = self.assignResults(results, realm: realm, fetchTime: fetchTime)
            
            if incompleteObjects.count == 0 {
                try! realm.commitWrite()
            } else {
                realm.cancelWrite()
                let deps = incompleteObjects.map { (primaryKey: $0.key, type: $0.value) }
                RealmFire.reportError(.objectDependenciesMissing(deps: deps))
                
                for (key, _) in incompleteObjects {
                    let _ = results.removeValue(forKey: key)
                }
                // Try assigning data again without the incomplete objects
                self.write {
                    let _ = self.assignResults(results, realm: realm, fetchTime: fetchTime)
                }
            }
        }
        
        guard let realm = realmobj() else { return }
        for (_, type) in TypeHandler.syncTypes {
            let lastFetch = metaHandler.getLastFetchedAt(type: type, realm: realm)
            let attr = type.uploadedAtAttribute()
            let query = dbref(forType: type).queryOrdered(byChild: attr).queryStarting(atValue: lastFetch)
            query.observeSingleEvent(of: .value, with: { snapshot in
                if let dataList = snapshot.value as? [String: [String: Any]] {
                    for (key, data) in dataList {
                        results[key] = (data: data, type: type)
                    }
                }
                complete()
            }) { error in
                RealmFire.reportError(.firebaseSyncError(firebaseError: error))
            }
        }
    }
    
    func assignResults(_ results: [String: (data: [String: Any], type: SyncObject.Type)], realm: Realm, fetchTime: Date) -> [String: SyncObject.Type] {
        var incompleteObjects = [String: SyncObject.Type]()
        for (key, (data: var data, type: type)) in results {
            let mapper = Mapper(realm: realm)
            data[type.primaryKey()!] = key
            let object = mapper.decode(dataObjectValue: data, type: type)
            if let object = object {
                realm.add(object, update: .all)
            } else {
                RealmFire.reportError(.firebaseMalformedResult)
            }
            print("Fetched \(type.className()) with key: \(key)")
            
            if mapper.incompleteObjects.count > 0 {
                incompleteObjects[key] = type
                for (key, type) in mapper.incompleteObjects {
                    incompleteObjects[key] = type
                }
            }
            
            incompleteObjects.removeValue(forKey: key)
            
            self.metaHandler.setLastFetchedAt(for: type, date: fetchTime, realm: realm)
        }
        return incompleteObjects
    }
    
    func uploadModifiedObjects() {
        guard let realm = realmobj() else { return }
        
        let modified = metaHandler.allUpdatedObjects(realm: realm)
        for meta in modified {
            let type = TypeHandler.getSyncType(className: meta.className)
            let object = realm.object(ofType: type, forPrimaryKey: meta.key)!
            let mapper = Mapper(realm: realm)
            var data = mapper.encode(dataObject: object)
            data.removeValue(forKey: type.primaryKey()!)
            data[Swift.type(of: object).uploadedAtAttribute()] = Date().timeIntervalSince1970
            dbref(forType: type, child: object.key()).setValue(data) { error, ref in
                if let error = error {
                    RealmFire.reportError(.firebaseSyncError(firebaseError: error))
                    return
                }
                print("\(type.className()) with key \(object.key()) was uploaded")
                
                self.write {
                    self.metaHandler.removeUpdatedObject(key: meta.key, realm: realm)
                }
            }
        }
    }
    
    func syncDeletedObjects() {
        guard let realm = realmobj() else { return }
        
        for meta in metaHandler.allDeletedObjects(realm: realm) {
            let type = TypeHandler.getSyncType(className: meta.className)
            let ref = database.reference(withPath: type.collectionName()).child(meta.key)
            ref.removeValue() { error, ref in
                if let error = error {
                    RealmFire.reportError(.firebaseSyncError(firebaseError: error))
                    return
                }
                
                print("\(type.collectionName()) with key \(meta.key) was deleted")
                self.write {
                    self.metaHandler.removeDeletedObject(key: meta.key, realm: realm)
                }
            }
        }
    }
    
    // Returns a Firebase database reference for this collection
    private func dbref(forType type: SyncObject.Type, child: String? = nil) -> DatabaseReference {
        let collectionRef = database.reference(withPath: type.collectionName())
        if let child = child {
            return collectionRef.child(child)
        } else {
            return collectionRef
        }
    }
    
    private func realmobj() -> Realm? {
        do {
            return try Realm(configuration: config)
        } catch let err {
            RealmFire.reportError(.firebaseSyncError(firebaseError: err))
            return nil
        }
    }
    
    // Safely opens write transaction and reports any errors to user
    private func write(handler: () throws -> Void) {
        do {
            let realm = try Realm(configuration: config)
            try realm.write {
                try handler()
            }
        } catch let err {
            // Report error to user, but worst thing that can happen if write fails
            // is that models gets refetched
            RealmFire.reportError(.firebaseSyncError(firebaseError: err))
        }
    }
}
