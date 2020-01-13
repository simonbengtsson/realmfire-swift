import UIKit
import Firebase
import RealmSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var objectTypeSwitch: UISegmentedControl!
    
    enum ObjectType: Int {
        case dog, person
    }
    
    var objectType: ObjectType {
        return ObjectType(rawValue: objectTypeSwitch.selectedSegmentIndex)!
    }
    
    var type: SyncObject.Type {
        return objectType == .dog ? Dog.self : Person.self
    }

    @IBAction func create(_ sender: UIButton) {
        let realm = try! Realm()
        let obj = objectType == .dog ? Dog(debug: true) : Person(debug: true)
        try! realm.write {
            realm.add(obj)
            RealmFire.markForSync(obj)
            if let dog = obj as? Dog {
                RealmFire.markForSync(dog.trainers)
                RealmFire.markForSync(dog.owner!)
            } else {
                let person = obj as! Person
                RealmFire.markForSync(person.dogs)
            }
            
        }
        RealmFire.sync(realm: realm)
    }
    
    @IBAction func editClicked(_ sender: UIButton) {
        let realm = try! Realm()
        let obj = realm.objects(type).first!
        try! realm.write {
            if let dog = obj as? Dog {
                dog.awardCount += 1
            } else if let person = obj as? Person {
                person.age += 1
            }
            realm.add(obj)
            RealmFire.markForSync(obj)
        }
        RealmFire.sync()
    }
    
    @IBAction func deleteClicked(_ sender: UIButton) {
        let realm = try! Realm()
        let obj = realm.objects(type).first!
        try! realm.write {
            realm.delete(obj)
            RealmFire.markForDeletion(obj)
        }
    }
    
    @IBAction func clearAll(_ sender: UIButton) {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    @IBAction func fetchCliced(_ sender: UIButton) {
        RealmFire.sync()
    }

    @IBAction func uploadClicked(_ sender: UIButton) {
        let realm = try! Realm()
        try! realm.write {
            for obj in realm.objects(Dog.self) {
                obj.awardCount += 1
                RealmFire.markForSync(obj)
                
            }
            for obj in realm.objects(Person.self) {
                obj.age += 1
                RealmFire.markForSync(obj)
            }
        }
    }
}
