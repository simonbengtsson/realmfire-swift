import Foundation
import RealmSwift
@testable import RealmFireDemo

import Foundation
import RealmSwift

class TestPerson: SyncObject {
    dynamic var registrationId = ""
    dynamic var name = ""
    dynamic var age = 0
    dynamic var secretMessage = ""
    let dogs = LinkingObjects(fromType: TestDog.self, property: "trainers")
    
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



class TestActivity: Object {
    dynamic var name = "Walking"
    dynamic var rating = 5
}

class TestDog: SyncObject {
    dynamic var uid = ""
    dynamic var name = ""
    dynamic var awardCount = 0
    dynamic var isHappy = false
    dynamic var height: Float = 0
    dynamic var speed: Double = 0
    
    dynamic var birthDate: Date? = nil
    dynamic var data: Data? = nil
    
    let rating = RealmOptional<Int>()
    let weight = RealmOptional<Double>()
    
    dynamic var owner: TestPerson? = nil
    let trainers = List<TestPerson>()
    
    dynamic var mainActivity: TestActivity? = nil
    let activities = List<TestActivity>()
    
    convenience init(debug: Bool) {
        self.init()
        name = "Fido"
        awardCount = 1
        isHappy = true
        height = 0.82
        speed = 12.2282
        
        birthDate = Date(timeIntervalSince1970: 1111)
        data = Data(base64Encoded: "BBBB")
        
        rating.value = 5
        weight.value = 15.14
        
        owner = TestPerson(debug: true)
        trainers.append(owner!)
        
        mainActivity = TestActivity()
        activities.append(mainActivity!)
    }
    
    override open class func primaryKey() -> String? {
        return #keyPath(uid)
    }
}
