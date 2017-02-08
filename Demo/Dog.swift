import Foundation
import RealmSwift

class Activity: Object {
    dynamic var name = "Walking"
    dynamic var date = Date()
}

class Dog: SyncObject {
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
    
    dynamic var owner: Person? = nil
    let trainers = List<Person>()
    
    dynamic var mainActivity: Activity? = nil
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
