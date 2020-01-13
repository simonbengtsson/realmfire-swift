import Foundation
import RealmSwift

class Person: SyncObject {
    @objc dynamic var registrationId = ""
    @objc dynamic var name = ""
    @objc dynamic var age = 0
    @objc dynamic var secretMessage = ""
    let dogs = LinkingObjects(fromType: Dog.self, property: "trainers")
    
    convenience init(debug: Bool) {
        self.init()
        registrationId = String(Int(Date().timeIntervalSince1970))
        name = "John"
        age = 20
        secretMessage = "I like ice cream"
    }
    
    override class func customAttributes() -> [String: String] {
        return [
            #keyPath(name): "full_name"
        ]
    }
    
    override class func uploadedAtAttribute() -> String {
        return "realmFireUploadedAt"
    }
    
    override open class func primaryKey() -> String? {
        return #keyPath(registrationId)
    }
    
    override open class func collectionName() -> String {
        return "persons"
    }
    
    override func encode(prop: Property, result: inout [String: Any]) -> Bool {
        if prop.name == #keyPath(secretMessage) {
            return true
        }
        return false
    }
    
    override func decode(prop: Property, data: [String: Any]) -> Bool {
        if prop.name == #keyPath(secretMessage) {
            secretMessage = "New secret message!"
            return true
        }
        return false
    }
}
