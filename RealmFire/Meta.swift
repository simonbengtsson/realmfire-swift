import Foundation
import RealmSwift

class MetaHandler {
    
    var syncMetaId = "realmfire-syncmeta"
    var deletionMetaId = "realmfire-deletionmeta"
    var collectionMetaId = "realmfire-collectionmeta"
    
    /// CollectionMeta
    
    func setLastFetchedAt(for type: SyncObject.Type, date: Date, realm: Realm) {
        //let obj = RealmFireMeta.find(id: type.className(), type: CollectionMeta.type, realm: realm).first ?? RealmFireMeta()
        let obj = RealmFireMeta.init(data: [:])
        if obj.id.isEmpty {
            obj.id = type.className()
            obj.type = CollectionMeta.type
            realm.add(obj)
        }
        let meta = CollectionMeta(className: type.className(), lastFetched: date.timeIntervalSince1970)
        obj.setData(data: meta.serialized())
    }
    
    func getLastFetchedAt(type: SyncObject.Type, realm: Realm) -> Double {
        //let obj = RealmFireMeta.find(id: type.className(), type: CollectionMeta.type, realm: realm).first
        //return obj?.obtain(CollectionMeta.self).lastFetched ?? 0
        return 0
    }
    
    /// DeletedObjectMeta
    
    func allDeletedObjects(realm: Realm) -> [CollectionMeta] {
        //let objects = RealmFireMeta.find(type: DeletedObjectMeta.type, realm: realm)
        //return objects.map { $0.obtain(DeletedObjectMeta.self) }
        return []
    }
    
    func addDeletedObjects(key: String, className: String, realm: Realm) {
        //let meta = DeletedObjectMeta(key: key, className: className)
        //DeletedObjectMeta.add(meta, realm: realm)
    }
    
    func removeDeletedObject(key: String, realm: Realm) {
        //let object = RealmFireMeta.find(id: key, type: DeletedObjectMeta.type, realm: realm)
        //realm.delete(object)
    }
    
    /// UpdatedObjectMeta
    
    func allUpdatedObjects(realm: Realm) -> [CollectionMeta] {
        //let objects = RealmFireMeta.find(type: UpdatedObjectMeta.type, realm: realm)
        //return objects.map { $0.obtain(DeletedObjectMeta.self) }
        return []
    }
    
    func addUpdatedObjects<S: Sequence>(_ objects: S, realm: Realm) where S.Iterator.Element: SyncObject {
        //let dict = UpdatedObjectMeta(key: key, className: className)
        //objects.forEach { dict[$0.key()] = type(of: $0).className() }
        //UpdatedObjectMeta.add(meta, realm: realm)
    }
    
    func removeUpdatedObject(key: String, realm: Realm) {
        //let object = RealmFireMeta.find(id: key, type: UpdatedObjectMeta.type, realm: realm)
        //realm.delete(object)
    }
    
    func addDeletedObject(key: String, className: String, realm: Realm) {
    }
    
    func addUpdatedObject(_ object: SyncObject, realm: Realm) {
    }
    
}

protocol Meta {
    static var type: String {get}
    init(deserializeWith data: [String: Any])
    func serialized() -> [String: Any]
}

extension Meta {
    static func add(_ object: Meta, id: String? = nil, realm: Realm) {
        //realm.add(RealmFireMeta(data: object.serialized(), type: self.type, id: id ?? ""))
    }
}

class CollectionMeta: Meta {
    static var type = "realmfire-collectionmeta"
    var meta = RealmFireMeta()
    var metas = [String: [String: Any]]() // [className: [prop: value]]
    
    var key = ""
    var lastFetched = 0.0
    var className = ""
    
    init(className: String, lastFetched: Double ) {
        self.lastFetched = lastFetched
        self.className = className
    }
    
    func setLastFetch(for className: String, lastFetched: Date, realm: Realm) {
        metas[className] = ["lastFetched": lastFetched.timeIntervalSince1970]
    }
    
    required init(deserializeWith data: [String: Any]) {
        self.lastFetched = data["lastFetched"] as! Double
        self.className = data["className"] as! String
    }
    
    func serialized() -> [String: Any] {
        return [
            "className": className,
            "lastFetched": lastFetched
        ]
    }
    
    func save() {
        let meta = RealmFireMeta.find(withType: "", realm: try! Realm())
        meta?.setData(data: [
            "className": className,
            "lastFetched": lastFetched
        ])
    }
}

class SyncMeta: Meta {
    static var type = "realmfire-syncmeta"
    
    var id = ""
    var objects = [String: String]() // [key: className]
    
    required init(deserializeWith data: [String: Any]) {
        objects = data["objects"] as! [String: String]
    }
    
    func serialized() -> [String: Any] {
        return ["objects": objects]
    }
}

/// A RealmFireMeta's task is to store and retreive any Meta object
class RealmFireMeta: Object {
    @objc dynamic var id = "" // Not currently used, but included for potensial future use
    @objc dynamic var type = ""
    @objc dynamic var data = Data()
    
    convenience init(data: [String: Any], type: String = "") {
        self.init()
        self.type = type
        setData(data: data)
    }
    
    convenience init(data: Meta, type: String) {
        self.init()
        self.type = type
        setData(data: data.serialized())
    }

    func setData(data: [String: Any]) {
        self.data = NSKeyedArchiver.archivedData(withRootObject: data)
    }
    
    func obtain<T: Meta>(_ type: T.Type) -> T {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: data)
        return type.init(deserializeWith: dict as! [String: Any])
    }
    
    static func find(withType type: String, realm: Realm) -> RealmFireMeta? {
        let res = realm.objects(RealmFireMeta.self).filter("'\(type)' = type")
        return res.first
    }
    
    /*
    static func query(type: String, realm: Realm) -> Results<RealmFireMeta> {
        let res = realm.objects(RealmFireMeta.self).filter("'\(type)' = type")
        // if let id = id { res = res.filter("'\(id)' = id") }
        return res
    }
 */
}
