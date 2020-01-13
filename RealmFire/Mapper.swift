import Foundation
import RealmSwift

class Mapper {
    var realm: Realm
    static var customDateEncoder: ((_ date: Date) -> Any?)?
    static var customDateDecoder: ((_ value: Any) -> Date?)?
    
    // Missing dependencies and objects that did not have all required properties
    var incompleteObjects = [(primaryKey: String, type: SyncObject.Type)]()
    
    var newRelationships = [(primaryKey: String, type: SyncObject.Type)]()
    
    public required init(realm: Realm) {
        self.realm = realm
    }
    
    // --- Date ---
    
    func encode(date: Date?) -> Any? {
        guard let date = date else { return nil }
        if let encoder = type(of: self).customDateEncoder, type(of: self).customDateDecoder != nil {
            return encoder(date)
        }
        return date.timeIntervalSince1970
    }
    
    func decode(dateValue: Any?) -> Date? {
        guard let dateValue = dateValue as? Double else { return nil }
        if let decoder = type(of: self).customDateDecoder, type(of: self).customDateEncoder != nil {
            return decoder(dateValue)
        }
        return Date(timeIntervalSince1970: dateValue)
    }
    
    // --- Data ---
    
    func encode(data: Data?) -> Any? {
        guard let data = data else { return nil }
        return String.init(data: data, encoding: .utf8)
    }
    
    func decode(dataValue: Any?) -> Data? {
        guard let dataValue = dataValue as? String else { return nil }
        return dataValue.data(using: .utf8)
    }
    
    // --- DataObject ---
    
    func encode<T: DataObject>(dataObject object: T) -> [String: Any] {
        let ignored = type(of: object).ignoredSyncProperties()
        let customAttributes = type(of: object).customAttributes()
        var data = [String: Any]()
        for prop in object.objectSchema.properties {
            if ignored.firstIndex(of: prop.name) == nil && !object.encode(prop: prop, result: &data) {
                let attr = customAttributes[prop.name] ?? prop.name
                data[attr] = encode(objectProp: prop, object: object)
            }
        }
        return data
    }
    
    func decode<T: DataObject>(dataObjectValue: Any?, type: T.Type) -> T? {
        let object = type.init()
        let customAttributes = Swift.type(of: object).customAttributes()
        let ignored = type.ignoredSyncProperties()
        for prop in object.objectSchema.properties {
            let data = dataObjectValue as! [String: Any]
            if ignored.firstIndex(of: prop.name) == nil && !object.decode(prop: prop, data: data) {
                let attr = customAttributes[prop.name] ?? prop.name
                let result = decode(objectProp: prop, propValue: data[attr])

                if result == nil && !prop.isOptional {
                    RealmFire.reportError(.firebaseMalformedResult)
                    return nil
                } else if let list = result as? List<DynamicObject> {
                    let dynamicList = object.dynamicList(prop.name)
                    list.forEach { dynamicList.append($0) }
                } else {
                    object[prop.name] = result
                }
            }
        }
        
        return object
    }
    
    // --- List<SyncObject> ---
    
    func encode(syncList: List<DynamicObject>) -> Any? {
        var dict = [String: Bool]()
        for dynamicObject in syncList {
            let obj = unsafeBitCast(dynamicObject, to: SyncObject.self)
            dict[obj.key()] = true
        }
        return dict
    }
    
    func decode(syncListValue: Any?, type: SyncObject.Type) -> [DynamicObject] {
        guard let syncListValue = syncListValue as? [String: Bool] else { return [] }
        var list = [DynamicObject]()
        for (key, _) in syncListValue {
            let obj = decode(syncObjectValue: key, type: type)
            list.append(obj)
        }
        return list
    }
    
    // --- SyncObject ---
    
    func encode(syncObject: SyncObject?) -> Any? {
        guard let syncObject = syncObject else { return nil }
        return syncObject.key()
    }
    
    func decode(syncObjectValue key: String, type: SyncObject.Type) -> DynamicObject {
        if let existing = realm.dynamicObject(ofType: type.className(), forPrimaryKey: key) {
            return existing
        } else {
            incompleteObjects.append((primaryKey: key, type: type))
            let tmp = realm.dynamicCreate(type.className())
            tmp[type.primaryKey()!] = key
            return tmp
        }
    }
    
    // --- List<Object> ---
    
    func encode(list: List<DynamicObject>) -> [Any?] {
        return Array(list.map { self.encode(object: $0) })
    }
    
    func decode(listValue: Any?, className: String) -> [DynamicObject] {
        guard let listValue = listValue as? [[String: Any]] else { return [] }
        var list = [DynamicObject]()
        for item in listValue {
            if let obj = decode(objectValue: item, className: className) {
                list.append(obj)
            }
        }
        return list
    }
    
    // --- Object ---
    
    func encode<T: Object>(object: T?) -> Any? {
        guard let object = object else { return nil }
        var data = [String: Any]()
        for prop in object.objectSchema.properties {
            data[prop.name] = encode(objectProp: prop, object: object)
        }
        return data
    }
    
    public func decode(objectValue: Any?, className: String) -> DynamicObject? {
        guard let objectValue = objectValue as? [String: Any] else { return nil }
        let object = realm.dynamicCreate(className)
        
        for prop in object.objectSchema.properties {
            let result = decode(objectProp: prop, propValue: objectValue[prop.name])
            
            if result == nil && !prop.isOptional {
                RealmFire.reportError(.firebaseMalformedResult)
                return nil
            } else if let list = result as? List<DynamicObject> {
                let dynamicList = object.dynamicList(prop.name)
                list.forEach { dynamicList.append($0) }
            } else {
                object[prop.name] = result
            }
        }
        return object
    }
    
    public func encode(objectProp prop: Property, object: Object) -> Any? {
        var result: Any? = nil
        let value = object[prop.name]
        
        switch prop.type {
        case .int, .bool, .string:
            result = value
        case .double, .float:
            let num = value as! Double
            if !num.isNaN && !num.isInfinite {
                result = value
            } else {
                let msg = "Firebase does not support nan or infinite values"
                RealmFire.reportError(.realmUnsupportedValue(object: object, property: prop.name, description: msg))
            }
        case .date:
            let date = value as? Date
            result = date == nil ? nil : encode(date: date!)
        case .data:
            result = encode(data: value as? Data)
        case .object:
            if TypeHandler.isSyncType(className: prop.objectClassName!) {
                result = encode(syncObject: value as? SyncObject)
            } else {
                result = encode(object: value as? Object)
            }
        case .any, .linkingObjects:
            fatalError("Not supported property type. Create an issue on github if you get this error.")
        }
        
        return result
    }
    
    public func decode(objectProp prop: Property, propValue value: Any?) -> Any? {
        switch prop.type {
        case .int, .bool, .string, .float, .double:
            return value
        case .date:
            return decode(dateValue: value)
        case .data:
            return decode(dataValue: value)
        case .object:
            let type = TypeHandler.getType(className: prop.objectClassName!)
            if let type = type as? SyncObject.Type {
                if let value = value as? String, !value.isEmpty {
                    return decode(syncObjectValue: value, type: type)
                } else {
                    return nil
                }
            } else if let type = type {
                return decode(dataObjectValue: value, type: type)
            } else {
                return decode(objectValue: value, className: prop.objectClassName!)
            }
        case .any, .linkingObjects:
            fatalError("Not supported property type. Create an issue on github if you get this error.")
        }
    }
}
