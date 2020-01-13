import Foundation
import RealmSwift

class Activity: Object {
    @objc dynamic var name = "Walking"
    @objc dynamic var date = Date()
}

class Dog: SyncObject {
    @objc dynamic var uid = ""
    @objc dynamic var name = ""
    @objc dynamic var awardCount = 0
    @objc dynamic var isHappy = false
    @objc dynamic var height: Float = 0
    @objc dynamic var speed: Double = 0
    
    @objc dynamic var birthDate: Date? = nil
    @objc dynamic var data: Data? = nil
    
    let rating = RealmOptional<Int>()
    let weight = RealmOptional<Double>()
    
    @objc dynamic var owner: Person? = nil
    let trainers = List<Person>()
    
    @objc dynamic var mainActivity: Activity? = nil
    let activities = List<Activity>()
    
    convenience init(debug: Bool) {
        self.init()
        uid = RealmFire.uid()
        name = "Fido"
        awardCount = 1
        isHappy = true
        height = 0.82
        speed = 12.2282
        
        birthDate = Date(timeIntervalSince1970: 1111)
        data = Data(base64Encoded: "BBBB")
        
        rating.value = 5
        weight.value = 15.14
        
        owner = Person(debug: true)
        trainers.append(owner!)
        
        mainActivity = Activity()
        activities.append(mainActivity!)
    }
    
    override open class func primaryKey() -> String? {
        return #keyPath(uid)
    }
}
