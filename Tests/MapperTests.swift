import XCTest
import RealmSwift
@testable import RealmFireDemo

class MapperTests: XCTestCase {
    var testRealm: Realm!
    var mapper: Mapper!
    
    override func tearDown() {
        super.tearDown()
        try! testRealm.write {
            testRealm.deleteAll()
        }
    }
    
    override func setUp() {
        super.setUp()
        var conf = Realm.Configuration()
        conf.inMemoryIdentifier = self.name
        let realm = try! Realm(configuration: conf)
        testRealm = realm
        mapper = Mapper(realm: testRealm)
    }
    
    
    func testDate() {
        let original = Date()
        let encoded = mapper.encode(date: original)
        let decoded = mapper.decode(dateValue: encoded)
        assert(original.timeIntervalSince1970 == decoded?.timeIntervalSince1970)
        
        let res = mapper.encode(date: nil)
        assert(res == nil)
    }
    
    func testData() {
        let original = "a test string"
        let decoded = mapper.decode(dataValue: original)
        let encoded = mapper.encode(data: decoded)
        assert(encoded as! String == original)
    }
    
    func testSyncObject() {
        let person = TestPerson(debug: true)
        try! testRealm.write {
            testRealm.add(person)
        }
        let encoded = mapper.encode(syncObject: person) as! String
        let decoded = mapper.decode(syncObjectValue: encoded, type: TestPerson.self)
        let obj = unsafeBitCast(decoded, to: TestPerson.self)
        assert(person.age == obj.age)
        
        let res = mapper.decode(syncObjectValue: "none-existing", type: TestPerson.self)
        assert(res.realm == nil)
    }
    
    func testSyncList() {
        let dog = TestDog(debug: true)
        try! testRealm.write {
            testRealm.add(dog)
        }
        let encoded = mapper.encode(syncList: dog.dynamicList("trainers"))
        let decoded = mapper.decode(syncListValue: encoded, type: TestPerson.self)
        let obj = unsafeBitCast(decoded.first!, to: TestPerson.self)
        assert(dog.trainers.first!.name == obj.name)
    }
    
    func testObjectList() {
        let dog = TestDog(debug: true)
        try! testRealm.write {
            testRealm.add(dog)
        }
        let encoded = mapper.encode(list: dog.dynamicList("activities"))
        try! testRealm.write {
            let decoded = mapper.decode(listValue: encoded, className: TestActivity.className())
            let obj = unsafeBitCast(decoded.first!, to: TestActivity.self)
            assert(dog.activities.first!.name == obj.name)
        }
    }
    
    func testObject() {
        let act = TestActivity()
        try! testRealm.write {
            testRealm.add(act)
        }
        let encoded = mapper.encode(object: act)
        try! testRealm.write {
            let decoded = mapper.decode(objectValue: encoded, className: TestActivity.className())
            let obj = unsafeBitCast(decoded, to: TestActivity.self)
            assert(obj.name == act.name)
        }
    }
    
    func testPerformanceExample() {
        self.measure {
            print("#perfmatters")
        }
    }
}

